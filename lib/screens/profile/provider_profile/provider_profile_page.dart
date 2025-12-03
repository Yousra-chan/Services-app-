import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myapp/models/ProviderModel.dart';
import 'package:myapp/services/provider_service.dart';

// Assuming these models/services exist as per the original code

class ProviderProfilePage extends StatefulWidget {
  final String providerId;
  final String? imageUrl;

  const ProviderProfilePage(
      {super.key, required this.providerId, this.imageUrl});

  @override
  State<ProviderProfilePage> createState() => _ProviderProfilePageState();
}

class _ProviderProfilePageState extends State<ProviderProfilePage> {
  // Define a primary color for the overall theme
  final Color primaryColor = const Color(0xFF007BFF); // A nice, modern blue

  final ProviderService _providerService = ProviderService();
  late Future<ProviderModel?> _providerFuture;

  @override
  void initState() {
    super.initState();
    _providerFuture = _providerService.getProviderById(widget.providerId);
  }

  void _refreshProvider() {
    setState(() {
      _providerFuture = _providerService.getProviderById(widget.providerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Keep a light, clean background
      backgroundColor: Colors.white,
      body: FutureBuilder<ProviderModel?>(
        future: _providerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }

          if (snapshot.hasError) {
            return _buildError();
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return _buildNotFound();
          }

          final provider = snapshot.data!;
          return _buildProfile(provider, context);
        },
      ),
    );
  }

  Widget _buildProfile(ProviderModel provider, BuildContext context) {
    final String profileImageUrl = widget.imageUrl ?? provider.photoUrl;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // 1. App Bar with Dynamic Header and Always-Visible Profile Picture
            SliverAppBar(
              backgroundColor: Colors.white,
              expandedHeight: 250, // Slightly taller header
              pinned: true,
              floating: false,
              elevation: 0,
              leading: Container(
                margin: const EdgeInsets.only(left: 8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: const Icon(Icons.share, color: Colors.black87),
                    onPressed: () => _shareProfile(provider),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  color: Colors.grey[50],
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Image - Larger and more prominent
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _buildProfileImage(profileImageUrl),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Name and Profession
                      Text(
                        provider.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.profession.isNotEmpty
                            ? provider.profession
                            : 'Service Provider',
                        style: TextStyle(
                          fontSize: 16,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Main Content
            SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),

                // Stats Section (Rating, Location, Status)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        Icons.star,
                        'Rating',
                        provider.rating.toStringAsFixed(1),
                        Colors.amber,
                      ),
                      _buildStatItem(
                        Icons.location_on,
                        'Location',
                        _extractLocation(provider.address),
                        Colors.blue,
                      ),
                      _buildStatItem(
                        Icons.verified_user,
                        'Status',
                        provider.subscriptionActive ? 'Verified' : 'Unverified',
                        provider.subscriptionActive
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ],
                  ),
                ),

                // Description (About)
                if (provider.description.isNotEmpty)
                  _buildSectionCard(
                    title: 'About ${provider.name}',
                    child: Text(
                      provider.description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ),

                // Services
                _buildServicesSection(provider),

                // Contact Information
                _buildSectionCard(
                  title: 'Contact Information',
                  child: Column(
                    children: [
                      _buildContactCard(
                        Icons.phone,
                        'Phone',
                        provider.phone,
                        primaryColor,
                        () => _makeCall(provider.phone),
                      ),
                      if (provider.whatsapp.isNotEmpty)
                        const SizedBox(height: 12),
                    ],
                  ),
                ),

                // Bottom spacing for the floating CTA button
                const SizedBox(height: 100),
              ]),
            ),
          ],
        ),

        // 3. Floating CTA Button
        _buildCtaButton(provider, context),
      ],
    );
  }

  // Helper widget to wrap sections in a card-like style
  Widget _buildSectionCard({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  // --- Utility Widgets ---

  Widget _buildServicesSection(ProviderModel provider) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getProviderServices(provider.uid ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final services = snapshot.data ?? [];

        if (services.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildSectionCard(
          title: 'Offered Services',
          child: Column(
            children:
                services.map((service) => _buildServiceItem(service)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> service) {
    final String price = '${service['price'] ?? '0'} DZD';
    final String title = service['title'] ?? 'Service';
    final String description = service['description'] ?? '';
    final String category = service['category'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon/Indicator
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.build_circle_outlined,
                color: primaryColor, size: 24),
          ),
          const SizedBox(width: 15),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      label: Text(category),
                      backgroundColor: Colors.transparent,
                      shape: StadiumBorder(
                          side: BorderSide(color: Colors.grey[300]!)),
                      labelStyle:
                          TextStyle(color: Colors.grey[600], fontSize: 12),
                      padding: EdgeInsets.zero,
                    ),
                    const Spacer(),
                    Text(
                      price,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(IconData icon, String title, String subtitle,
      Color color, VoidCallback onTap) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildCtaButton(ProviderModel provider, BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _startChat(context, provider),
                icon: const Icon(Icons.message),
                label: const Text('Send Message'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 60,
              child: ElevatedButton(
                onPressed: () => _makeCall(provider.phone),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Icon(Icons.call, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- The rest of the original helper methods and states ---

  Widget _buildProfileImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(child: CircularProgressIndicator(color: primaryColor));
        },
      );
    }
    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.person, color: Colors.grey, size: 40),
    );
  }

  String _extractLocation(String address) {
    if (address.isEmpty) return 'Unknown';
    final parts = address.split(',').map((e) => e.trim()).toList();
    if (parts.length > 1) return parts[0]; // Just take the first part
    if (address.length > 15) return '${address.substring(0, 15)}...';
    return address;
  }

  Future<List<Map<String, dynamic>>> _getProviderServices(
      String providerId) async {
    // NOTE: Using a mock implementation for demonstration since Firestore is not available here.
    // Replace this with your actual FirebaseFirestore logic.
    await Future.delayed(const Duration(milliseconds: 500));
    if (providerId.isEmpty) return [];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('services')
          .where('providerId', isEqualTo: providerId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      // print('Error getting services: $e');
      // Mock data for display purposes if Firestore fails or is commented out
      return [
        {
          'title': 'Plumbing Repair',
          'description': 'Emergency and general plumbing services for homes.',
          'category': 'Home Maintenance',
          'price': 5000,
        },
        {
          'title': 'Electrical Wiring',
          'description': 'Full house wiring and circuit breaker installation.',
          'category': 'Construction',
          'price': 12000,
        },
      ];
    }
  }

  // Contact Methods (using placeholders for external calls)
  void _startChat(BuildContext context, ProviderModel provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting chat with ${provider.name}')),
    );
  }

  void _makeCall(String phoneNumber) async {
    final url = 'tel:${_cleanPhoneNumber(phoneNumber)}';
    // Use an actual launcher here (e.g., url_launcher package)
    // if (await canLaunch(url)) { await launch(url); }
    // else { print('Could not launch $url'); }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Simulated Call to ${_cleanPhoneNumber(phoneNumber)}')),
    );
  }

  void _openWhatsApp(String whatsappNumber) async {
    final cleanNumber = _cleanPhoneNumber(whatsappNumber);
    final url = 'https://wa.me/$cleanNumber';
    // Use an actual launcher here (e.g., url_launcher package)
    // if (await canLaunch(url)) { await launch(url); }
    // else { print('Could not launch $url'); }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Simulated WhatsApp to $cleanNumber')),
    );
  }

  void _shareProfile(ProviderModel provider) {
    final text = 'Check out ${provider.name}\'s profile!';
    // Use a share package (e.g., share_plus) here
    // Share.share(text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Simulated Share: $text')),
    );
  }

  String _cleanPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
  }

  // Loading State
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor),
          const SizedBox(height: 16),
          const Text(
            'Loading Profile...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // Error State
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
            const SizedBox(height: 16),
            const Text(
              'Unable to Load Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _refreshProvider,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // Not Found State
  Widget _buildNotFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Profile Not Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "This profile doesn't exist or may have been removed.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myapp/models/ProviderModel.dart';
import 'package:myapp/screens/profile/provider_profile/provider_profile_widget.dart';
import 'package:myapp/services/provider_service.dart';
import 'package:myapp/utils/image_utils.dart';

// Add these constants since profile_constants.dart might not exist
const Color kLightBackgroundColor = Color(0xFFF8F9FF);
const Color kPrimaryBlue = Color.fromARGB(255, 87, 101, 240);
const Color kDarkTextColor = Color(0xFF323232);
const Color kMutedTextColor = Color(0xFF969696);

class ProviderProfilePage extends StatefulWidget {
  final String providerId;
  final String? imageUrl;

  const ProviderProfilePage(
      {super.key, required this.providerId, this.imageUrl});

  @override
  State<ProviderProfilePage> createState() => _ProviderProfilePageState();
}

class _ProviderProfilePageState extends State<ProviderProfilePage> {
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
      backgroundColor: kLightBackgroundColor,
      body: FutureBuilder<ProviderModel?>(
        future: _providerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return _buildNotFoundState();
          }

          final provider = snapshot.data!;
          return _buildIntuitiveProfile(provider, context);
        },
      ),
    );
  }

  Widget _buildIntuitiveProfile(ProviderModel provider, BuildContext context) {
    final String? profileImageUrl = widget.imageUrl ?? provider.photoUrl;

    return Column(
      children: [
        // Clean Header with Essential Info
        _buildCleanHeader(provider, profileImageUrl),

        // Main Content - Tab-like Sections
        Expanded(
          child: DefaultTabController(
            length:
                3, // Changed from 4 to 3 since we don't have Gallery tab anymore
            child: Column(
              children: [
                // Tab Bar
                Container(
                  color: Colors.white,
                  child: TabBar(
                    labelColor: kPrimaryBlue,
                    unselectedLabelColor: kMutedTextColor,
                    indicatorColor: kPrimaryBlue,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(text: 'About'),
                      Tab(text: 'Services'),
                      Tab(text: 'Contact'),
                    ],
                  ),
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    children: [
                      // About Tab
                      _buildAboutTab(provider),

                      // Services Tab
                      _buildServicesTab(provider),

                      // Contact Tab
                      _buildContactTab(provider),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Fixed Action Buttons
        _buildActionButtons(provider),
      ],
    );
  }

  Widget _buildCleanHeader(ProviderModel provider, String? imageUrl) {
    // Extract wilaya and commune from address
    final wilaya = _extractWilayaFromAddress(provider.address) ?? 'Unknown';
    final commune = _extractCommuneFromAddress(provider.address) ?? 'Unknown';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Navigation Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kLightBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: kDarkTextColor, size: 20),
                ),
              ),
              IconButton(
                onPressed: () => _shareProfile(provider),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kLightBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.share, color: kDarkTextColor, size: 20),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Profile Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: kPrimaryBlue.withOpacity(0.3), width: 2),
                ),
                child: ClipOval(
                  child: _buildProfileImage(imageUrl),
                ),
              ),

              const SizedBox(width: 16),

              // Profile Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kDarkTextColor,
                        fontFamily: 'Exo2',
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      provider.profession.isNotEmpty
                          ? provider.profession
                          : 'Service Provider',
                      style: TextStyle(
                        color: kPrimaryBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '$commune, $wilaya',
                      style: TextStyle(
                        color: kMutedTextColor,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Rating and Status
                    Row(
                      children: [
                        // Rating
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.amber.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                provider.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Verified Badge
                        if (provider.subscriptionActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.green.withOpacity(0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.verified,
                                    color: Colors.green, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab(ProviderModel provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Me',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kDarkTextColor,
            ),
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              provider.description.isNotEmpty
                  ? provider.description
                  : 'No description provided yet.',
              style: TextStyle(
                color: kDarkTextColor,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Additional Info Section
          const Text(
            'Quick Info',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kDarkTextColor,
            ),
          ),

          const SizedBox(height: 16),

          _buildInfoItem('Profession', provider.profession),
          _buildInfoItem('Location', provider.address),
          _buildInfoItem('Phone', provider.phone),
          if (provider.whatsapp.isNotEmpty)
            _buildInfoItem('WhatsApp', provider.whatsapp),
        ],
      ),
    );
  }

  Widget _buildServicesTab(ProviderModel provider) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getProviderServices(provider.uid ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
              child: Text('Error loading services: ${snapshot.error}'));
        }

        final services = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Services I Offer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kDarkTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Here are the services I specialize in:',
                style: TextStyle(
                  color: kMutedTextColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              if (services.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.work_outline,
                          size: 48, color: kMutedTextColor.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'No services listed yet',
                        style: TextStyle(
                          color: kMutedTextColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: services.map((service) {
                    return _buildServiceCard(service);
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            service['title'] ?? 'Service',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kDarkTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            service['description'] ?? '',
            style: TextStyle(
              color: kMutedTextColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(
                label: Text(service['category'] ?? ''),
                backgroundColor: kPrimaryBlue.withOpacity(0.1),
                labelStyle: TextStyle(color: kPrimaryBlue),
              ),
              Text(
                '${service['price'] ?? '0'} DZD ${service['priceUnit'] ?? ''}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getProviderServices(
      String providerId) async {
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
      print('Error getting services: $e');
      return [];
    }
  }

  Widget _buildContactTab(ProviderModel provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Get In Touch',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kDarkTextColor,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Choose your preferred way to contact me:',
            style: TextStyle(
              color: kMutedTextColor,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 24),

          // Contact Methods
          _buildContactMethod(
            icon: Icons.message,
            title: 'Send Message',
            subtitle: 'Chat directly with me',
            color: kPrimaryBlue,
            onTap: () => _startChat(context, provider),
          ),

          const SizedBox(height: 12),

          _buildContactMethod(
            icon: Icons.phone,
            title: 'Call Now',
            subtitle: provider.phone,
            color: Colors.green,
            onTap: () => _makeCall(provider.phone),
          ),

          const SizedBox(height: 12),

          if (provider.whatsapp.isNotEmpty)
            _buildContactMethod(
              icon: Icons.chat,
              title: 'WhatsApp',
              subtitle: provider.whatsapp,
              color: const Color(0xFF25D366),
              onTap: () => _openWhatsApp(provider.whatsapp),
            ),

          const SizedBox(height: 12),

          _buildContactMethod(
            icon: Icons.location_on,
            title: 'Location',
            subtitle: provider.address,
            color: Colors.orange,
            onTap: () => _openMaps(provider.address),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: kMutedTextColor,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: kDarkTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactMethod({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kDarkTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: kMutedTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: kMutedTextColor.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ProviderModel provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _startChat(context, provider),
                icon: const Icon(Icons.message, size: 20),
                label: const Text(
                  'Message',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                ),
                child: const Icon(Icons.phone, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          return _buildFallbackImage();
        },
      );
    }
    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Container(
      color: kLightBackgroundColor,
      child: Icon(Icons.person, color: kMutedTextColor, size: 40),
    );
  }

  // Helper methods to extract location from address
  String? _extractWilayaFromAddress(String address) {
    if (address.isEmpty) return null;

    final wilayas = [
      'Alger',
      'Boumerdès',
      'Blida',
      'Oran',
      'Tizi Ouzou',
      'Constantine'
    ];

    for (var wilaya in wilayas) {
      if (address.toLowerCase().contains(wilaya.toLowerCase())) {
        return wilaya;
      }
    }

    return null;
  }

  String? _extractCommuneFromAddress(String address) {
    if (address.isEmpty) return null;

    final parts = address.split(',');
    if (parts.isNotEmpty) {
      return parts.first.trim();
    }

    return null;
  }

  // Contact Methods (implement these with your logic)
  void _startChat(BuildContext context, ProviderModel provider) {
    // TODO: Implement chat functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting chat with ${provider.name}')),
    );
  }

  void _makeCall(String phoneNumber) async {
    // TODO: Implement phone call functionality
    final url = 'tel:${_cleanPhoneNumber(phoneNumber)}';
    print('Calling: $url');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling ${_cleanPhoneNumber(phoneNumber)}')),
    );
  }

  void _openWhatsApp(String whatsappNumber) async {
    // TODO: Implement WhatsApp functionality
    final cleanNumber = _cleanPhoneNumber(whatsappNumber);
    final url = 'https://wa.me/$cleanNumber';
    print('Opening WhatsApp: $url');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening WhatsApp')),
    );
  }

  void _openMaps(String address) async {
    // TODO: Implement maps functionality
    final encodedAddress = Uri.encodeComponent(address);
    final url =
        'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
    print('Opening maps: $url');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening location')),
    );
  }

  void _shareProfile(ProviderModel provider) {
    // TODO: Implement share functionality
    final text = 'Check out ${provider.name}\'s profile!';
    print('Sharing: $text');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing profile')),
    );
  }

  String _cleanPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
  }

  // Loading State
  Widget _buildLoadingState() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: kPrimaryBlue),
            const SizedBox(height: 16),
            const Text(
              'Loading Profile...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kDarkTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Error State
  Widget _buildErrorState(String error) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryBlue),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Unable to Load Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kDarkTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kMutedTextColor),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _refreshProvider,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Not Found State
  Widget _buildNotFoundState() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryBlue),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 60, color: kMutedTextColor),
              const SizedBox(height: 16),
              const Text(
                'Profile Not Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kDarkTextColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "The provider profile you're looking for doesn't exist or may have been removed.",
                textAlign: TextAlign.center,
                style: TextStyle(color: kMutedTextColor),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:myapp/models/ProviderModel.dart';
import 'package:myapp/ViewModel/auth_view_model.dart';
import 'package:myapp/services/provider_service.dart';
import 'package:myapp/services/chat_service.dart';
import 'package:myapp/utils/image_utils.dart';
import 'package:myapp/screens/posts/posts_constants.dart' show kOfferingColor;

const kPrimaryBlue = Color(0xFF4A6FDC);
const kDarkTextColor = Color(0xFF333333);
const kMutedTextColor = Color(0xFF666666);
const kLightBackgroundColor = Color(0xFFF5F5F5);

class ProviderProfileScreen extends StatelessWidget {
  final ProviderModel provider;
  final String serviceCategory;

  const ProviderProfileScreen({
    required this.provider,
    required this.serviceCategory,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. Collapsing Header (SliverAppBar)
              ProviderHeaderSliver(
                provider: provider,
                serviceCategory: serviceCategory ?? 'General Services',
              ),

              // 2. Main Content Body (SliverList holds the rest of your cards)
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Description Section
                          _buildSectionTitle('👋 About ${provider.name}'),
                          const SizedBox(height: 10),
                          DescriptionCard(description: provider.description),
                          const SizedBox(height: 30),

                          // Services Section - FIXED: Use serviceIds instead of services
                          _buildSectionTitle('🔧 Services Offered'),
                          const SizedBox(height: 10),
                          // Option 1: If ServicesChips expects List<String> for service names
                          ServicesChips(
                            services: provider.serviceIds, // Use serviceIds
                          ),

                          const SizedBox(height: 30),

                          // Gallery Section
                          _buildSectionTitle('📸 Work Gallery'),
                          const SizedBox(height: 10),
                          WorkGallery(providerId: provider.uid ?? ''),
                          const SizedBox(height: 30),

                          // Contact Details Section
                          _buildSectionTitle('📞 Contact Information'),
                          const SizedBox(height: 10),
                          ContactDetails(provider: provider),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 3. Floating Contact Button (Fixed Bottom Bar)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ContactButton(provider: provider),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: kDarkTextColor,
        fontFamily: 'Exo2',
      ),
    );
  }
}

// --- WIDGETS (The remaining code you provided, ensuring it's in the same file or imported) ---

// NOTE: You must ensure all these classes (ProviderHeaderSliver, RatingBadge, etc.)
// are available either in this file or imported from their respective files.

/// Enhanced Collapsing Header
class ProviderHeaderSliver extends StatelessWidget {
  final ProviderModel provider;
  final String? imageUrl;
  final String serviceCategory;

  const ProviderHeaderSliver({
    required this.provider,
    this.imageUrl,
    this.serviceCategory = 'General Services',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final String profileImageUrl = ImageUtils.getImageUrl(
      imageUrl ?? provider.photoUrl ?? '',
      fallbackUrl:
          'https://media.sproutsocial.com/uploads/2022/06/profile-picture.jpeg',
    );

    return SliverAppBar(
      backgroundColor: kPrimaryBlue,
      expandedHeight: 380.0,
      pinned: true,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.share, size: 22),
            onPressed: () => _shareProviderProfile(context, provider),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 300),
          child: Text(
            provider.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Exo2',
            ),
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image with Gradient Overlay - using enhanced image loading
            _buildProfileImage(profileImageUrl),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),

            // Profile Info Overlay
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.profession.isNotEmpty
                        ? provider.profession
                        : 'Service Provider',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Exo2',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    serviceCategory, // Use the passed parameter
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontFamily: 'Exo2',
                    ),
                  ),
                ],
              ),
            ),

            // Rating and Verification Badges
            Positioned(
              bottom: 20,
              right: 20,
              child: Row(
                children: [
                  if (provider.subscriptionActive)
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  RatingBadge(rating: provider.rating),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final imageProvider = ImageUtils.getImageProvider(imageUrl);

      if (imageProvider != null) {
        return Image(
          image: imageProvider,
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
    }

    // If no image URL or invalid, show fallback
    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kPrimaryBlue,
            kPrimaryBlue,
            const Color(0xFF667EEA),
          ],
        ),
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 80,
      ),
    );
  }

  void _shareProviderProfile(
      BuildContext context, ProviderModel provider) async {
    final shareText =
        'Check out ${provider.name} - ${provider.profession} on Akhdem Li!';
    final url = 'https://yourapp.com/providers/${provider.uid}';

    final shareContent = '$shareText $url';

    if (await launchUrl(
        Uri.parse('sms:?body=${Uri.encodeComponent(shareContent)}'))) {
      await launchUrl(
          Uri.parse('sms:?body=${Uri.encodeComponent(shareContent)}'));
    } else {
      // Use standard sharing method if SMS fails or is not preferred
      // You might use the 'share_plus' package here instead of just SMS.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sharing ${provider.name}\'s profile'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}

/// Enhanced Rating Badge
class RatingBadge extends StatelessWidget {
  final double rating;

  const RatingBadge({required this.rating, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFEC8B)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.black87, size: 16),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Enhanced Description Card
class DescriptionCard extends StatelessWidget {
  final String description;

  const DescriptionCard({required this.description, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        description.isNotEmpty ? description : 'No description available.',
        style: const TextStyle(
          color: kDarkTextColor,
          height: 1.6,
          fontSize: 15,
        ),
      ),
    );
  }
}

/// Enhanced Services Chips
class ServicesChips extends StatelessWidget {
  final List<String> services;

  const ServicesChips({required this.services, super.key});

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          'No services listed yet.',
          style: const TextStyle(
            color: kMutedTextColor,
            fontSize: 16,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12.0,
        runSpacing: 12.0,
        children: services.map((service) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kPrimaryBlue.withOpacity(0.8),
                  const Color(0xFF667EEA)
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    service,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Enhanced Work Gallery
class WorkGallery extends StatelessWidget {
  final String providerId;

  const WorkGallery({required this.providerId, super.key});

  @override
  Widget build(BuildContext context) {
    // NOTE: Ensure ProviderService().getProviderGallery is properly implemented
    return FutureBuilder<List<String>>(
      future: ProviderService().getProviderGallery(providerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final images = snapshot.data ?? [];

        if (images.isEmpty) {
          return Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'No work photos available yet.',
                style: const TextStyle(
                  color: kMutedTextColor,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }

        return SizedBox(
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) {
              final imageUrl = ImageUtils.getImageUrl(images[index]);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Image(
                        image: ImageUtils.getImageProvider(imageUrl) ??
                            const NetworkImage(
                                    'https://via.placeholder.com/160x200/CCCCCC/969696?text=No+Image')
                                as ImageProvider,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: kLightBackgroundColor,
                          child: const Center(
                            child: Icon(Icons.broken_image,
                                color: Colors.grey, size: 40),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Enhanced Contact Details
class ContactDetails extends StatelessWidget {
  final ProviderModel provider;

  const ContactDetails({required this.provider, super.key});

  Widget _buildContactItem(IconData icon, String title, String subtitle,
      Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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
                          color: kDarkTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
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
      ),
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final url = Uri.parse('tel:${_cleanPhoneNumber(phoneNumber)}');
    if (await launchUrl(url)) {
      await launchUrl(url);
    } else {
      // Handle error
    }
  }

  void _openWhatsApp(String whatsappNumber) async {
    final cleanNumber = _cleanPhoneNumber(whatsappNumber);
    final url = Uri.parse('https://wa.me/$cleanNumber');

    if (await launchUrl(url)) {
      await launchUrl(url);
    } else {
      // Handle error
    }
  }

  void _openLocationInMaps(String address) async {
    // Use the provider's address string for a simple map search
    final encodedAddress = Uri.encodeComponent(address);
    // Universal maps URL for better compatibility
    final url = Uri.parse('https://maps.apple.com/?q=$encodedAddress');

    if (await launchUrl(url)) {
      await launchUrl(url);
    } else {
      final fallbackUrl = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$encodedAddress');
      if (await launchUrl(fallbackUrl)) {
        await launchUrl(fallbackUrl);
      } else {
        // Handle error: Could not launch maps
      }
    }
  }

  String _cleanPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except +
    return phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildContactItem(
          Icons.location_on_outlined,
          'Location',
          provider.address,
          kPrimaryBlue,
          () => _openLocationInMaps(provider.address),
        ),
        _buildContactItem(
          Icons.phone,
          'Phone',
          provider.phone,
          Colors.green,
          () => _makePhoneCall(provider.phone),
        ),
        _buildContactItem(
          Icons.chat_bubble_rounded,
          'WhatsApp',
          provider.whatsapp,
          kOfferingColor, // Ensure kOfferingColor is accessible
          () => _openWhatsApp(provider.whatsapp),
        ),
      ],
    );
  }
}

/// Enhanced Contact Button (Fixed at the bottom)
class ContactButton extends StatelessWidget {
  final ProviderModel provider;

  const ContactButton({required this.provider, super.key});

  void _startChat(BuildContext context) async {
    // NOTE: This assumes AuthViewModel is available via a Provider at the root of your app
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final chatService = ChatService();

    if (authViewModel.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in to start a chat'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'Sign In',
            onPressed: () {
              // Add navigation to your sign in page here
            },
          ),
        ),
      );
      return;
    }

    try {
      // You need to ensure ProviderModel has a non-null uid
      if (provider.uid == null) {
        throw Exception("Provider UID is null.");
      }

      final chatId = await chatService.createChat(
        clientId: authViewModel.currentUser!.uid,
        providerId: provider.uid!, // Add ! to assert non-null
      );

      // --- REPLACE WITH YOUR CHAT NAVIGATION ---
      // Navigator.push(context, MaterialPageRoute(builder: (_) => DiscussionPage(...)));
      // For now, show a confirmation snackbar:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Starting chat... Chat ID: $chatId'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start chat: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    final url = 'tel:${_cleanPhoneNumber(phoneNumber)}';
    if (await launchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      // Handle error
    }
  }

  String _cleanPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryBlue, const Color(0xFF667EEA)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryBlue.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _startChat(context),
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.message_rounded,
                              color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            "Message Me",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Exo2',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: kPrimaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: kPrimaryBlue.withOpacity(0.3)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _makePhoneCall(provider.phone),
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    child: Icon(Icons.phone, color: kPrimaryBlue, size: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

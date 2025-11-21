import 'package:flutter/material.dart';
import 'package:myapp/screens/posts/posts_constants.dart' show kOfferingColor;
import 'package:provider/provider.dart';
import 'package:myapp/models/ProviderModel.dart';
import 'package:myapp/ViewModel/auth_view_model.dart';
import 'package:myapp/services/provider_service.dart';
import 'package:myapp/screens/profile/profile_constants.dart';

class ProviderProfilePage extends StatefulWidget {
  final String providerId;

  const ProviderProfilePage({super.key, required this.providerId});

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
          return _buildProviderProfile(provider, context);
        },
      ),
    );
  }

  Widget _buildProviderProfile(ProviderModel provider, BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // 1. Collapsing Header (SliverAppBar)
            _ProviderHeaderSliver(
              provider: provider,
              imageUrl: provider.photoUrl ??
                  'https://media.sproutsocial.com/uploads/2022/06/profile-picture.jpeg',
            ),

            // 2. Main Content
            SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionTitle("About ${provider.name}"),
                _DescriptionCard(description: provider.description),
                _buildSectionTitle("Services Offered"),
                _ServicesChips(services: provider.services),
                _buildSectionTitle("Work Gallery"),
                _WorkGallery(providerId: provider.uid ?? widget.providerId),
                _buildSectionTitle("Price & Estimate"),
                _PriceEstimate(provider: provider),
                _buildSectionTitle("Contact Details"),
                _ContactDetails(provider: provider),
                const SizedBox(height: 100), // Space for the bottom button
              ]),
            ),
          ],
        ),

        // Bottom Contact Button positioned absolutely
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _ContactButton(provider: provider),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading provider profile...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshProvider,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Not Found'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Provider Not Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'The provider profile you are looking for does not exist or has been removed.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  // --- Section Title ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 25, left: 20, right: 20, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: kDarkTextColor,
        ),
      ),
    );
  }
}

/// 1. Collapsing Header Widget
class _ProviderHeaderSliver extends StatelessWidget {
  final ProviderModel provider;
  final String imageUrl;

  const _ProviderHeaderSliver({required this.provider, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: kPrimaryBlue,
      expandedHeight: 300.0,
      pinned: true,
      elevation: 4.0,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            _shareProviderProfile(context, provider);
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          provider.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image with error handling
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              colorBlendMode: BlendMode.darken,
              color: Colors.black.withOpacity(0.3),
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: kPrimaryBlue,
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 80,
                  ),
                );
              },
            ),
            // Rating Badge
            Positioned(
              bottom: 25,
              right: 20,
              child: _RatingBadge(rating: provider.rating),
            ),
            // Subscription Status Badge
            if (provider.subscriptionActive)
              Positioned(
                top: 40,
                right: 20,
                child: _SubscriptionBadge(),
              ),
          ],
        ),
      ),
    );
  }

  void _shareProviderProfile(BuildContext context, ProviderModel provider) {
    final shareText =
        'Check out ${provider.name} - ${provider.profession} on Akhdem Li!';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing ${provider.name}\'s profile')),
    );
  }
}

/// Subscription Badge Widget
class _SubscriptionBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: Colors.white, size: 16),
          SizedBox(width: 5),
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
    );
  }
}

/// 2. Rating Badge Widget
class _RatingBadge extends StatelessWidget {
  final double rating;

  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kAccentColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 5),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// 3. Description Card
class _DescriptionCard extends StatelessWidget {
  final String description;

  const _DescriptionCard({required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Text(
            description.isNotEmpty ? description : 'No description available.',
            style: TextStyle(color: kDarkTextColor, height: 1.5, fontSize: 15),
          ),
        ),
      ),
    );
  }
}

/// 4. Services Chips
class _ServicesChips extends StatelessWidget {
  final List<String> services;

  const _ServicesChips({required this.services});

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'No services listed yet.',
          style: TextStyle(color: kMutedTextColor, fontSize: 16),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: services
            .map((service) => Chip(
                  backgroundColor: kPrimaryBlue.withOpacity(0.1),
                  side: BorderSide.none,
                  label: Text(
                    service,
                    style: TextStyle(
                      color: kPrimaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  avatar: Icon(Icons.bolt, color: kPrimaryBlue, size: 18),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                ))
            .toList(),
      ),
    );
  }
}

/// 5. Work Gallery with Backend
class _WorkGallery extends StatelessWidget {
  final String providerId;

  const _WorkGallery({required this.providerId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: ProviderService().getProviderGallery(providerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final images = snapshot.data ?? [];

        if (images.isEmpty) {
          return SizedBox(
            height: 120,
            child: Center(
              child: Text(
                'No work photos available yet.',
                style: TextStyle(color: kMutedTextColor),
              ),
            ),
          );
        }

        return SizedBox(
          height: 180,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 15),
                width: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: kSoftShadowColor,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: kLightBackgroundColor,
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
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

/// 6. Price Estimate with Dynamic Data
class _PriceEstimate extends StatelessWidget {
  final ProviderModel provider;

  const _PriceEstimate({required this.provider});

  @override
  Widget build(BuildContext context) {
    final priceText = "Contact for pricing";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kAccentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: kAccentColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.paid_outlined, color: kAccentColor, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              priceText,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kDarkTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 7. Contact Details
class _ContactDetails extends StatelessWidget {
  final ProviderModel provider;

  const _ContactDetails({required this.provider});

  Widget _buildInfoRow(IconData icon, String text,
      {bool isWhatsapp = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: isWhatsapp ? kOfferingColor : kPrimaryBlue,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: kDarkTextColor, fontSize: 16),
              ),
            ),
            if (!isWhatsapp)
              Icon(
                Icons.arrow_forward_ios,
                color: kMutedTextColor.withOpacity(0.5),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  // --- FIX 1: Add context as a parameter here ---
  void _makePhoneCall(BuildContext context, String phoneNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling $phoneNumber')),
    );
  }

  // --- FIX 2: Add context as a parameter here ---
  void _openWhatsApp(BuildContext context, String whatsappNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening WhatsApp: $whatsappNumber')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kCardBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: kSoftShadowColor,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.location_on_outlined, provider.address),
          const Divider(height: 20, thickness: 0.5),
          _buildInfoRow(
            Icons.phone,
            provider.phone,
            // --- FIX 3: Pass the context from build to the method ---
            onTap: () => _makePhoneCall(context, provider.phone),
          ),
          const Divider(height: 20, thickness: 0.5),
          _buildInfoRow(
            Icons.chat_bubble_rounded,
            provider.whatsapp,
            isWhatsapp: true,
            // --- FIX 4: Pass the context from build to the method ---
            onTap: () => _openWhatsApp(context, provider.whatsapp),
          ),
        ],
      ),
    );
  }
}

/// 8. Bottom Contact Button
class _ContactButton extends StatelessWidget {
  final ProviderModel provider;

  const _ContactButton({required this.provider});

  void _startChat(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    if (authViewModel.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to start a chat')),
      );
      return;
    }

    // Navigate to chat screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening chat with ${provider.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: kCardBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: kSoftShadowColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.message_rounded, size: 22),
          label: const Text("Message Me", style: TextStyle(fontSize: 18)),
          onPressed: () => _startChat(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 8,
          ),
        ),
      ),
    );
  }
}

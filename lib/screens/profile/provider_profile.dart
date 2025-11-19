import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Assuming the path is correct
import 'package:myapp/models/ProviderModel.dart';
// Assuming this file defines colors like kPrimaryBlue, kLightBackgroundColor, etc.
import 'package:myapp/screens/posts/posts_constants.dart';

// --- Dummy Data (Kept for demonstration) ---
final ProviderModel dummyProviderModel = ProviderModel(
  uid: "p123",
  name: "Khaled E.",
  profession: "Certified Electrician",
  description:
      "10 years experience. Available for wiring, fixture installation, and emergency troubleshooting. Contact me for a quote! Committed to safety and quality.",
  phone: "+213 555 123 456",
  whatsapp: "+213 555 123 456",
  photoUrl:
      'https://media.sproutsocial.com/uploads/2022/06/profile-picture.jpeg',
  location: const GeoPoint(36.75388, 3.05875),
  address: "City Center, North District",
  rating: 4.8,
  subscriptionActive: true,
  subscriptionExpires: Timestamp.fromDate(
    Timestamp.now().toDate().add(const Duration(days: 30)),
  ),
  userRef: FirebaseFirestore.instance.doc('users/user_khaled'),
  services: const [
    "Residential Wiring",
    "Fixture Installation",
    "Emergency Troubleshooting",
    "Panel Upgrades",
    "Smart Home Integration",
    "Commercial Maintenance",
    "Grounding Systems",
  ],
);

class ProviderProfilePage extends StatelessWidget {
  final ProviderModel provider;

  const ProviderProfilePage({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackgroundColor,
      // Use Stack to place the Floating Button (or use bottomNavigationBar/bottomSheet)
      // For simplicity, we keep the bottomSheet pattern, but clean it up.
      body: CustomScrollView(
        slivers: [
          // 1. Collapsing Header (SliverAppBar)
          _ProviderHeaderSliver(
            provider: provider,
            imageUrl:
                provider.photoUrl ??
                'https://media.sproutsocial.com/uploads/2022/06/profile-picture.jpeg',
          ),

          // 2. Main Content (SliverList is the simplest to use with a Column-like structure)
          SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionTitle("About ${provider.name}"),
              _DescriptionCard(description: provider.description),

              _buildSectionTitle("Services Offered"),
              _ServicesChips(services: provider.services),

              _buildSectionTitle("Work Gallery"),
              const _WorkGallery(),

              _buildSectionTitle("Price & Estimate"),
              const _PriceEstimate(),

              _buildSectionTitle("Contact Details"),
              _ContactDetails(provider: provider),

              // Padding at the bottom so the last content isn't covered by the bottomSheet
              const SizedBox(height: 100),
            ]),
          ),
        ],
      ),
      // --- Floating Contact Button ---
      bottomSheet: _ContactButton(provider: provider),
    );
  }

  // --- Section Title (Moved out of the main class for organization) ---
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
      // --- Simple AppBar Content ---
      backgroundColor: kPrimaryBlue,
      expandedHeight: 300.0, // Taller header height
      pinned: true, // AppBar sticks to the top
      elevation: 4.0,

      // --- Custom Action/Leading buttons (Always visible) ---
      iconTheme: const IconThemeData(
        color: Colors.white,
      ), // Ensures icons are white
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {}, // Share logic
        ),
      ],

      // --- Content when expanded ---
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
            // Background Image
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              colorBlendMode: BlendMode.darken,
              color: Colors.black.withOpacity(0.3), // Dark overlay
            ),

            // Rating Badge (Positioned at the bottom-right of the expanded area)
            Positioned(
              bottom: 25,
              right: 20,
              child: _RatingBadge(rating: provider.rating),
            ),
          ],
        ),
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
            description,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children:
            services
                .map(
                  (service) => Chip(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 5,
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}

/// 5. Work Gallery
class _WorkGallery extends StatelessWidget {
  const _WorkGallery();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: kDummyWorkImages.length,
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
                kDummyWorkImages[index],
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.red),
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 6. Price Estimate
class _PriceEstimate extends StatelessWidget {
  const _PriceEstimate();

  @override
  Widget build(BuildContext context) {
    final priceText =
        "${kDummyPriceEstimate.toStringAsFixed(2)} DZD/hr (Estimated Base Rate)";

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

  // Helper method for each info row
  Widget _buildInfoRow(IconData icon, String text, {bool isWhatsapp = false}) {
    return Padding(
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
              style: TextStyle(color: kDarkTextColor, fontSize: 16),
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
        boxShadow: [
          BoxShadow(
            color: kSoftShadowColor,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.location_on_outlined, provider.address),
          const Divider(height: 20, thickness: 0.5),
          _buildInfoRow(Icons.phone, provider.phone),
          const Divider(height: 20, thickness: 0.5),
          _buildInfoRow(
            Icons.chat_bubble_rounded,
            provider.whatsapp,
            isWhatsapp: true,
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
        top:
            false, // Ensures button is not pushed up by notch, but padding is correct
        child: ElevatedButton.icon(
          icon: const Icon(Icons.message_rounded, size: 22),
          label: const Text("Message Me", style: TextStyle(fontSize: 18)),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Opening Chat for ${provider.name}')),
            );
          },
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

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'home_constants.dart';
import 'notifications_page.dart';

// Home Header Widget
// In home_widgets.dart - update buildHomeHeader function
Widget buildHomeHeader(
  BuildContext context, {
  required String userName,
  required TextEditingController searchController,
  required Function(String) onSearchChanged,
  int notificationCount = 0, // Add this parameter
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.only(top: 60, left: 25, right: 25, bottom: 25),
    decoration: BoxDecoration(
      color: kPrimaryBlue,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row with Notification Bell
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $userName!',
                  style: kHeaderTextStyle,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Find your perfect service provider',
                  style: kSubHeaderTextStyle,
                ),
              ],
            ),

            // Notification Bell with Badge
            Stack(
              children: [
                IconButton(
                  onPressed: () {
                    showNotificationsWindow(context);
                  },
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                // Notification Badge
                if (notificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        notificationCount > 9
                            ? '9+'
                            : notificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Search Bar
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: kSoftShadowColor,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search for services or providers...',
              hintStyle: TextStyle(color: kMutedTextColor),
              prefixIcon: Icon(Icons.search, color: kPrimaryBlue),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            ),
          ),
        ),
      ],
    ),
  );
}

// In home_widgets.dart - make sure this function exists
Widget _buildNotificationIcon(BuildContext context, int notificationCount) {
  return GestureDetector(
    onTap: () {
      showNotificationsWindow(
          context); // This should open your notifications dialog
    },
    child: Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(CupertinoIcons.bell_fill,
              color: Colors.white, size: 20),
        ),
        if (notificationCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                notificationCount > 9 ? '9+' : notificationCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    ),
  );
}

// Search Field Widget
Widget _buildSearchField(
  TextEditingController searchController,
  Function(String) onSearchChanged,
) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(kDefaultBorderRadius),
    ),
    child: Row(
      children: [
        const Icon(CupertinoIcons.search, color: kMutedTextColor, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: "Search for a service or provider...",
              hintStyle: TextStyle(
                color: kMutedTextColor,
                fontSize: 16,
                fontFamily: 'Exo2',
              ),
            ),
            style: const TextStyle(
              color: kDarkTextColor,
              fontSize: 16,
              fontFamily: 'Exo2',
            ),
          ),
        ),
        if (searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(CupertinoIcons.xmark_circle_fill,
                color: kMutedTextColor, size: 20),
            onPressed: () {
              searchController.clear();
              onSearchChanged('');
            },
          ),
      ],
    ),
  );
}

// Category Item Widget
Widget buildCategoryItem(ServiceCategory category, {VoidCallback? onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: kCardBackgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kSoftShadowColor.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(category.icon, color: kPrimaryBlue, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            category.name,
            style: const TextStyle(
              color: kDarkTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Exo2',
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

// Service Provider Card Widget
Widget buildProviderCard(ServiceProvider provider, {VoidCallback? onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kCardBackgroundColor,
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
        boxShadow: [
          BoxShadow(
            color: kSoftShadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Provider Avatar with network image support
          _buildProviderAvatar(provider),
          const SizedBox(width: 15),

          // Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.name,
                  style: kCardTitleTextStyle,
                ),
                const SizedBox(height: 4),
                Text(
                  provider.category,
                  style: kCardSubtitleTextStyle,
                ),
                const SizedBox(height: 4),
                _buildRatingRow(provider),
                if (provider.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    provider.description,
                    style: kCaptionTextStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Distance and Price
          _buildProviderMetaInfo(provider),
        ],
      ),
    ),
  );
}

// Provider Avatar Widget
Widget _buildProviderAvatar(ServiceProvider provider) {
  return Stack(
    children: [
      CircleAvatar(
        radius: 30,
        backgroundColor: kLightBackgroundColor,
        backgroundImage: provider.imageUrl.isNotEmpty
            ? NetworkImage(provider.imageUrl)
            : null,
        child: provider.imageUrl.isEmpty
            ? Icon(
                CupertinoIcons.person_alt_circle_fill,
                color: kPrimaryBlue,
                size: 35,
              )
            : null,
      ),
      if (provider.isPopular)
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: kPrimaryBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.star_fill,
              color: Colors.white,
              size: 12,
            ),
          ),
        ),
    ],
  );
}

// Rating Row Widget
Widget _buildRatingRow(ServiceProvider provider) {
  return Row(
    children: [
      Icon(CupertinoIcons.star_fill, color: kRatingYellow, size: 14),
      const SizedBox(width: 4),
      Text(
        provider.rating.toString(),
        style: const TextStyle(
          color: kDarkTextColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'Exo2',
        ),
      ),
      const SizedBox(width: 8),
      Text(
        '(${provider.reviews} reviews)',
        style: const TextStyle(
          color: kMutedTextColor,
          fontSize: 12,
          fontFamily: 'Exo2',
        ),
      ),
    ],
  );
}

// Provider Meta Info Widget
Widget _buildProviderMetaInfo(ServiceProvider provider) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        provider.distance,
        style: const TextStyle(
          color: kPrimaryBlue,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'Exo2',
        ),
      ),
      const SizedBox(height: 4),
      if (provider.price > 0)
        Text(
          '\$${provider.price.toStringAsFixed(0)}/hr',
          style: const TextStyle(
            color: kDarkTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'Exo2',
          ),
        ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: kPrimaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'View',
          style: TextStyle(
            color: kPrimaryBlue,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Exo2',
          ),
        ),
      ),
    ],
  );
}

// Loading Shimmer for Categories
Widget buildCategoryShimmer() {
  return SizedBox(
    height: 110,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(right: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 50,
                height: 12,
                color: Colors.grey[300],
              ),
            ],
          ),
        );
      },
    ),
  );
}

// Loading Shimmer for Providers
Widget buildProviderShimmer() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 25.0),
    child: Column(
      children: List.generate(3, (index) => _buildProviderShimmerItem()),
    ),
  );
}

Widget _buildProviderShimmerItem() {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: kCardBackgroundColor,
      borderRadius: BorderRadius.circular(kDefaultBorderRadius),
    ),
    child: Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 16,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 12,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 8),
              Container(
                width: 100,
                height: 12,
                color: Colors.grey[300],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 40,
              height: 16,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 8),
            Container(
              width: 50,
              height: 12,
              color: Colors.grey[300],
            ),
          ],
        ),
      ],
    ),
  );
}

// Error Widget
Widget buildErrorWidget(String message, {VoidCallback? onRetry}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: kMutedTextColor,
            size: 50,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: kBodyTextStyle,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: kPrimaryBlue,
                borderRadius: BorderRadius.circular(kDefaultBorderRadius),
              ),
              child: GestureDetector(
                onTap: onRetry,
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Exo2',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

// Empty State Widget
Widget buildEmptyState({
  required String title,
  required String description,
  required IconData icon,
  Color iconColor = kPrimaryBlue,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 50,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: kDarkTextColor,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              fontFamily: 'Exo2',
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kMutedTextColor,
                fontSize: 16,
                fontFamily: 'Exo2',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// Section Title Widget
Widget buildSectionTitle(String title, {double horizontalPadding = 25.0}) {
  return Padding(
    padding: EdgeInsets.fromLTRB(
      horizontalPadding,
      25,
      horizontalPadding,
      15,
    ),
    child: Text(
      title,
      style: kSectionTitleTextStyle,
    ),
  );
}

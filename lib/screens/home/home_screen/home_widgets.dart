import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/models/CategoryModel.dart';
import 'package:myapp/models/service_provider.dart';
import 'home_constants.dart';
import '../notifications_page.dart';

// Home Header Widget
Widget buildHomeHeader(
  BuildContext context, {
  required String userName,
  required TextEditingController searchController,
  required Function(String) onSearchChanged,
  int notificationCount = 0,
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
            child: SizedBox(
              height: 45,
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: 'Search for services or providers...',
                  hintStyle: TextStyle(color: kMutedTextColor),
                  prefixIcon: Icon(Icons.search, color: kPrimaryBlue),
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero, // IMPORTANT
                ),
              ),
            )),
      ],
    ),
  );
}

Widget buildModernCategoryItem(
  CategoryModel category,
  int index, {
  required bool isSelected,
  required VoidCallback onTap,
}) {
  // Simple color selection
  final colors = [
    const Color(0xFF667EEA),
    const Color(0xFF764BA2),
    const Color(0xFFF093FB),
    const Color(0xFFF5576C),
    const Color(0xFF4FACFE),
    const Color(0xFF00F2FE),
  ];
  final color = colors[index % colors.length];

  // Simple icon selection
  final icon = _getSimpleIcon(category.name);

  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  Color.alphaBlend(Colors.black.withOpacity(0.2), color)
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey.shade50],
              ),
        shape: BoxShape.circle,
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          else
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
        border: isSelected
            ? Border.all(color: Colors.white, width: 2)
            : Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.2)
                  : color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 18,
            ),
          ),
          const SizedBox(height: 6),
          // Category name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              category.name.length > 10
                  ? '${category.name.substring(0, 10)}...'
                  : category.name,
              style: TextStyle(
                color: isSelected ? Colors.white : kDarkTextColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontFamily: 'Exo2',
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ],
      ),
    ),
  );
}

// Simple icon helper
IconData _getSimpleIcon(String categoryName) {
  final name = categoryName.toLowerCase();
  if (name.contains('teach') || name.contains('tutor'))
    return CupertinoIcons.pencil;
  if (name.contains('health') || name.contains('medical'))
    return CupertinoIcons.heart_fill;
  if (name.contains('car') || name.contains('mechanic'))
    return CupertinoIcons.car_fill;
  if (name.contains('clean')) return CupertinoIcons.sparkles;
  if (name.contains('plumb')) return CupertinoIcons.wrench_fill;
  if (name.contains('electric')) return CupertinoIcons.bolt_fill;
  if (name.contains('beauty')) return CupertinoIcons.scissors;
  if (name.contains('garden')) return CupertinoIcons.clear_fill;
  if (name.contains('home')) return CupertinoIcons.house_fill;
  return CupertinoIcons.circle_fill;
}

// SubCategory Grid Widget
Widget buildSubCategoriesGrid({
  required List<CategoryModel> subCategories,
  required String parentCategoryName,
  required VoidCallback onBackTap,
  required Function(CategoryModel) onSubCategoryTap,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button and title
        Row(
          children: [
            GestureDetector(
              onTap: onBackTap,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kPrimaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, color: kPrimaryBlue, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                parentCategoryName,
                style: const TextStyle(
                  color: kDarkTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Exo2',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Subcategories grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.9,
          ),
          itemCount: subCategories.length,
          itemBuilder: (context, index) {
            final subCategory = subCategories[index];
            final colors = [
              const Color(0xFF667EEA),
              const Color(0xFF764BA2),
              const Color(0xFFF093FB),
            ];
            final color = colors[index % colors.length];
            final icon = _getSimpleIcon(subCategory.name);

            return GestureDetector(
              onTap: () => onSubCategoryTap(subCategory),
              child: Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        subCategory.name.length > 12
                            ? '${subCategory.name.substring(0, 12)}...'
                            : subCategory.name,
                        style: const TextStyle(
                          color: kDarkTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Exo2',
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
}

// Modern Categories Section
Widget buildModernCategoriesSection({
  required List<CategoryModel> categories,
  required CategoryModel? selectedCategory,
  required Function(CategoryModel) onCategorySelected,
  required Function() onCategoryDeselected,
  required List<CategoryModel> subCategories,
  required bool showSubCategories,
  required Function(CategoryModel) onSubCategorySelected,
}) {
  const SizedBox(height: 60);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 60),
      // Section title
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Explore Services',
              style: TextStyle(
                color: kDarkTextColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'Exo2',
              ),
            ),
            if (selectedCategory != null)
              GestureDetector(
                onTap: onCategoryDeselected,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPrimaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: kPrimaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Exo2',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 20),

      // Main categories (circular)
      SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = selectedCategory?.id == category.id;

            return buildModernCategoryItem(
              category,
              index,
              isSelected: isSelected,
              onTap: () => onCategorySelected(category),
            );
          },
        ),
      ),

      // Subcategories section
      if (showSubCategories && selectedCategory != null) ...[
        const SizedBox(height: 20),
        buildSubCategoriesGrid(
          subCategories: subCategories,
          parentCategoryName: selectedCategory.name,
          onBackTap: onCategoryDeselected,
          onSubCategoryTap: onSubCategorySelected,
        ),
      ],

      const SizedBox(height: 10),
    ],
  );
}

// KEEP YOUR EXISTING WIDGETS BELOW - THEY SHOULD WORK FINE

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
          // Provider Avatar
          _buildProviderAvatar(provider),
          const SizedBox(width: 15),
          // Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider.name, style: kCardTitleTextStyle),
                const SizedBox(height: 4),
                Text(provider.category, style: kCardSubtitleTextStyle),
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
            ? Icon(CupertinoIcons.person_alt_circle_fill,
                color: kPrimaryBlue, size: 35)
            : null,
      ),
      if (provider.isPopular)
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
                color: kPrimaryBlue, shape: BoxShape.circle),
            child: const Icon(CupertinoIcons.star_fill,
                color: Colors.white, size: 12),
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
      Text(provider.rating.toString(),
          style: const TextStyle(
              color: kDarkTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Exo2')),
      const SizedBox(width: 8),
      Text('(${provider.reviews} reviews)',
          style: const TextStyle(
              color: kMutedTextColor, fontSize: 12, fontFamily: 'Exo2')),
    ],
  );
}

// Provider Meta Info Widget
Widget _buildProviderMetaInfo(ServiceProvider provider) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(provider.distance,
          style: const TextStyle(
              color: kPrimaryBlue,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Exo2')),
      const SizedBox(height: 4),
      if (provider.price > 0)
        Text('\$${provider.price.toStringAsFixed(0)}/hr',
            style: const TextStyle(
                color: kDarkTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Exo2')),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: kPrimaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: const Text('View',
            style: TextStyle(
                color: kPrimaryBlue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Exo2')),
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
                      color: Colors.grey[300], shape: BoxShape.circle)),
              const SizedBox(height: 8),
              Container(width: 50, height: 12, color: Colors.grey[300]),
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
        borderRadius: BorderRadius.circular(kDefaultBorderRadius)),
    child: Row(
      children: [
        Container(
            width: 60,
            height: 60,
            decoration:
                BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle)),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 120, height: 16, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Container(width: 80, height: 12, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Container(width: 100, height: 12, color: Colors.grey[300]),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(width: 40, height: 16, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Container(width: 50, height: 12, color: Colors.grey[300]),
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
          Icon(CupertinoIcons.exclamationmark_triangle,
              color: kMutedTextColor, size: 50),
          const SizedBox(height: 16),
          Text(message, style: kBodyTextStyle, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                  color: kPrimaryBlue,
                  borderRadius: BorderRadius.circular(kDefaultBorderRadius)),
              child: GestureDetector(
                onTap: onRetry,
                child: const Text('Try Again',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Exo2')),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

// Section Title Widget
Widget buildSectionTitle(String title, {double horizontalPadding = 25.0}) {
  return Padding(
    padding: EdgeInsets.fromLTRB(horizontalPadding, 25, horizontalPadding, 15),
    child: Text(title, style: kSectionTitleTextStyle),
  );
}

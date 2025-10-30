import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'home_constants.dart';


Widget buildHomeHeader(BuildContext context) {
  final double topPadding = MediaQuery.of(context).padding.top;

  return Container(
    padding: EdgeInsets.fromLTRB(25, topPadding + 15, 25, 25),
    decoration: const BoxDecoration(
      color: kPrimaryBlue,
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Row: Menu and Notifications
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            Icon(CupertinoIcons.bell_fill, color: Colors.white, size: 26),
          ],
        ),
        const SizedBox(height: 25),

        // Welcome Text
        const Text(
          "Hello, Julian!",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontFamily: 'Exo2',
          ),
        ),
        const Text(
          "What service do you need today?",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            fontFamily: 'Exo2',
          ),
        ),
        const SizedBox(height: 20),

        // Search Field (Matching the Chat Page design)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Row(
            children: [
              Icon(CupertinoIcons.search, color: kMutedTextColor, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Search for a service or provider...",
                  style: TextStyle(
                    color: kMutedTextColor,
                    fontSize: 16,
                    fontFamily: 'Exo2',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// Builds a single circular icon button for a service category
Widget buildCategoryItem(ServiceCategory category) {
  return Padding(
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
        ),
      ],
    ),
  );
}

// Builds a card for a single popular service provider
Widget buildProviderCard(ServiceProvider provider) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: kCardBackgroundColor,
      borderRadius: BorderRadius.circular(15),
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
        CircleAvatar(
          radius: 30,
          backgroundColor: kLightBackgroundColor,
          child: Icon(
            CupertinoIcons.person_alt_circle_fill,
            color: kPrimaryBlue,
            size: 35,
          ),
        ),
        const SizedBox(width: 15),

        // Info Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.name,
                style: const TextStyle(
                  color: kDarkTextColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Exo2',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                provider.category,
                style: const TextStyle(
                  color: kMutedTextColor,
                  fontSize: 13,
                  fontFamily: 'Exo2',
                ),
              ),
            ],
          ),
        ),

        // Rating and Distance
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Icon(CupertinoIcons.star_fill, color: kRatingYellow, size: 16),
                const SizedBox(width: 4),
                Text(
                  provider.rating.toString(),
                  style: const TextStyle(
                    color: kDarkTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Exo2',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              provider.distance,
              style: const TextStyle(
                color: kPrimaryBlue,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Exo2',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

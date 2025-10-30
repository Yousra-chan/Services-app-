import 'package:flutter/material.dart';
import 'home_constants.dart';
import 'home_widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Curved Blue Header with Search Bar
            buildHomeHeader(context),

            // 2. Categories Section Title
            _buildSectionTitle("Explore Categories", 25.0),

            // 3. Horizontal Category List
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return buildCategoryItem(categories[index]);
                },
              ),
            ),

            // 4. Popular Providers Section Title
            _buildSectionTitle("Popular Providers Near You", 25.0),

            // 5. Vertical List of Providers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                children:
                    popularProviders.map((provider) {
                      return buildProviderCard(provider);
                    }).toList(),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- Local Helper Widget ---
  Widget _buildSectionTitle(String title, double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        25,
        horizontalPadding,
        15,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: kDarkTextColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Exo2',
        ),
      ),
    );
  }
}

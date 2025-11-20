import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_constants.dart';
import 'home_widgets.dart';
import 'package:myapp/ViewModel/auth_view_model.dart'; // Import auth view model

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _userName = 'Guest';
  bool _useAlternativeSearch = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkFirestoreStructure();
  }

  void _loadUserData() {
    final user = FirebaseService.currentUser;
    if (user != null) {
      FirebaseService.getUserData(user.uid).listen((userData) {
        if (mounted) {
          setState(() {
            _userName = userData['name'] ?? user.displayName ?? 'User';
          });
        }
      });
    }
  }

  void _checkFirestoreStructure() {
    _useAlternativeSearch = true;
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final currentUser = authViewModel.currentUser;

    return Scaffold(
      backgroundColor: kLightBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Curved Blue Header with Search Bar and Notifications
            _buildHomeHeaderWithNotifications(context, currentUser?.uid),

            // 2. Categories Section Title
            _buildSectionTitle("Explore Categories", 25.0),

            // 3. Horizontal Category List from Firestore
            SizedBox(
              height: 110,
              child: StreamBuilder<List<ServiceCategory>>(
                stream: FirebaseService.getCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildCategoryShimmer();
                  }

                  if (snapshot.hasError) {
                    print('Categories Error: ${snapshot.error}');
                    return _buildErrorWidget('Failed to load categories');
                  }

                  final categories = snapshot.data ?? defaultCategories;

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return buildCategoryItem(categories[index]);
                    },
                  );
                },
              ),
            ),

            // 4. Popular Providers Section Title
            _buildSectionTitle("Popular Providers Near You", 25.0),

            // 5. Vertical List of Providers from Firestore
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: _buildProvidersList(),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Updated header with notification count
  Widget _buildHomeHeaderWithNotifications(
      BuildContext context, String? userId) {
    return StreamBuilder<int>(
      stream: userId != null && userId.isNotEmpty
          ? FirebaseService.getUnreadNotificationCount(userId)
          : Stream.value(0),
      builder: (context, snapshot) {
        print(
            '🔔 Notification count stream - Connection: ${snapshot.connectionState}');
        print('🔔 Notification count stream - Has data: ${snapshot.hasData}');
        print('🔔 Notification count stream - Has error: ${snapshot.hasError}');

        if (snapshot.hasError) {
          print('❌ Notification count error: ${snapshot.error}');
        }

        final notificationCount = snapshot.data ?? 0;
        print('🔔 Current notification count: $notificationCount');

        return buildHomeHeader(
          context,
          userName: _userName,
          searchController: _searchController,
          onSearchChanged: (query) {
            setState(() {
              _searchQuery = query;
            });
          },
          notificationCount: notificationCount,
        );
      },
    );
  }

  Widget _buildProvidersList() {
    if (_searchQuery.isNotEmpty) {
      if (_useAlternativeSearch) {
        return StreamBuilder<List<ServiceProvider>>(
          stream: FirebaseService.searchProvidersAlternative(_searchQuery),
          builder: (context, snapshot) {
            return _buildProviderContent(snapshot, isSearch: true);
          },
        );
      } else {
        return StreamBuilder<List<ServiceProvider>>(
          stream: FirebaseService.searchProviders(_searchQuery),
          builder: (context, snapshot) {
            return _buildProviderContent(snapshot, isSearch: true);
          },
        );
      }
    } else {
      return StreamBuilder<List<ServiceProvider>>(
        stream: FirebaseService.getPopularProviders(),
        builder: (context, snapshot) {
          return _buildProviderContent(snapshot);
        },
      );
    }
  }

  Widget _buildProviderContent(
    AsyncSnapshot<List<ServiceProvider>> snapshot, {
    bool isSearch = false,
  }) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildProviderShimmer();
    }

    if (snapshot.hasError) {
      print('Providers Error: ${snapshot.error}');
      return _buildErrorWidget('Failed to load providers');
    }

    final providers = snapshot.data ?? [];

    if (isSearch && providers.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              color: kMutedTextColor,
              size: 50,
            ),
            const SizedBox(height: 10),
            Text(
              'No providers found for "$_searchQuery"',
              style: const TextStyle(
                color: kMutedTextColor,
                fontSize: 16,
                fontFamily: 'Exo2',
              ),
            ),
          ],
        ),
      );
    }

    if (providers.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              color: kMutedTextColor,
              size: 50,
            ),
            const SizedBox(height: 10),
            const Text(
              'No providers available',
              style: TextStyle(
                color: kMutedTextColor,
                fontSize: 16,
                fontFamily: 'Exo2',
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: providers.map((provider) {
        return buildProviderCard(provider);
      }).toList(),
    );
  }

  Widget _buildCategoryShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      itemCount: 4,
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
    );
  }

  Widget _buildProviderShimmer() {
    return Column(
      children: List.generate(3, (index) => _buildProviderShimmerItem()),
    );
  }

  Widget _buildProviderShimmerItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kCardBackgroundColor,
        borderRadius: BorderRadius.circular(15),
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

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: kMutedTextColor,
              size: 50,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                color: kMutedTextColor,
                fontSize: 16,
                fontFamily: 'Exo2',
              ),
              textAlign: TextAlign.center,
            ),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

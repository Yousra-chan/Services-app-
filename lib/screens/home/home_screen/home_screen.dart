import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/models/UserModel.dart';
import 'package:myapp/screens/home/home_screen/home_header_widget.dart';
import 'package:myapp/screens/home/notifications_page.dart';
import 'package:myapp/services/firebase_service.dart';
import 'package:myapp/models/CategoryModel.dart';
import 'package:provider/provider.dart';
import 'package:myapp/ViewModel/auth_view_model.dart';
import 'package:myapp/ViewModel/service_view_model.dart';
import 'home_constants.dart';
import 'categories_section.dart';
import 'subcategories_page.dart';
import 'create_service_button.dart';
import 'package:myapp/screens/service/create_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  UserModel? _currentUser;
  int _notificationCount = 0;
  StreamSubscription? _notificationCountSubscription;

  CategoryModel? _selectedCategory;
  List<CategoryModel> _categories = [];
  List<CategoryModel> _subCategories = [];
  bool _showSubCategories = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCategories();
    _loadNotificationCount();
  }

  void _loadUserData() {
    final user = FirebaseService.currentUser;
    if (user != null) {
      FirebaseService.getUserData(user.uid).listen((userData) {
        if (mounted && userData.exists && userData.data() != null) {
          setState(() {
            _currentUser = UserModel.fromMap(
                userData.data()! as Map<String, dynamic>, user.uid);
          });
        }
      });
    }
  }

  void _loadCategories() {
    FirebaseService.getCategories().listen((categories) {
      if (mounted) {
        setState(() {
          _categories = categories.isNotEmpty
              ? categories
              : CategoryModel.defaultCategories;
        });
      }
    }, onError: (error) {
      print('Error loading categories: $error');
      if (mounted) {
        setState(() {
          _categories = CategoryModel.defaultCategories;
        });
      }
    });
  }

  void _loadNotificationCount() {
    final user = FirebaseService.currentUser;
    print('🔔 [HomeScreen] Loading notification count for user: ${user?.uid}');

    if (user != null && user.uid.isNotEmpty) {
      _notificationCountSubscription?.cancel();

      _notificationCountSubscription =
          FirebaseService.getUnreadNotificationCount(user.uid).listen((count) {
        print('🔔 [HomeScreen] Notification count updated: $count');
        if (mounted) {
          setState(() {
            _notificationCount = count;
          });
        }
      }, onError: (error) {
        print('❌ [HomeScreen] Error in notification count stream: $error');
        if (mounted) {
          setState(() {
            _notificationCount = 0;
          });
        }
      });
    } else {
      print('❌ [HomeScreen] No valid user found for notifications');
      if (mounted) {
        setState(() {
          _notificationCount = 0;
        });
      }
    }
  }

  void _onCategorySelected(CategoryModel category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadSubCategories(
        category.id); // ADDED: Load subcategories when category is selected
  }

  void _loadSubCategories(String categoryId) {
    FirebaseService.getSubCategories(categoryId).listen((subCategories) {
      if (mounted) {
        setState(() {
          // FIXED: Proper subcategory conversion
          try {
            _subCategories = (subCategories as List).map((item) {
              if (item is CategoryModel) {
                return item;
              } else if (item is Map<String, dynamic>) {
                return CategoryModel.fromMap(item, item['id'] ?? 'temp_id');
              }
              return CategoryModel(
                id: 'temp',
                name: 'Unknown',
                description: '',
                icon: CupertinoIcons.circle_fill,
                iconCode: 'unknown',
                subcategories: [],
              );
            }).toList();
          } catch (e) {
            print('Error converting subcategories: $e');
            _subCategories = _getDefaultSubCategories(categoryId);
          }

          if (_subCategories.isEmpty) {
            _subCategories = _getDefaultSubCategories(categoryId);
          }
        });
      }
    }, onError: (error) {
      print('Error loading subcategories: $error');
      if (mounted) {
        setState(() {
          _subCategories = _getDefaultSubCategories(categoryId);
        });
      }
    });
  }

  List<CategoryModel> _getDefaultSubCategories(String categoryId) {
    switch (categoryId) {
      case '1': // Cleaning
        return [
          CategoryModel(
            id: 'sub1',
            name: 'House Cleaning',
            description: 'Complete house cleaning services',
            icon: CupertinoIcons.house_fill,
            iconCode: 'house_clean',
            subcategories: [],
          ),
          CategoryModel(
            id: 'sub2',
            name: 'Office Cleaning',
            description: 'Professional office cleaning',
            icon: CupertinoIcons.building_2_fill,
            iconCode: 'office_clean',
            subcategories: [],
          ),
          CategoryModel(
            id: 'sub3',
            name: 'Carpet Cleaning',
            description: 'Deep carpet cleaning',
            icon: CupertinoIcons
                .rectangle_fill, // FIXED: Changed from square_fill
            iconCode: 'carpet_clean',
            subcategories: [],
          ),
        ];
      case '2': // Plumbing
        return [
          CategoryModel(
            id: 'sub1',
            name: 'Emergency Repair',
            description: '24/7 emergency plumbing',
            icon: CupertinoIcons.exclamationmark_triangle_fill,
            iconCode: 'emergency_plumb',
            subcategories: [],
          ),
          CategoryModel(
            id: 'sub2',
            name: 'Pipe Installation',
            description: 'New pipe installation',
            icon: CupertinoIcons.wrench_fill,
            iconCode: 'pipe_install',
            subcategories: [],
          ),
          CategoryModel(
            id: 'sub3',
            name: 'Leak Detection',
            description: 'Professional leak detection',
            icon: CupertinoIcons.drop_fill,
            iconCode: 'leak_detect',
            subcategories: [],
          ),
        ];
      case '10': // Teaching
        return [
          CategoryModel(
            id: 'sub1',
            name: 'Math Tutor',
            description: 'Mathematics tutoring',
            icon: CupertinoIcons
                .number_circle_fill, // FIXED: Changed from number_square_fill
            iconCode: 'math_tutor',
            subcategories: [],
          ),
          CategoryModel(
            id: 'sub2',
            name: 'Language',
            description: 'Language lessons',
            icon: CupertinoIcons.text_bubble_fill,
            iconCode: 'language',
            subcategories: [],
          ),
          CategoryModel(
            id: 'sub3',
            name: 'Science',
            description: 'Science subjects',
            icon: CupertinoIcons.lab_flask,
            iconCode: 'science',
            subcategories: [],
          ),
          CategoryModel(
            id: 'sub4',
            name: 'Music',
            description: 'Music lessons',
            icon: CupertinoIcons.music_note_2,
            iconCode: 'music',
            subcategories: [],
          ),
          CategoryModel(
            id: 'sub5',
            name: 'Art',
            description: 'Art and drawing',
            icon: CupertinoIcons.paintbrush_fill,
            iconCode: 'art',
            subcategories: [],
          ),
          CategoryModel(
            id: 'sub6',
            name: 'Programming',
            description: 'Coding and programming',
            icon: CupertinoIcons.desktopcomputer,
            iconCode: 'programming',
            subcategories: [],
          ),
        ];
      default:
        return [
          CategoryModel(
            id: 'sub1',
            name: 'Basic Service',
            description: 'Standard service package',
            icon: CupertinoIcons.circle_fill,
            iconCode: 'basic',
            subcategories: [],
          ),
          CategoryModel(
            id: 'sub2',
            name: 'Premium Service',
            description: 'Premium service package',
            icon: CupertinoIcons.star_fill,
            iconCode: 'premium',
            subcategories: [],
          ),
        ];
    }
  }

  void _navigateToServiceCreation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthViewModel()),
            ChangeNotifierProvider(create: (_) => ServiceViewModel()),
          ],
          child: const CreateServiceScreen(),
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  void _showNotificationsWindow(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsWindow(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showSubCategories && _selectedCategory != null) {
      return SubcategoriesPage(
        selectedCategory: _selectedCategory!,
        subCategories: _subCategories,
        onBackPressed: () {
          setState(() {
            _showSubCategories = false;
          });
        },
      );
    }

    return Scaffold(
      backgroundColor: kLightBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  HomeHeader(
                    currentUser: _currentUser,
                    searchController: _searchController,
                    onSearchChanged: _onSearchChanged,
                    notificationCount: _notificationCount,
                    onNotificationPressed: () =>
                        _showNotificationsWindow(context),
                  ),
                  CategoriesSection(
                    categories: _categories,
                    selectedCategory: _selectedCategory,
                    currentUser: _currentUser,
                    onCategorySelected: _onCategorySelected,
                    onShowSubCategories: (category, subCategories) {
                      setState(() {
                        _selectedCategory = category;
                        _subCategories = subCategories;
                        _showSubCategories = true;
                      });
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          CreateServiceButton(
            onPressed: _navigateToServiceCreation,
            isProvider: _currentUser?.isProvider ?? false,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notificationCountSubscription?.cancel();
    super.dispose();
  }
}

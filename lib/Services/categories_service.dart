import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/models/CategoryModel.dart';

class CategoriesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all available categories (defaults + Firestore data)
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      // Get services from Firestore
      final servicesSnapshot = await _firestore.collection('services').get();

      // Start with default categories
      final categories = CategoryModel.defaultCategories;

      // Process Firestore services to find unique categories
      final firestoreCategories = <String, Map<String, SubcategoryModel>>{};

      for (var doc in servicesSnapshot.docs) {
        final data = doc.data();
        final serviceCategory = data['category']?.toString()?.trim() ?? '';
        final serviceSubcategory =
            data['subcategory']?.toString()?.trim() ?? '';

        if (serviceCategory.isNotEmpty) {
          firestoreCategories[serviceCategory] ??= {};

          if (serviceSubcategory.isNotEmpty) {
            firestoreCategories[serviceCategory]![serviceSubcategory] =
                SubcategoryModel(
              id: '${serviceCategory}_$serviceSubcategory',
              name: serviceSubcategory,
              description: 'Service in $serviceCategory',
              icon: CupertinoIcons.circle_fill,
              iconCode: 'circle_fill',
            );
          }
        }
      }

      // Merge Firestore categories with defaults
      final mergedCategories = <CategoryModel>[];

      // Add all default categories
      mergedCategories.addAll(categories);

      // Add new categories from Firestore that aren't in defaults
      for (var entry in firestoreCategories.entries) {
        final categoryName = entry.key;
        final subcategoriesMap = entry.value;

        final existingCategory = categories.firstWhere(
          (cat) => cat.name.toLowerCase() == categoryName.toLowerCase(),
          orElse: () => CategoryModel(
            id: categoryName.toLowerCase(),
            name: categoryName,
            description: '$categoryName Services',
            icon: CupertinoIcons.circle_fill,
            iconCode: categoryName.toLowerCase(),
            subcategories: [],
          ),
        );

        // Add to merged list if not already present
        if (!mergedCategories.any((cat) => cat.name == categoryName)) {
          mergedCategories.add(existingCategory);
        }

        // Add subcategories
        for (var subEntry in subcategoriesMap.entries) {
          final subcategoryName = subEntry.key;
          final subcategoryModel = subEntry.value;

          // Check if subcategory already exists
          if (!existingCategory.subcategories
              .any((sub) => sub.name == subcategoryName)) {
            existingCategory.subcategories.add(subcategoryModel);
          }
        }
      }

      return mergedCategories;
    } catch (e) {
      print('❌ Error getting categories: $e');
      return CategoryModel.defaultCategories;
    }
  }

  // Get categories as map for dropdowns
  Future<Map<String, List<String>>> getCategoriesForFilter() async {
    final categories = await getAllCategories();

    final result = <String, List<String>>{};

    for (var category in categories) {
      result[category.name] =
          category.subcategories.map((sub) => sub.name).toList();
    }

    return result;
  }

  // In categories_service.dart
// Get category by name - SIMPLE VERSION
  CategoryModel? getCategoryByName(String name) {
    try {
      // Search in default categories
      return CategoryModel.defaultCategories.firstWhere(
        (category) => category.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      print('Category "$name" not found in default categories');
      return null;
    }
  }

  // Get subcategory by name within a category
  Future<SubcategoryModel?> getSubcategoryByName(
      String categoryName, String subcategoryName) async {
    final category = await getCategoryByName(categoryName);
    if (category == null) return null;

    return category.subcategories.firstWhere(
      (sub) => sub.name.toLowerCase() == subcategoryName.toLowerCase(),
      orElse: () => SubcategoryModel(
        id: '${categoryName}_$subcategoryName',
        name: subcategoryName,
        description: '$subcategoryName under $categoryName',
        icon: CupertinoIcons.circle_fill,
        iconCode: 'circle_fill',
      ),
    );
  }
}

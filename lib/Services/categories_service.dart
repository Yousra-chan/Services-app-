import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/models/CategoryModel.dart';

class CategoriesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all categories from Firestore services
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      // Get all active services from Firestore
      final servicesSnapshot = await _firestore
          .collection('services')
          .where('isActive', isEqualTo: true)
          .get();

      // Map to store categories and their subcategories
      final categoryMap = <String, Map<String, SubcategoryModel>>{};

      // Process services to extract categories and subcategories
      for (var doc in servicesSnapshot.docs) {
        final data = doc.data();
        final serviceCategory = data['category']?.toString().trim() ?? '';
        final serviceSubcategory = data['subcategory']?.toString().trim() ?? '';

        if (serviceCategory.isNotEmpty) {
          // Initialize category if not exists
          categoryMap[serviceCategory] ??= {};

          // Add subcategory if exists
          if (serviceSubcategory.isNotEmpty) {
            categoryMap[serviceCategory]![serviceSubcategory] =
                SubcategoryModel(
              id: '${serviceCategory}_$serviceSubcategory'.replaceAll(' ', '_'),
              name: serviceSubcategory,
              description: '$serviceSubcategory under $serviceCategory',
              icon: CupertinoIcons.circle_fill,
              iconCode: 'circle_fill',
            );
          }
        }
      }

      // Convert map to CategoryModel list
      final categories = <CategoryModel>[];
      categoryMap.forEach((categoryName, subcategoriesMap) {
        categories.add(CategoryModel(
          id: categoryName.toLowerCase().replaceAll(' ', '_'),
          name: categoryName,
          description: '$categoryName Services',
          icon: CategoryModel.getIconFromCode(categoryName.toLowerCase()),
          iconCode: categoryName.toLowerCase(),
          subcategories: subcategoriesMap.values.toList(),
        ));
      });

      // Merge with default categories
      final defaultCategories = CategoryModel.defaultCategories;
      final mergedCategories = <CategoryModel>[];

      // Add all default categories first
      for (var defaultCat in defaultCategories) {
        final existingCat = categories.firstWhere(
          (cat) => cat.name.toLowerCase() == defaultCat.name.toLowerCase(),
          orElse: () => defaultCat,
        );

        // Merge subcategories
        final defaultSubs = defaultCat.subcategories.map((e) => e.name).toSet();
        final existingSubs =
            existingCat.subcategories.map((e) => e.name).toSet();

        if (defaultSubs.isNotEmpty) {
          for (var sub in defaultCat.subcategories) {
            if (!existingSubs.contains(sub.name)) {
              existingCat.subcategories.add(sub);
            }
          }
        }

        mergedCategories.add(existingCat);
      }

      // Add categories from Firestore not in defaults
      for (var firestoreCat in categories) {
        if (!mergedCategories.any((cat) => cat.name == firestoreCat.name)) {
          mergedCategories.add(firestoreCat);
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

  // Get category by name
  CategoryModel? getCategoryByName(String name) {
    try {
      final defaultCategories = CategoryModel.defaultCategories;
      final lowerName = name.toLowerCase();

      for (var category in defaultCategories) {
        if (category.name.toLowerCase() == lowerName) {
          return category;
        }
      }

      // If not found, create a simple category
      return CategoryModel(
        id: lowerName.replaceAll(' ', '_'),
        name: name,
        description: '$name Services',
        icon: CupertinoIcons.circle_fill,
        iconCode: 'circle_fill',
        subcategories: [],
      );
    } catch (e) {
      print('❌ Error in getCategoryByName for "$name": $e');
      return null;
    }
  }

  // Get subcategory by name within a category
  Future<SubcategoryModel?> getSubcategoryByName(
      String categoryName, String subcategoryName) async {
    final category = getCategoryByName(categoryName);
    if (category == null) return null;

    return category.subcategories.firstWhere(
      (sub) => sub.name.toLowerCase() == subcategoryName.toLowerCase(),
      orElse: () => SubcategoryModel(
        id: '${categoryName}_$subcategoryName'.replaceAll(' ', '_'),
        name: subcategoryName,
        description: '$subcategoryName under $categoryName',
        icon: CupertinoIcons.circle_fill,
        iconCode: 'circle_fill',
      ),
    );
  }
}

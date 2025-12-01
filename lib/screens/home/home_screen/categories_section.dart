import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/models/CategoryModel.dart';
import 'package:myapp/models/UserModel.dart';
import 'home_constants.dart';

class CategoriesSection extends StatefulWidget {
  final List<CategoryModel> categories;
  final CategoryModel? selectedCategory;
  final UserModel? currentUser;
  final Function(CategoryModel) onCategorySelected;
  final Function(CategoryModel, List<CategoryModel>)
      onShowSubCategories; // Updated callback

  const CategoriesSection({
    Key? key,
    required this.categories,
    required this.selectedCategory,
    required this.currentUser,
    required this.onCategorySelected,
    required this.onShowSubCategories, // Now accepts category and subcategories
  }) : super(key: key);

  @override
  State<CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<CategoriesSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Method to generate subcategories for a given category
  List<CategoryModel> _generateSubCategoriesForCategory(
      CategoryModel mainCategory) {
    switch (mainCategory.name.toLowerCase()) {
      case 'cleaning':
        return [
          CategoryModel(
            id: '${mainCategory.id}_1',
            name: 'Home Cleaning',
            description: 'Full home cleaning and maintenance',
            icon: CupertinoIcons.house_fill,
            iconCode: 'home_cleaning',
            subcategories: [], // Added
          ),
          CategoryModel(
            id: '${mainCategory.id}_2',
            name: 'Office Cleaning',
            description: 'Office and workspace cleaning',
            icon: CupertinoIcons.briefcase_fill,
            iconCode: 'office_cleaning',
            subcategories: [], // Added
          ),
          CategoryModel(
            id: '${mainCategory.id}_3',
            name: 'Deep Cleaning',
            description: 'Thorough deep cleaning service',
            icon: CupertinoIcons.sparkles,
            iconCode: 'deep_cleaning',
            subcategories: [], // Added
          ),
          CategoryModel(
            id: '${mainCategory.id}_4',
            name: 'Carpet Cleaning',
            description: 'Professional carpet and rug cleaning',
            icon: CupertinoIcons.rectangle_fill,
            iconCode: 'carpet_cleaning',
            subcategories: [], // Added
          ),
        ];

      case 'plumbing':
        return [
          CategoryModel(
            id: '${mainCategory.id}_1',
            name: 'Pipe Repair',
            description: 'Pipe fixing and maintenance',
            icon: CupertinoIcons.wrench_fill,
            iconCode: 'pipe_repair',
            subcategories: [], // Added
          ),
          CategoryModel(
            id: '${mainCategory.id}_2',
            name: 'Leak Fixing',
            description: 'Water leak detection and repair',
            icon: CupertinoIcons.drop_fill,
            iconCode: 'leak_fixing',
            subcategories: [], // Added
          ),
          CategoryModel(
            id: '${mainCategory.id}_3',
            name: 'Fixture Installation',
            description: 'Sink, toilet, and faucet installation',
            icon: CupertinoIcons.settings,
            iconCode: 'fixture_installation',
            subcategories: [], // Added
          ),
        ];

      case 'electrical':
        return [
          CategoryModel(
            id: '${mainCategory.id}_1',
            name: 'Wiring Installation',
            description: 'Electrical wiring and cabling',
            icon: CupertinoIcons.bolt_fill,
            iconCode: 'wiring_installation',
            subcategories: [], // Added
          ),
          CategoryModel(
            id: '${mainCategory.id}_2',
            name: 'Outlet Repair',
            description: 'Socket and outlet fixing',
            icon: CupertinoIcons.power,
            iconCode: 'outlet_repair',
            subcategories: [], // Added
          ),
          CategoryModel(
            id: '${mainCategory.id}_3',
            name: 'Lighting Installation',
            description: 'Light fixture installation',
            icon: CupertinoIcons.lightbulb_fill,
            iconCode: 'lighting_installation',
            subcategories: [], // Added
          ),
        ];

      default:
        return [
          CategoryModel(
            id: '${mainCategory.id}_1',
            name: 'Basic ${mainCategory.name}',
            description: 'Standard ${mainCategory.name.toLowerCase()} service',
            icon: mainCategory.icon,
            iconCode: 'basic_${mainCategory.name.toLowerCase()}',
            subcategories: [], // Added
          ),
          CategoryModel(
            id: '${mainCategory.id}_2',
            name: 'Advanced ${mainCategory.name}',
            description:
                'Advanced ${mainCategory.name.toLowerCase()} solutions',
            icon: mainCategory.icon,
            iconCode: 'advanced_${mainCategory.name.toLowerCase()}',
            subcategories: [], // Added
          ),
          CategoryModel(
            id: '${mainCategory.id}_3',
            name: 'Emergency ${mainCategory.name}',
            description:
                '24/7 emergency ${mainCategory.name.toLowerCase()} service',
            icon: CupertinoIcons.exclamationmark_triangle_fill,
            iconCode: 'emergency_${mainCategory.name.toLowerCase()}',
            subcategories: [], // Added
          ),
        ];
    }
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.currentUser?.isProvider ?? false
                  ? 'Service Categories'
                  : 'Browse Categories',
              style: const TextStyle(
                color: kDarkTextColor,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                fontFamily: 'Exo2',
                letterSpacing: -0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kPrimaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kPrimaryBlue.withOpacity(0.2)),
              ),
              child: Text(
                '${widget.categories.length}',
                style: TextStyle(
                  color: kPrimaryBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Exo2',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Select a category to explore services',
          style: TextStyle(
            color: kMutedTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Exo2',
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesList() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: widget.categories.length,
        itemBuilder: (context, index) {
          final category = widget.categories[index];
          final isSelected = widget.selectedCategory?.id == category.id;
          final colors = _getCategoryColors(index);

          return Container(
            margin: EdgeInsets.only(
              right: 16,
              left: index == 0 ? 0 : 0,
            ),
            child: _buildCategoryItem(category, colors, isSelected, index),
          );
        },
      ),
    );
  }

  Widget _buildCategoryItem(
    CategoryModel category,
    List<Color> colors,
    bool isSelected,
    int index,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: isSelected ? 100 : 90,
      child: Column(
        children: [
          // Category Circle
          GestureDetector(
            onTap: () => widget.onCategorySelected(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isSelected ? 70 : 64,
              height: isSelected ? 70 : 64,
              decoration: BoxDecoration(
                color: isSelected ? colors[0] : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colors[0] : Colors.grey.shade300,
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: colors[0].withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              child: Icon(
                category.icon,
                color: isSelected ? Colors.white : colors[0],
                size: isSelected ? 28 : 24,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Category Name
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _truncateCategoryName(category.name),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? colors[0] : kDarkTextColor,
                fontSize: isSelected ? 13 : 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontFamily: 'Exo2',
              ),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCategoryDetail() {
    final selectedIndex = widget.categories
        .indexWhere((cat) => cat.id == widget.selectedCategory!.id);
    final colors = _getCategoryColors(selectedIndex);

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            // Icon with background
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.selectedCategory!.icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.selectedCategory!.name,
                    style: const TextStyle(
                      color: kDarkTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Exo2',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.currentUser?.isProvider ?? false
                        ? 'Offer ${widget.selectedCategory!.name.toLowerCase()} services'
                        : 'Find ${widget.selectedCategory!.name.toLowerCase()} professionals',
                    style: TextStyle(
                      color: kMutedTextColor,
                      fontSize: 13,
                      fontFamily: 'Exo2',
                    ),
                  ),
                ],
              ),
            ),
            // Action button
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () {
                  // Generate subcategories and pass them to the callback
                  final subCategories = _generateSubCategoriesForCategory(
                      widget.selectedCategory!);
                  widget.onShowSubCategories(
                      widget.selectedCategory!, subCategories);
                },
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _truncateCategoryName(String name) {
    if (name.length <= 12) return name;
    return '${name.substring(0, 10)}...';
  }

  List<Color> _getCategoryColors(int index) {
    const colorSchemes = [
      [Color(0xFF667EEA), Color(0xFF764BA2)], // Purple
      [Color(0xFF4FACFE), Color(0xFF00F2FE)], // Blue
      [Color(0xFF43E97B), Color(0xFF38F9D7)], // Green
      [Color(0xFFFA709A), Color(0xFFFEE140)], // Pink/Yellow
      [Color(0xFFF093FB), Color(0xFFF5576C)], // Magenta
      [Color(0xFFA8C0FF), Color(0xFF3F2B96)], // Light Blue/Purple
      [Color(0xFFFD746C), Color(0xFFFF9068)], // Orange
      [Color(0xFF42E695), Color(0xFF3BB2B8)], // Teal
    ];
    return colorSchemes[index % colorSchemes.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildCategoriesList(),
          if (widget.selectedCategory != null) ...[
            const SizedBox(height: 24),
            _buildSelectedCategoryDetail(),
          ],
        ],
      ),
    );
  }
}

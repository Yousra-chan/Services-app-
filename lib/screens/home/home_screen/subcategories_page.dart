import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/models/CategoryModel.dart';
import 'package:myapp/screens/home/provider_list_page.dart';
import 'home_constants.dart';

class SubcategoriesPage extends StatefulWidget {
  final CategoryModel selectedCategory;
  final List<CategoryModel> subCategories;
  final VoidCallback onBackPressed;

  const SubcategoriesPage({
    Key? key,
    required this.selectedCategory,
    required this.subCategories,
    required this.onBackPressed,
  }) : super(key: key);

  @override
  State<SubcategoriesPage> createState() => _SubcategoriesPageState();
}

class _SubcategoriesPageState extends State<SubcategoriesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: kDarkTextColor),
          onPressed: widget.onBackPressed,
        ),
        title: Text(
          widget.selectedCategory.name,
          style: const TextStyle(
            color: kDarkTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Exo2',
          ),
        ),
        centerTitle: false,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSubcategoriesGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Service Type',
          style: const TextStyle(
            color: kDarkTextColor,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            fontFamily: 'Exo2',
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select a specific ${widget.selectedCategory.name.toLowerCase()} service',
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

  Widget _buildSubcategoriesGrid(BuildContext context) {
    if (widget.subCategories.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.category_outlined,
                size: 80,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No services available',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later for ${widget.selectedCategory.name} services',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: widget.subCategories.length,
        itemBuilder: (context, index) {
          final subCategory = widget.subCategories[index];
          final colors = _getCategoryColors(index);

          return _buildSubcategoryItem(subCategory, colors, index, context);
        },
      ),
    );
  }

  Widget _buildSubcategoryItem(
    CategoryModel subCategory,
    List<Color> colors,
    int index,
    BuildContext context,
  ) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index % 6) * 50),
      curve: Curves.easeOutBack,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onSubCategorySelected(subCategory, context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors[0].withOpacity(0.1),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: colors[0].withOpacity(0.2), width: 2),
                  ),
                  child: Icon(
                    subCategory.icon,
                    color: colors[0],
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                // Subcategory Name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _truncateSubcategoryName(subCategory.name),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: kDarkTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Exo2',
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onSubCategorySelected(CategoryModel subCategory, BuildContext context) {
    print('🎯 Selected subcategory: ${subCategory.name}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProvidersListPage(
          subCategory: subCategory.name, // Pass name as String
          category: subCategory.id, // Pass ID if needed
        ),
      ),
    );
  }

  String _truncateSubcategoryName(String name) {
    if (name.length <= 14) return name;
    return '${name.substring(0, 12)}...';
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
}

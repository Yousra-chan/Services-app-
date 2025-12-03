import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myapp/models/CategoryModel.dart';
import 'package:myapp/screens/home/home_screen/home_constants.dart';

class SubcategorySection extends StatefulWidget {
  final CategoryModel? selectedCategory;
  final Function(SubcategoryModel) onSubcategorySelected;

  const SubcategorySection({
    super.key,
    required this.selectedCategory,
    required this.onSubcategorySelected,
  });

  @override
  State<SubcategorySection> createState() => _SubcategorySectionState();
}

class _SubcategorySectionState extends State<SubcategorySection> {
  String? _selectedSubcategoryId;

  void _selectSubcategory(SubcategoryModel subcategory) {
    setState(() {
      _selectedSubcategoryId = subcategory.id;
    });
    widget.onSubcategorySelected(subcategory);
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Service Subcategory',
              style: TextStyle(
                color: kDarkTextColor,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                fontFamily: 'Exo2',
                letterSpacing: -0.5,
              ),
            ),
            if (widget.selectedCategory != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kPrimaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kPrimaryBlue.withOpacity(0.2)),
                ),
                child: Text(
                  '${widget.selectedCategory!.subcategories.length}',
                  style: const TextStyle(
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
          widget.selectedCategory != null
              ? 'Choose a specific ${widget.selectedCategory!.name.toLowerCase()} service'
              : 'Select a category first to see subcategories',
          style: const TextStyle(
            color: kMutedTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Exo2',
          ),
        ),
      ],
    );
  }

  Widget _buildSubcategoriesGrid() {
    if (widget.selectedCategory == null) {
      return Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: kLightBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.square_grid_2x2,
                size: 64,
                color: kMutedTextColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'Select a Category',
                style: TextStyle(
                  color: kDarkTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Exo2',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a category above to see available subcategories',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kMutedTextColor,
                  fontSize: 14,
                  fontFamily: 'Exo2',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final subcategories = widget.selectedCategory!.subcategories;

    if (subcategories.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: kLightBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.infinite,
                size: 64,
                color: kMutedTextColor,
              ),
              const SizedBox(height: 16),
              Text(
                'No Subcategories',
                style: TextStyle(
                  color: kDarkTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Exo2',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No subcategories available for ${widget.selectedCategory!.name}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kMutedTextColor,
                  fontSize: 14,
                  fontFamily: 'Exo2',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9,
        ),
        itemCount: subcategories.length,
        itemBuilder: (context, index) {
          final subcategory = subcategories[index];
          final isSelected = _selectedSubcategoryId == subcategory.id;
          final colors = _getSubcategoryColors(index);

          return _buildSubcategoryItem(subcategory, colors, isSelected, index);
        },
      ),
    );
  }

  Widget _buildSubcategoryItem(
    SubcategoryModel subcategory,
    List<Color> colors,
    bool isSelected,
    int index,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectSubcategory(subcategory),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? colors[0] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? colors[0] : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : colors[0].withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withOpacity(0.3)
                          : colors[0].withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    subcategory.icon,
                    color: isSelected ? Colors.white : colors[0],
                    size: 20,
                  ),
                ),
                const SizedBox(height: 12),
                // Subcategory Name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    subcategory.name.length > 12
                        ? '${subcategory.name.substring(0, 10)}...'
                        : subcategory.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : kDarkTextColor,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      fontFamily: 'Exo2',
                    ),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedIndicator() {
    if (widget.selectedCategory == null || _selectedSubcategoryId == null) {
      return const SizedBox.shrink();
    }

    // FIX: Use try-catch to handle the case where subcategory is not found
    try {
      final selectedSubcategory = widget.selectedCategory!.subcategories
          .firstWhere((sub) => sub.id == _selectedSubcategoryId);

      return Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSuccessGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kSuccessGreen.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kSuccessGreen.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.checkmark_alt_circle_fill,
                color: kSuccessGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subcategory Selected',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kSuccessGreen,
                      fontFamily: 'Exo2',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedSubcategory.name,
                    style: const TextStyle(
                      fontSize: 13,
                      color: kDarkTextColor,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Exo2',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      // If subcategory is not found, clear the selection and return empty widget
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedSubcategoryId = null;
          });
        }
      });
      return const SizedBox.shrink();
    }
  }

  List<Color> _getSubcategoryColors(int index) {
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
          _buildSubcategoriesGrid(),
          _buildSelectedIndicator(),
        ],
      ),
    );
  }
}

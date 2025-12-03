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
  final Function(CategoryModel, List<CategoryModel>) onShowSubCategories;
  final bool isLoading;

  const CategoriesSection({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.currentUser,
    required this.onCategorySelected,
    required this.onShowSubCategories,
    this.isLoading = false,
  });

  @override
  State<CategoriesSection> createState() => _CategoriesSectionState();
}

// ============================================================================
// CONSTANTS & CONFIGURATION
// ============================================================================

class _CategoriesPageConfig {
  static const int maxRecentItems = 3;
  static const double categoryCircleSize = 64;
  static const double selectedCircleSize = 70;
  static const double iconSize = 24;
  static const double selectedIconSize = 28;
  static const double recentIconSize = 22;
  static const double recentCircleSize = 50;
  static const int maxNameLength = 12;
  static const int recentMaxNameLength = 10;

  static const List<List<Color>> colorSchemes = [
    [Color(0xFF667EEA), Color(0xFF764BA2)],
    [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    [Color(0xFF43E97B), Color(0xFF38F9D7)],
    [Color(0xFFFA709A), Color(0xFFFEE140)],
    [Color(0xFFF093FB), Color(0xFFF5576C)],
    [Color(0xFFA8C0FF), Color(0xFF3F2B96)],
    [Color(0xFFFD746C), Color(0xFFFF9068)],
    [Color(0xFF42E695), Color(0xFF3BB2B8)],
  ];
}

// ============================================================================
// STATE CLASS
// ============================================================================

class _CategoriesSectionState extends State<CategoriesSection> {
  // --------------------------------------------------------------------------
  // CONTROLLERS & STATE VARIABLES
  // --------------------------------------------------------------------------
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<CategoryModel> _recentCategories = [];
  List<CategoryModel> _filteredCategories = [];
  String _searchQuery = '';

  // --------------------------------------------------------------------------
  // LIFECYCLE METHODS
  // --------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  @override
  void didUpdateWidget(CategoriesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categories != oldWidget.categories) {
      _filterCategories(_searchQuery);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // INITIALIZATION METHODS
  // --------------------------------------------------------------------------
  void _initializeState() {
    _filteredCategories = widget.categories;
    _loadRecentCategories();
  }

  void _loadRecentCategories() async {
    // TODO: Load from SharedPreferences in real app
    if (mounted) {
      setState(() {
        _recentCategories = widget.categories
            .take(_CategoriesPageConfig.maxRecentItems)
            .toList();
      });
    }
  }

  // --------------------------------------------------------------------------
  // SEARCH & FILTER METHODS
  // --------------------------------------------------------------------------
  void _filterCategories(String query) {
    if (!mounted) return;

    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCategories = widget.categories;
      } else {
        _filteredCategories = widget.categories
            .where((category) =>
                category.name.toLowerCase().contains(query.toLowerCase()) ||
                category.description
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // --------------------------------------------------------------------------
  // RECENT ITEMS MANAGEMENT
  // --------------------------------------------------------------------------
  void _addToRecent(CategoryModel category) {
    if (!mounted) return;

    setState(() {
      // Remove if already exists
      _recentCategories.removeWhere((c) => c.id == category.id);

      // Add to beginning
      _recentCategories.insert(0, category);

      // Keep only recent items up to max limit
      if (_recentCategories.length > _CategoriesPageConfig.maxRecentItems) {
        _recentCategories.removeLast();
      }
    });
    // TODO: Save to local storage
  }

  // --------------------------------------------------------------------------
  // NAVIGATION METHODS
  // --------------------------------------------------------------------------
  void _selectNextCategory() {
    if (widget.selectedCategory == null) return;

    final currentIndex = _filteredCategories
        .indexWhere((cat) => cat.id == widget.selectedCategory!.id);

    if (currentIndex < _filteredCategories.length - 1) {
      widget.onCategorySelected(_filteredCategories[currentIndex + 1]);
      _addToRecent(_filteredCategories[currentIndex + 1]);
    }
  }

  void _selectPreviousCategory() {
    if (widget.selectedCategory == null) return;

    final currentIndex = _filteredCategories
        .indexWhere((cat) => cat.id == widget.selectedCategory!.id);

    if (currentIndex > 0) {
      widget.onCategorySelected(_filteredCategories[currentIndex - 1]);
      _addToRecent(_filteredCategories[currentIndex - 1]);
    }
  }

  // --------------------------------------------------------------------------
  // SUBCATEGORY GENERATION
  // --------------------------------------------------------------------------
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
            subcategories: [],
          ),
          CategoryModel(
            id: '${mainCategory.id}_2',
            name: 'Office Cleaning',
            description: 'Office and workspace cleaning',
            icon: CupertinoIcons.briefcase_fill,
            iconCode: 'office_cleaning',
            subcategories: [],
          ),
          CategoryModel(
            id: '${mainCategory.id}_3',
            name: 'Deep Cleaning',
            description: 'Thorough deep cleaning service',
            icon: CupertinoIcons.sparkles,
            iconCode: 'deep_cleaning',
            subcategories: [],
          ),
          CategoryModel(
            id: '${mainCategory.id}_4',
            name: 'Carpet Cleaning',
            description: 'Professional carpet and rug cleaning',
            icon: CupertinoIcons.rectangle_fill,
            iconCode: 'carpet_cleaning',
            subcategories: [],
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
            subcategories: [],
          ),
          CategoryModel(
            id: '${mainCategory.id}_2',
            name: 'Leak Fixing',
            description: 'Water leak detection and repair',
            icon: CupertinoIcons.drop_fill,
            iconCode: 'leak_fixing',
            subcategories: [],
          ),
          CategoryModel(
            id: '${mainCategory.id}_3',
            name: 'Fixture Installation',
            description: 'Sink, toilet, and faucet installation',
            icon: CupertinoIcons.settings,
            iconCode: 'fixture_installation',
            subcategories: [],
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
            subcategories: [],
          ),
          CategoryModel(
            id: '${mainCategory.id}_2',
            name: 'Outlet Repair',
            description: 'Socket and outlet fixing',
            icon: CupertinoIcons.power,
            iconCode: 'outlet_repair',
            subcategories: [],
          ),
          CategoryModel(
            id: '${mainCategory.id}_3',
            name: 'Lighting Installation',
            description: 'Light fixture installation',
            icon: CupertinoIcons.lightbulb_fill,
            iconCode: 'lighting_installation',
            subcategories: [],
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
            subcategories: [],
          ),
          CategoryModel(
            id: '${mainCategory.id}_2',
            name: 'Advanced ${mainCategory.name}',
            description:
                'Advanced ${mainCategory.name.toLowerCase()} solutions',
            icon: mainCategory.icon,
            iconCode: 'advanced_${mainCategory.name.toLowerCase()}',
            subcategories: [],
          ),
          CategoryModel(
            id: '${mainCategory.id}_3',
            name: 'Emergency ${mainCategory.name}',
            description:
                '24/7 emergency ${mainCategory.name.toLowerCase()} service',
            icon: CupertinoIcons.exclamationmark_triangle_fill,
            iconCode: 'emergency_${mainCategory.name.toLowerCase()}',
            subcategories: [],
          ),
        ];
    }
  }

  // --------------------------------------------------------------------------
  // BOTTOM SHEET METHODS
  // --------------------------------------------------------------------------
  void _showCategoryDetails(CategoryModel category) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildDetailsBottomSheet(category),
    );
  }

  Widget _buildDetailsBottomSheet(CategoryModel category) {
    final subCategories = _generateSubCategoriesForCategory(category);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDetailsIcon(category),
          const SizedBox(height: 16),
          _buildDetailsTitle(category),
          const SizedBox(height: 8),
          _buildDetailsDescription(category),
          const SizedBox(height: 24),
          _buildPopularServicesSection(subCategories),
          const SizedBox(height: 24),
          _buildActionButtons(category),
        ],
      ),
    );
  }

  Widget _buildDetailsIcon(CategoryModel category) {
    final colors = _getCategoryColors(
      _filteredCategories.indexOf(category),
    );

    return Container(
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
        category.icon,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _buildDetailsTitle(CategoryModel category) {
    return Text(
      category.name,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: kDarkTextColor,
        fontFamily: 'Exo2',
      ),
    );
  }

  Widget _buildDetailsDescription(CategoryModel category) {
    return Text(
      category.description,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: kMutedTextColor,
        fontFamily: 'Exo2',
      ),
    );
  }

  Widget _buildPopularServicesSection(List<CategoryModel> subCategories) {
    return Column(
      children: [
        Text(
          'Popular Services',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: kDarkTextColor,
            fontFamily: 'Exo2',
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: subCategories
              .take(3)
              .map((sub) => Chip(
                    label: Text(sub.name),
                    backgroundColor: kLightBackgroundColor,
                    labelStyle: TextStyle(
                      color: kDarkTextColor,
                      fontFamily: 'Exo2',
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons(CategoryModel category) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: kMutedTextColor),
            ),
            child: Text(
              'Close',
              style: TextStyle(
                color: kMutedTextColor,
                fontFamily: 'Exo2',
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onCategorySelected(category);
              _addToRecent(category);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Browse Services',
              style: TextStyle(
                fontFamily: 'Exo2',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // HELPER METHODS
  // --------------------------------------------------------------------------
  String _truncateCategoryName(String name,
      {int maxLength = _CategoriesPageConfig.maxNameLength}) {
    if (name.length <= maxLength) return name;
    return '${name.substring(0, maxLength - 3)}...';
  }

  List<Color> _getCategoryColors(int index) {
    return _CategoriesPageConfig
        .colorSchemes[index % _CategoriesPageConfig.colorSchemes.length];
  }

  // --------------------------------------------------------------------------
  // WIDGET BUILDING METHODS - HEADER
  // --------------------------------------------------------------------------
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
                '${_filteredCategories.length}',
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

  // --------------------------------------------------------------------------
  // WIDGET BUILDING METHODS - SEARCH FIELD
  // --------------------------------------------------------------------------
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search categories...',
          prefixIcon: Icon(Icons.search, color: kMutedTextColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: kMutedTextColor),
                  onPressed: () {
                    _searchController.clear();
                    _filterCategories('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: kPrimaryBlue, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: _filterCategories,
      ),
    );
  }

  // --------------------------------------------------------------------------
  // WIDGET BUILDING METHODS - LOADING STATE
  // --------------------------------------------------------------------------
  Widget _buildLoadingState() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(right: 16),
            width: 90,
            child: Column(
              children: [
                // Loading circle
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 8),
                // Loading text
                Container(
                  width: 60,
                  height: 16,
                  color: Colors.grey[200],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --------------------------------------------------------------------------
  // WIDGET BUILDING METHODS - CATEGORIES LIST
  // --------------------------------------------------------------------------
  Widget _buildCategoriesList() {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (_filteredCategories.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: kMutedTextColor,
            ),
            const SizedBox(height: 12),
            Text(
              'No categories found',
              style: TextStyle(
                color: kMutedTextColor,
                fontFamily: 'Exo2',
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _filteredCategories.length,
        itemBuilder: (context, index) {
          final category = _filteredCategories[index];
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
    return Semantics(
      button: true,
      label: '${category.name} category',
      child: ExcludeSemantics(
        child: Column(
          children: [
            // Category Circle
            GestureDetector(
              onTap: () {
                widget.onCategorySelected(category);
                _addToRecent(category);
              },
              onLongPress: () {
                _showCategoryDetails(category);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isSelected
                    ? _CategoriesPageConfig.selectedCircleSize
                    : _CategoriesPageConfig.categoryCircleSize,
                height: isSelected
                    ? _CategoriesPageConfig.selectedCircleSize
                    : _CategoriesPageConfig.categoryCircleSize,
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
                  size: isSelected
                      ? _CategoriesPageConfig.selectedIconSize
                      : _CategoriesPageConfig.iconSize,
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
      ),
    );
  }

  // --------------------------------------------------------------------------
  // WIDGET BUILDING METHODS - RECENT CATEGORIES
  // --------------------------------------------------------------------------
  Widget _buildRecentCategories() {
    if (_recentCategories.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recently Viewed',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kDarkTextColor,
            fontFamily: 'Exo2',
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recentCategories.length,
            itemBuilder: (context, index) {
              final category = _recentCategories[index];
              final colors = _getCategoryColors(index);

              return Container(
                margin: EdgeInsets.only(right: 12),
                width: 70,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        widget.onCategorySelected(category);
                      },
                      child: Container(
                        width: _CategoriesPageConfig.recentCircleSize,
                        height: _CategoriesPageConfig.recentCircleSize,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: colors,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          category.icon,
                          color: Colors.white,
                          size: _CategoriesPageConfig.recentIconSize,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _truncateCategoryName(category.name,
                          maxLength: _CategoriesPageConfig.recentMaxNameLength),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: kDarkTextColor,
                        fontFamily: 'Exo2',
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // WIDGET BUILDING METHODS - SELECTED CATEGORY DETAIL
  // --------------------------------------------------------------------------
  Widget _buildSelectedCategoryDetail() {
    if (widget.selectedCategory == null) return const SizedBox();

    final selectedIndex = _filteredCategories
        .indexWhere((cat) => cat.id == widget.selectedCategory!.id);

    if (selectedIndex == -1) return const SizedBox();

    final colors = _getCategoryColors(selectedIndex);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          // Swiped right - previous category
          _selectPreviousCategory();
        } else if (details.primaryVelocity! < 0) {
          // Swiped left - next category
          _selectNextCategory();
        }
      },
      child: Material(
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
      ),
    );
  }

  // --------------------------------------------------------------------------
  // MAIN BUILD METHOD
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildSearchField(),
          const SizedBox(height: 16),
          if (_recentCategories.isNotEmpty) ...[
            _buildRecentCategories(),
            const SizedBox(height: 20),
          ],
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

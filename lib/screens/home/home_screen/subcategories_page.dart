import 'package:flutter/material.dart';
import 'package:myapp/models/CategoryModel.dart';
import 'package:myapp/screens/home/providers_list/provider_list_page.dart';
import 'home_constants.dart';

class SubcategoriesPage extends StatefulWidget {
  final CategoryModel selectedCategory;
  final List<CategoryModel> subCategories;
  final VoidCallback onBackPressed;

  const SubcategoriesPage({
    super.key,
    required this.selectedCategory,
    required this.subCategories,
    required this.onBackPressed,
  });

  @override
  State<SubcategoriesPage> createState() => _SubcategoriesPageState();
}

// ============================================================================
// CONSTANTS & CONFIGURATION
// ============================================================================

class _SubcategoriesPageConfig {
  static const double gridItemHeight = 120;
  static const double gridItemWidth = 100;
  static const int gridCrossAxisCount = 3;
  static const double gridSpacing = 16;
  static const int maxRecentItems = 2;
  static const int maxNameLength = 14;
  static const int truncatedNameLength = 12;
  static const double iconSize = 24;
  static const double recentIconSize = 22;
  static const double detailsIconSize = 28;

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

class _SubcategoriesPageState extends State<SubcategoriesPage> {
  // --------------------------------------------------------------------------
  // CONTROLLERS & STATE VARIABLES
  // --------------------------------------------------------------------------
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<CategoryModel> _filteredSubCategories = [];
  String _searchQuery = '';
  List<CategoryModel> _recentSubCategories = [];

  // --------------------------------------------------------------------------
  // LIFECYCLE METHODS
  // --------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // INITIALIZATION METHODS
  // --------------------------------------------------------------------------
  void _initializeState() {
    _filteredSubCategories = widget.subCategories;
    _loadRecentSubCategories();
  }

  void _loadRecentSubCategories() async {
    // TODO: Load from SharedPreferences in real app
    if (mounted) {
      setState(() {
        _recentSubCategories = widget.subCategories
            .take(_SubcategoriesPageConfig.maxRecentItems)
            .toList();
      });
    }
  }

  // --------------------------------------------------------------------------
  // SEARCH & FILTER METHODS
  // --------------------------------------------------------------------------
  void _filterSubCategories(String query) {
    if (!mounted) return;

    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSubCategories = widget.subCategories;
      } else {
        _filteredSubCategories = widget.subCategories
            .where((subCategory) =>
                subCategory.name.toLowerCase().contains(query.toLowerCase()) ||
                subCategory.description
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // --------------------------------------------------------------------------
  // RECENT ITEMS MANAGEMENT
  // --------------------------------------------------------------------------
  void _addToRecent(CategoryModel subCategory) {
    if (!mounted) return;

    setState(() {
      // Remove if already exists
      _recentSubCategories.removeWhere((c) => c.id == subCategory.id);

      // Add to beginning
      _recentSubCategories.insert(0, subCategory);

      // Keep only recent items up to max limit
      if (_recentSubCategories.length >
          _SubcategoriesPageConfig.maxRecentItems) {
        _recentSubCategories.removeLast();
      }
    });
    // TODO: Save to local storage
  }

  // --------------------------------------------------------------------------
  // NAVIGATION & INTERACTION METHODS
  // --------------------------------------------------------------------------
  void _onSubCategorySelected(CategoryModel subCategory, BuildContext context) {
    print('🎯 Selected subcategory: ${subCategory.name}');
    _addToRecent(subCategory);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProvidersListPage(
          category: widget.selectedCategory.name,
          subCategory: subCategory.name,
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // HELPER METHODS
  // --------------------------------------------------------------------------
  String _truncateSubcategoryName(String name) {
    if (name.length <= _SubcategoriesPageConfig.maxNameLength) return name;
    return '${name.substring(0, _SubcategoriesPageConfig.truncatedNameLength)}...';
  }

  List<Color> _getCategoryColors(int index) {
    return _SubcategoriesPageConfig
        .colorSchemes[index % _SubcategoriesPageConfig.colorSchemes.length];
  }

  // --------------------------------------------------------------------------
  // BOTTOM SHEET METHODS
  // --------------------------------------------------------------------------
  void _showSubCategoryDetails(CategoryModel subCategory) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildDetailsBottomSheet(subCategory),
    );
  }

  Widget _buildDetailsBottomSheet(CategoryModel subCategory) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDetailsIcon(subCategory),
          const SizedBox(height: 16),
          _buildDetailsTitle(subCategory),
          const SizedBox(height: 8),
          _buildDetailsDescription(subCategory),
          const SizedBox(height: 24),
          _buildServiceDetailsSection(subCategory),
          const SizedBox(height: 24),
          _buildActionButtons(subCategory, context),
        ],
      ),
    );
  }

  Widget _buildDetailsIcon(CategoryModel subCategory) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getCategoryColors(widget.subCategories.indexOf(subCategory)),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        subCategory.icon,
        color: Colors.white,
        size: _SubcategoriesPageConfig.detailsIconSize,
      ),
    );
  }

  Widget _buildDetailsTitle(CategoryModel subCategory) {
    return Text(
      subCategory.name,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: kDarkTextColor,
        fontFamily: 'Exo2',
      ),
    );
  }

  Widget _buildDetailsDescription(CategoryModel subCategory) {
    return Text(
      subCategory.description,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: kMutedTextColor,
        fontFamily: 'Exo2',
      ),
    );
  }

  Widget _buildServiceDetailsSection(CategoryModel subCategory) {
    return Column(
      children: [
        Text(
          'Service Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: kDarkTextColor,
            fontFamily: 'Exo2',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kLightBackgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Main Category: ${widget.selectedCategory.name}',
                style: TextStyle(
                  color: kDarkTextColor,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Exo2',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Service Type: ${subCategory.name}',
                style: TextStyle(
                  color: kMutedTextColor,
                  fontFamily: 'Exo2',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(CategoryModel subCategory, BuildContext context) {
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
              _onSubCategorySelected(subCategory, context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Browse Providers',
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
  // WIDGET BUILDING METHODS - HEADER
  // --------------------------------------------------------------------------
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

  // --------------------------------------------------------------------------
  // WIDGET BUILDING METHODS - SEARCH FIELD
  // --------------------------------------------------------------------------
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search services...',
          prefixIcon: Icon(Icons.search, color: kMutedTextColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: kMutedTextColor),
                  onPressed: () {
                    _searchController.clear();
                    _filterSubCategories('');
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
        onChanged: _filterSubCategories,
      ),
    );
  }

  // --------------------------------------------------------------------------
  // WIDGET BUILDING METHODS - RECENT SUBCATEGORIES
  // --------------------------------------------------------------------------

  Widget _buildRecentItem(CategoryModel subCategory, int index) {
    final colors = _getCategoryColors(index);

    return Container(
      margin: EdgeInsets.only(right: 12),
      width: 60,
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _onSubCategorySelected(subCategory, context),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                subCategory.icon,
                color: Colors.white,
                size: _SubcategoriesPageConfig.recentIconSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // WIDGET BUILDING METHODS - EMPTY STATE
  // --------------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: kMutedTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results for "$_searchQuery"'
                  : 'No services available',
              style: TextStyle(
                color: kDarkTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Exo2',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Check back later for ${widget.selectedCategory.name} services',
              style: TextStyle(
                color: kMutedTextColor,
                fontSize: 14,
                fontFamily: 'Exo2',
              ),
            ),
            if (_searchQuery.isNotEmpty) _buildClearSearchButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildClearSearchButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ElevatedButton(
        onPressed: () {
          _searchController.clear();
          _filterSubCategories('');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Clear Search',
          style: TextStyle(
            fontFamily: 'Exo2',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // WIDGET BUILDING METHODS - GRID VIEW
  // --------------------------------------------------------------------------
  Widget _buildSubcategoriesGrid() {
    if (_filteredSubCategories.isEmpty) {
      return _buildEmptyState();
    }

    return Expanded(
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _SubcategoriesPageConfig.gridCrossAxisCount,
          crossAxisSpacing: _SubcategoriesPageConfig.gridSpacing,
          mainAxisSpacing: _SubcategoriesPageConfig.gridSpacing,
          childAspectRatio: 1.0,
        ),
        itemCount: _filteredSubCategories.length,
        itemBuilder: (context, index) {
          final subCategory = _filteredSubCategories[index];
          final colors = _getCategoryColors(index);

          return _buildSubcategoryItem(subCategory, colors, index);
        },
      ),
    );
  }

  Widget _buildSubcategoryItem(
    CategoryModel subCategory,
    List<Color> colors,
    int index,
  ) {
    return Semantics(
      button: true,
      label: '${subCategory.name} service',
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index % 6) * 50),
          curve: Curves.easeOutBack,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onSubCategorySelected(subCategory, context),
              onLongPress: () => _showSubCategoryDetails(subCategory),
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
                        border: Border.all(
                            color: colors[0].withOpacity(0.2), width: 2),
                      ),
                      child: Icon(
                        subCategory.icon,
                        color: colors[0],
                        size: _SubcategoriesPageConfig.iconSize,
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
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // MAIN BUILD METHOD
  // --------------------------------------------------------------------------
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.selectedCategory.name,
              style: const TextStyle(
                color: kDarkTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Exo2',
              ),
            ),
            Text(
              '${_filteredSubCategories.length} services',
              style: TextStyle(
                fontSize: 12,
                color: kMutedTextColor,
                fontFamily: 'Exo2',
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSearchField(),
            const SizedBox(height: 16),
            _buildSubcategoriesGrid(),
          ],
        ),
      ),
    );
  }
}

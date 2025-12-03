import 'package:flutter/material.dart';
import 'package:myapp/screens/auth/constants.dart';
import 'package:myapp/screens/home/providers_list/provider_card.dart';
import 'package:myapp/screens/home/providers_list/provider_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/ProviderModel.dart';
import 'package:myapp/ViewModel/search_view_model.dart';
import 'package:myapp/models/CategoryModel.dart';

class ProvidersListPage extends StatefulWidget {
  final String? category;
  final String? subCategory;
  final String? wilaya;
  final String? commune;
  final double? minRating;
  final bool? subscriptionActive;
  final CategoryModel? selectedCategory;
  final CategoryModel? selectedSubCategory;

  const ProvidersListPage({
    super.key,
    this.category,
    this.subCategory,
    this.wilaya,
    this.commune,
    this.minRating,
    this.subscriptionActive,
    this.selectedCategory,
    this.selectedSubCategory,
  });

  @override
  State<ProvidersListPage> createState() => _ProvidersListPageState();
}

class _ProvidersListPageState extends State<ProvidersListPage> {
  final TextEditingController _searchController = TextEditingController();
  late SearchViewModel _searchViewModel;
  Map<String, dynamic> _currentFilters = {};
  String _selectedSortOption = 'rating_desc';

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _searchViewModel = Provider.of<SearchViewModel>(context, listen: false);
    _loadProviders();
  }

  void _initializeFilters() {
    _currentFilters = {
      if (widget.category != null) 'category': widget.category,
      if (widget.subCategory != null) 'subcategory': widget.subCategory,
      if (widget.wilaya != null) 'wilaya': widget.wilaya,
      if (widget.commune != null) 'commune': widget.commune,
      if (widget.minRating != null) 'minRating': widget.minRating,
      if (widget.subscriptionActive != null)
        'subscriptionActive': widget.subscriptionActive,
    };

    if (widget.selectedCategory != null) {
      _currentFilters['category'] = widget.selectedCategory!.name;
    }
    if (widget.selectedSubCategory != null) {
      _currentFilters['subcategory'] = widget.selectedSubCategory!.name;
    }
  }

  Future<void> _loadProviders() async {
    await _searchViewModel.searchWithFilters(_currentFilters);
  }

  Future<void> _refreshProviders() async {
    await _searchViewModel.searchWithFilters(_currentFilters);
  }

  List<ProviderModel> _sortProviders(List<ProviderModel> providers) {
    switch (_selectedSortOption) {
      case 'rating_desc':
        return providers..sort((a, b) => b.rating.compareTo(a.rating));
      case 'rating_asc':
        return providers..sort((a, b) => a.rating.compareTo(b.rating));
      case 'name_asc':
        return providers..sort((a, b) => a.name.compareTo(b.name));
      case 'name_desc':
        return providers..sort((a, b) => b.name.compareTo(a.name));
      default:
        return providers;
    }
  }

  String _getPageTitle() {
    if (widget.selectedSubCategory != null) {
      return widget.selectedSubCategory!.name;
    } else if (widget.selectedCategory != null) {
      return widget.selectedCategory!.name;
    } else if (widget.subCategory != null) {
      return widget.subCategory!;
    } else if (widget.category != null) {
      return widget.category!;
    }
    return 'All Providers';
  }

  String _getPageSubtitle() {
    final providerCount = _searchViewModel.providerResults.length;
    if (providerCount == 0) return 'No providers found';
    if (providerCount == 1) return '1 professional found';
    return '$providerCount professionals found';
  }

  Future<void> _onMessageTap(ProviderModel provider) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderProfileScreen(provider: provider),
      ),
    );
  }

  Future<void> _onCallTap(ProviderModel provider) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderProfileScreen(provider: provider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar with Back Button
            _buildCustomAppBar(),

            // Search and Sort Section
            _buildSearchSortSection(),

            // Results List
            Expanded(
              child: Consumer<SearchViewModel>(
                builder: (context, searchViewModel, child) {
                  final sortedProviders = _sortProviders(
                      List.from(searchViewModel.providerResults));
                  return _buildResults(searchViewModel, sortedProviders);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: kDarkTextColor,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),

          // Title and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPageTitle(),
                  style: TextStyle(
                    color: kDarkTextColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Exo2',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Consumer<SearchViewModel>(
                  builder: (context, searchViewModel, child) {
                    return Text(
                      _getPageSubtitle(),
                      style: TextStyle(
                        fontSize: 13,
                        color: kMutedTextColor,
                        fontFamily: 'Exo2',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSortSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Search Field with Improved Design
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(width: 16),
                Icon(Icons.search_rounded, color: kPrimaryBlue, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (query) {
                      if (query.trim().isEmpty) {
                        _loadProviders();
                      } else {
                        _searchViewModel.searchProvidersOnly(query);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by name or profession...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontFamily: 'Exo2',
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded,
                                  size: 20, color: Colors.grey.shade500),
                              onPressed: () {
                                _searchController.clear();
                                _loadProviders();
                              },
                            )
                          : null,
                    ),
                    style: TextStyle(
                      fontFamily: 'Exo2',
                      fontSize: 15,
                      color: kDarkTextColor,
                    ),
                    cursorColor: kPrimaryBlue,
                  ),
                ),
                SizedBox(width: 16),
              ],
            ),
          ),
          SizedBox(height: 16),

          // Sort Dropdown with Better Design
          _buildSortDropdown(),
        ],
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Show sort options modal
            _showSortOptionsModal();
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.sort_rounded, size: 20, color: kPrimaryBlue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getSortLabel(_selectedSortOption),
                    style: TextStyle(
                      fontSize: 15,
                      color: kDarkTextColor,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Exo2',
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down_rounded,
                    size: 24, color: kPrimaryBlue),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSortLabel(String value) {
    switch (value) {
      case 'rating_desc':
        return 'Highest Rating';
      case 'rating_asc':
        return 'Lowest Rating';
      case 'name_asc':
        return 'Name A-Z';
      case 'name_desc':
        return 'Name Z-A';
      default:
        return 'Sort by';
    }
  }

  void _showSortOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sort by',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kDarkTextColor,
                  fontFamily: 'Exo2',
                ),
              ),
              SizedBox(height: 20),
              ...['rating_desc', 'rating_asc', 'name_asc', 'name_desc']
                  .map((option) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedSortOption = option;
                      });
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade100,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedSortOption == option
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: _selectedSortOption == option
                                ? kPrimaryBlue
                                : Colors.grey.shade400,
                            size: 22,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _getSortLabel(option),
                              style: TextStyle(
                                fontSize: 16,
                                color: kDarkTextColor,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Exo2',
                              ),
                            ),
                          ),
                          if (_selectedSortOption == option)
                            Icon(
                              Icons.check_rounded,
                              color: kPrimaryBlue,
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResults(
      SearchViewModel searchViewModel, List<ProviderModel> sortedProviders) {
    if (searchViewModel.isLoading) {
      return _buildLoadingState();
    }

    if (searchViewModel.error != null && sortedProviders.isEmpty) {
      return _buildErrorState(searchViewModel);
    }

    if (sortedProviders.isEmpty) {
      return _buildEmptyState(searchViewModel);
    }

    return RefreshIndicator(
      onRefresh: _refreshProviders,
      color: kPrimaryBlue,
      backgroundColor: Colors.white,
      displacement: 40,
      child: ListView.separated(
        padding: EdgeInsets.only(bottom: 20, top: 8),
        itemCount: sortedProviders.length,
        separatorBuilder: (context, index) => SizedBox(height: 8),
        itemBuilder: (context, index) {
          return ProviderCard(
            provider: sortedProviders[index],
            onMessageTap: _onMessageTap,
            onCallTap: _onCallTap,
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kPrimaryBlue.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(kPrimaryBlue),
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Loading Professionals',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kDarkTextColor,
              fontFamily: 'Exo2',
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please wait a moment...',
            style: TextStyle(
              color: kMutedTextColor,
              fontFamily: 'Exo2',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(SearchViewModel searchViewModel) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Colors.red,
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Unable to Load',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: kDarkTextColor,
                fontFamily: 'Exo2',
              ),
            ),
            SizedBox(height: 12),
            Text(
              searchViewModel.error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kMutedTextColor,
                fontFamily: 'Exo2',
                fontSize: 15,
                height: 1.4,
              ),
            ),
            SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [kPrimaryBlue, Color(0xFF4A6FDC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _refreshProviders,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'Try Again',
                          style: TextStyle(
                            fontFamily: 'Exo2',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(SearchViewModel searchViewModel) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.search_off_rounded,
                  size: 60,
                  color: kMutedTextColor,
                ),
              ),
            ),
            SizedBox(height: 32),
            Text(
              'No Professionals Found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: kDarkTextColor,
                fontFamily: 'Exo2',
              ),
            ),
            SizedBox(height: 12),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No results for "${_searchController.text}"'
                  : 'Try searching for professionals in your area',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kMutedTextColor,
                fontSize: 16,
                fontFamily: 'Exo2',
                height: 1.5,
              ),
            ),
            SizedBox(height: 32),
            if (_searchController.text.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _searchController.clear();
                      _loadProviders();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.clear_all_rounded, color: kPrimaryBlue),
                          SizedBox(width: 12),
                          Text(
                            'Clear Search',
                            style: TextStyle(
                              fontFamily: 'Exo2',
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: kPrimaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
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

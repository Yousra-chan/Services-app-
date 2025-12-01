import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/services/wilaya_service.dart';
import 'package:myapp/services/categories_service.dart';
import 'package:myapp/models/CategoryModel.dart';
import 'search_constants.dart';

class SearchFilterDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onFiltersApplied;
  final String? initialWilaya;
  final String? initialCategory;
  final String? initialSubcategory;

  const SearchFilterDialog({
    Key? key,
    required this.onFiltersApplied,
    this.initialWilaya,
    this.initialCategory,
    this.initialSubcategory,
  }) : super(key: key);

  @override
  State<SearchFilterDialog> createState() => _SearchFilterDialogState();
}

class _SearchFilterDialogState extends State<SearchFilterDialog> {
  String? _selectedWilaya;
  String? _selectedCommune;
  String? _selectedCategory;
  String? _selectedSubcategory;
  double _selectedDistance = 20.0;
  bool _useDistanceFilter = false;

  List<String> _wilayas = WilayaService.getAllWilayaNames();
  List<String> _communes = [];
  List<CategoryModel> _allCategories = [];
  List<String> _availableSubcategories = [];
  bool _isLoading = false;

  final CategoriesService _categoriesService = CategoriesService();

  @override
  void initState() {
    super.initState();
    _selectedWilaya = widget.initialWilaya;
    _selectedCategory = widget.initialCategory;
    _selectedSubcategory = widget.initialSubcategory;

    if (_selectedWilaya != null) {
      _communes = WilayaService.getCommunesForWilaya(_selectedWilaya!);
    }

    _loadCategoriesData();
  }

  Future<void> _loadCategoriesData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final categories = await _categoriesService.getAllCategories();

      setState(() {
        _allCategories = categories;
        _isLoading = false;
      });

      print("✅ Loaded ${categories.length} categories");

      // Update subcategories if category is already selected
      if (_selectedCategory != null) {
        _updateAvailableSubcategories();
      }
    } catch (e) {
      print("❌ Error loading categories: $e");
      setState(() {
        _isLoading = false;
        // Load default categories as fallback
        _allCategories = CategoryModel.defaultCategories;
      });
    }
  }

  void _updateAvailableSubcategories() {
    if (_selectedCategory == null) {
      setState(() {
        _availableSubcategories = [];
        _selectedSubcategory = null;
      });
      return;
    }

    final category = _categoriesService.getCategoryByName(_selectedCategory!);

    if (category != null) {
      setState(() {
        _availableSubcategories =
            category.subcategories.map((sub) => sub.name).toList();

        // Reset subcategory if not in new list
        if (_selectedSubcategory != null &&
            !_availableSubcategories.contains(_selectedSubcategory)) {
          _selectedSubcategory = null;
        }
      });
    } else {
      setState(() {
        _availableSubcategories = [];
        _selectedSubcategory = null;
      });
    }
  }

  // Helper method to get icon for category name
  IconData _getIconForCategoryName(String categoryName) {
    final lowerName = categoryName.toLowerCase();

    if (lowerName.contains('clean')) return CupertinoIcons.house_fill;
    if (lowerName.contains('plumb')) return CupertinoIcons.wrench_fill;
    if (lowerName.contains('electric')) return CupertinoIcons.bolt_fill;
    if (lowerName.contains('carpent')) return CupertinoIcons.hammer_fill;
    if (lowerName.contains('paint')) return CupertinoIcons.paintbrush_fill;
    if (lowerName.contains('garden')) return CupertinoIcons.clear_fill;
    if (lowerName.contains('move')) return CupertinoIcons.car_fill;
    if (lowerName.contains('repair')) return CupertinoIcons.wrench_fill;
    if (lowerName.contains('install')) return CupertinoIcons.settings;
    if (lowerName.contains('tutor')) return CupertinoIcons.book_fill;
    if (lowerName.contains('teach')) return CupertinoIcons.person_fill;
    if (lowerName.contains('doctor')) return CupertinoIcons.heart_fill;
    if (lowerName.contains('medical')) return CupertinoIcons.heart_fill;
    if (lowerName.contains('hair')) return CupertinoIcons.scissors;
    if (lowerName.contains('beauty')) return CupertinoIcons.sparkles;

    return CupertinoIcons.circle_fill;
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Filtrer la recherche',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Exo2',
            color: kDarkTextColor,
          ),
        ),
        IconButton(
          icon: Icon(CupertinoIcons.xmark, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildWilayaFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wilaya',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Exo2',
            color: kDarkTextColor,
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: kLightBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kMutedTextColor.withOpacity(0.3)),
          ),
          child: DropdownButton<String>(
            value: _selectedWilaya,
            isExpanded: true,
            underline: SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: kPrimaryBlue),
            hint: Text(
              'Sélectionnez une wilaya',
              style: TextStyle(color: kMutedTextColor),
            ),
            items: _wilayas.map((wilaya) {
              return DropdownMenuItem<String>(
                value: wilaya,
                child: Text(
                  wilaya,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Exo2',
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedWilaya = value;
                _communes = WilayaService.getCommunesForWilaya(value!);
                _selectedCommune = null;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommuneFilter() {
    if (_selectedWilaya == null) return SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 15),
        Text(
          'Commune',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Exo2',
            color: kDarkTextColor,
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: kLightBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kMutedTextColor.withOpacity(0.3)),
          ),
          child: _communes.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Aucune commune disponible',
                    style: TextStyle(color: kMutedTextColor),
                  ),
                )
              : DropdownButton<String>(
                  value: _selectedCommune,
                  isExpanded: true,
                  underline: SizedBox(),
                  icon: Icon(Icons.arrow_drop_down, color: kPrimaryBlue),
                  hint: Text(
                    'Sélectionnez une commune',
                    style: TextStyle(color: kMutedTextColor),
                  ),
                  items: _communes.map((commune) {
                    return DropdownMenuItem<String>(
                      value: commune,
                      child: Text(
                        commune,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Exo2',
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCommune = value;
                    });
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    final availableCategories = _allCategories.map((cat) => cat.name).toList()
      ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 15),
        Text(
          'Catégorie de service',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Exo2',
            color: kDarkTextColor,
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: kLightBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kMutedTextColor.withOpacity(0.3)),
          ),
          child: _isLoading
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(kPrimaryBlue),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Chargement des catégories...',
                        style: TextStyle(
                          color: kMutedTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : availableCategories.isEmpty
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Aucune catégorie disponible',
                        style: TextStyle(color: kMutedTextColor),
                      ),
                    )
                  : DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      underline: SizedBox(),
                      icon: Icon(Icons.arrow_drop_down, color: kPrimaryBlue),
                      hint: Text(
                        'Sélectionnez une catégorie',
                        style: TextStyle(color: kMutedTextColor),
                      ),
                      items: availableCategories.map((category) {
                        final catModel = _allCategories.firstWhere(
                          (cat) => cat.name == category,
                          orElse: () => _allCategories.first,
                        );

                        return DropdownMenuItem<String>(
                          value: category,
                          child: Row(
                            children: [
                              Icon(catModel.icon,
                                  color: kPrimaryBlue, size: 18),
                              SizedBox(width: 10),
                              Text(
                                category,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Exo2',
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                          _selectedSubcategory = null;
                        });
                        _updateAvailableSubcategories();
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSubcategoryFilter() {
    if (_selectedCategory == null || _availableSubcategories.isEmpty) {
      return SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 15),
        Text(
          'Type de service',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Exo2',
            color: kDarkTextColor,
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: kLightBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kMutedTextColor.withOpacity(0.3)),
          ),
          child: DropdownButton<String>(
            value: _selectedSubcategory,
            isExpanded: true,
            underline: SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: kPrimaryBlue),
            hint: Text(
              'Sélectionnez un type',
              style: TextStyle(color: kMutedTextColor),
            ),
            items: _availableSubcategories.map((subcategory) {
              // Try to find the actual subcategory model
              SubcategoryModel? subModel;
              for (var category in _allCategories) {
                if (category.name == _selectedCategory) {
                  subModel = category.subcategories.firstWhere(
                    (sub) => sub.name == subcategory,
                    orElse: () => SubcategoryModel(
                      id: subcategory,
                      name: subcategory,
                      description: '',
                      icon: _getIconForCategoryName(_selectedCategory!),
                      iconCode: '',
                    ),
                  );
                  break;
                }
              }

              if (subModel == null) {
                subModel = SubcategoryModel(
                  id: subcategory,
                  name: subcategory,
                  description: '',
                  icon: _getIconForCategoryName(_selectedCategory!),
                  iconCode: '',
                );
              }

              return DropdownMenuItem<String>(
                value: subcategory,
                child: Row(
                  children: [
                    Icon(subModel.icon, color: kMutedTextColor, size: 16),
                    SizedBox(width: 10),
                    Text(
                      subcategory,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Exo2',
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSubcategory = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 15),
        Row(
          children: [
            Checkbox(
              value: _useDistanceFilter,
              onChanged: (value) {
                setState(() {
                  _useDistanceFilter = value ?? false;
                });
              },
              activeColor: kPrimaryBlue,
            ),
            Text(
              'Filtrer par distance',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Exo2',
                color: kDarkTextColor,
              ),
            ),
          ],
        ),
        if (_useDistanceFilter) ...[
          SizedBox(height: 8),
          Text(
            'Distance maximale: ${_selectedDistance.toInt()} km',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontFamily: 'Exo2',
              color: kDarkTextColor,
            ),
          ),
          SizedBox(height: 8),
          Slider(
            value: _selectedDistance,
            min: 1,
            max: 50,
            divisions: 49,
            onChanged: (value) {
              setState(() {
                _selectedDistance = value;
              });
            },
            activeColor: kPrimaryBlue,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _selectedWilaya = null;
                _selectedCommune = null;
                _selectedCategory = null;
                _selectedSubcategory = null;
                _selectedDistance = 20.0;
                _useDistanceFilter = false;
                _communes = [];
                _availableSubcategories = [];
              });
            },
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Réinitialiser',
              style: TextStyle(
                color: kDarkTextColor,
                fontFamily: 'Exo2',
              ),
            ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              final filters = {
                'wilaya': _selectedWilaya,
                'commune': _selectedCommune,
                'category': _selectedCategory,
                'subcategory': _selectedSubcategory,
                'maxDistance': _useDistanceFilter ? _selectedDistance : null,
                'useDistanceFilter': _useDistanceFilter,
              };

              print("✅ Applying filters: $filters");
              widget.onFiltersApplied(filters);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryBlue,
              padding: EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Appliquer',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Exo2',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesGrid() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: kPrimaryBlue),
      );
    }

    if (_allCategories.isEmpty) {
      return Center(
        child: Text(
          'Aucune catégorie disponible',
          style: TextStyle(color: kMutedTextColor),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: _allCategories.length,
      itemBuilder: (context, index) {
        final category = _allCategories[index];
        final isSelected = _selectedCategory == category.name;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = isSelected ? null : category.name;
              _selectedSubcategory = null;
            });
            _updateAvailableSubcategories();
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? kSelectedFilterColor : kCardBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? kPrimaryBlue
                    : kMutedTextColor.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category.icon,
                  color: isSelected ? kPrimaryBlue : kMutedTextColor,
                  size: 30,
                ),
                SizedBox(height: 8),
                Text(
                  category.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Exo2',
                    color: isSelected ? kPrimaryBlue : kDarkTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 500,
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 20),

            // Categories Grid
            Text(
              'Catégories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Exo2',
                color: kDarkTextColor,
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: _buildCategoriesGrid(),
            ),
            SizedBox(height: 20),

            // Advanced Filters Section
            ExpansionTile(
              title: Text(
                'Filtres avancés',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Exo2',
                  color: kDarkTextColor,
                ),
              ),
              children: [
                SizedBox(height: 10),
                _buildSubcategoryFilter(),
                SizedBox(height: 15),
                _buildWilayaFilter(),
                _buildCommuneFilter(),
                SizedBox(height: 15),
                _buildDistanceFilter(),
                SizedBox(height: 20),
              ],
            ),

            SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }
}

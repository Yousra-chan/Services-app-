import 'package:flutter/material.dart';
import 'package:myapp/screens/service/category_section.dart';
import 'package:myapp/screens/service/input_field.dart';
import 'package:myapp/screens/service/location_section.dart';
import 'package:myapp/screens/service/price_section.dart';
import 'package:myapp/screens/service/sub_category_section.dart';
import 'package:myapp/screens/service/tags_section.dart';
import 'package:provider/provider.dart';
import 'package:myapp/ViewModel/auth_view_model.dart';
import 'package:myapp/ViewModel/service_view_model.dart';
import 'package:myapp/models/CategoryModel.dart';

class CreateServiceForm extends StatefulWidget {
  final bool isLoading;

  const CreateServiceForm({
    super.key,
    required this.isLoading,
  });

  @override
  State<CreateServiceForm> createState() => _CreateServiceFormState();
}

class _CreateServiceFormState extends State<CreateServiceForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String _selectedPriceUnit = 'per service';
  final List<String> _selectedTags = [];
  CategoryModel? _selectedCategory;
  SubcategoryModel? _selectedSubcategory;

  // Location state
  String _locationAddress = '';
  double? _latitude;
  double? _longitude;
  bool _hasLocation = false;

  // Color scheme
  final Color _primaryColor = Color(0xFF6366F1);
  final Color _secondaryColor = Color(0xFF10B981);
  final Color _accentColor = Color(0xFFF59E0B);
  final Color _textPrimary = Color(0xFF1E293B);
  final Color _textSecondary = Color(0xFF64748B);

  final List<String> _priceUnits = [
    'per hour',
    'per service',
    'per day',
    'per item',
    'per square meter',
    'per session'
  ];

  void _submitService() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate category and subcategory selection
    if (_selectedCategory == null) {
      _showError('Please select a service category');
      return;
    }

    if (_selectedSubcategory == null) {
      _showError('Please select a service subcategory');
      return;
    }

    // Validate location
    if (!_hasLocation) {
      _showError('Please enable and detect your location');
      return;
    }

    // Validate price
    final priceText = _priceController.text.trim();
    if (priceText.isEmpty) {
      _showError('Please enter a price');
      return;
    }

    double price;
    try {
      price = double.parse(priceText);
      if (price <= 0) {
        _showError('Price must be greater than 0');
        return;
      }
    } catch (e) {
      _showError('Please enter a valid price (e.g., 1000 or 1000.50)');
      return;
    }

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final serviceViewModel =
        Provider.of<ServiceViewModel>(context, listen: false);

    if (authViewModel.currentUser == null) {
      _showError('Please log in to create a service');
      return;
    }

    try {
      // Note: No markUserAsProvider method exists, so you need to handle this differently
      // You might need to create this method in ServiceViewModel or AuthViewModel
      // For now, let's assume the user is already a provider or will be marked elsewhere

      final success = await serviceViewModel.createServiceFromData(
        providerId: authViewModel.currentUser!.uid,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!.name,
        subcategory: _selectedSubcategory!.name,
        price: price,
        priceUnit: _selectedPriceUnit,
        location: _locationAddress,
        latitude: _latitude,
        longitude: _longitude,
        tags: _selectedTags,
        images: const [], // Add if you have image upload
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Service created successfully!'),
              ],
            ),
            backgroundColor: _secondaryColor,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        _showError(serviceViewModel.error ?? 'Failed to create service');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error creating service: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Color(0xFFEF4444),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? subtitle, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: _primaryColor),
              ),
              SizedBox(width: 8),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
              height: 1.4,
            ),
          ),
        ],
        SizedBox(height: 16),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Service Title
            InputField(
              label: 'Service Title',
              hint: 'e.g., Professional House Cleaning',
              controller: _titleController,
              icon: Icons.work_rounded,
              maxLength: 100,
              validator: (value) =>
                  value!.isEmpty ? 'Please enter service title' : null,
            ),
            SizedBox(height: 28),

            // Description
            InputField(
              label: 'Service Description',
              hint: 'Describe your service in detail...',
              controller: _descriptionController,
              icon: Icons.description_rounded,
              maxLines: 4,
              maxLength: 500,
              validator: (value) =>
                  value!.isEmpty ? 'Please enter service description' : null,
            ),
            SizedBox(height: 28),

            // Category
            CategorySection(
              onCategorySelected: (category) {
                setState(() {
                  _selectedCategory = category;
                  _selectedSubcategory =
                      null; // Reset subcategory when category changes
                });
              },
            ),
            SizedBox(height: 28),

            // Subcategory
            SubcategorySection(
              selectedCategory: _selectedCategory,
              onSubcategorySelected: (subcategory) {
                setState(() {
                  _selectedSubcategory = subcategory;
                });
              },
            ),
            SizedBox(height: 28),

            // Price and Price Unit
            PriceSection(
              priceController: _priceController,
              selectedPriceUnit: _selectedPriceUnit,
              priceUnits: _priceUnits,
              onPriceUnitChanged: (value) {
                setState(() {
                  _selectedPriceUnit = value!;
                });
              },
            ),
            SizedBox(height: 28),

            // Location
            LocationSection(
              onLocationUpdated: (address, lat, lng) {
                setState(() {
                  _locationAddress = address;
                  _latitude = lat;
                  _longitude = lng;
                  _hasLocation = true;
                });
              },
            ),
            SizedBox(height: 28),

            // Tags
            TagsSection(
              selectedTags: _selectedTags,
              onTagsChanged: (tags) {
                setState(() {
                  _selectedTags.clear();
                  _selectedTags.addAll(tags);
                });
              },
            ),
            SizedBox(height: 36),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        widget.isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(color: _primaryColor, width: 2),
                      backgroundColor: Colors.transparent,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back_rounded,
                            size: 20, color: _primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.isLoading ? null : _submitService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: widget.isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_rounded, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Create Service',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Helper Text
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accentColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_rounded, color: _accentColor, size: 18),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your service will be reviewed within 24 hours before going live to ensure quality standards.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

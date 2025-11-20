import 'package:flutter/material.dart';
import 'package:myapp/screens/auth/login/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:myapp/ViewModel/auth_view_model.dart';
import 'package:myapp/ViewModel/service_view_model.dart';
import 'package:myapp/screens/auth/constants.dart';

class CreateServiceScreen extends StatefulWidget {
  const CreateServiceScreen({super.key});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _selectedCategory = 'Cleaning';
  String _selectedPriceUnit = 'per hour';
  final List<String> _selectedTags = [];

  final List<String> _categories = [
    'Cleaning',
    'Plumbing',
    'Electrical',
    'Carpentry',
    'Painting',
    'Gardening',
    'Moving',
    'Repair',
    'Installation',
    'Other'
  ];

  final List<String> _priceUnits = [
    'per hour',
    'per service',
    'per day',
    'per item'
  ];

  final List<String> _availableTags = [
    'Quick Service',
    '24/7 Available',
    'Emergency',
    'Weekend Available',
    'Free Estimate',
    'Insured',
    'Certified',
    'Eco-Friendly'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _submitService() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final serviceViewModel =
        Provider.of<ServiceViewModel>(context, listen: false);

    if (authViewModel.currentUser == null) return;

    try {
      final success = await serviceViewModel.createService(
        providerId: authViewModel.currentUser!.uid,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        price: double.parse(_priceController.text.trim()),
        priceUnit: _selectedPriceUnit,
        location: _locationController.text.trim(),
        tags: _selectedTags,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(serviceViewModel.error ?? 'Failed to create service'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: buildAestheticInputDecoration('Category'),
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value!;
        });
      },
      validator: (value) => value == null ? 'Please select a category' : null,
    );
  }

  Widget _buildPriceUnitDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedPriceUnit,
      decoration: buildAestheticInputDecoration('Price Unit'),
      items: _priceUnits.map((unit) {
        return DropdownMenuItem(
          value: unit,
          child: Text(unit),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedPriceUnit = value!;
        });
      },
      validator: (value) => value == null ? 'Please select price unit' : null,
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Tags',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kDarkTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
              selectedColor: kPrimaryBlue.withOpacity(0.2),
              checkmarkColor: kPrimaryBlue,
              labelStyle: TextStyle(
                color: isSelected ? kPrimaryBlue : kDarkTextColor,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final serviceViewModel = Provider.of<ServiceViewModel>(context);

    return Scaffold(
      backgroundColor: kLightBackgroundColor,
      appBar: AppBar(
        title: const Text('Create Service'),
        backgroundColor: Colors.white,
        foregroundColor: kDarkTextColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Service Title
                TextFormField(
                  controller: _titleController,
                  decoration: buildAestheticInputDecoration('Service Title'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter service title' : null,
                  maxLength: 100,
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration:
                      buildAestheticInputDecoration('Service Description'),
                  validator: (value) => value!.isEmpty
                      ? 'Please enter service description'
                      : null,
                  maxLines: 4,
                  maxLength: 500,
                ),
                const SizedBox(height: 16),

                // Category
                _buildCategoryDropdown(),
                const SizedBox(height: 16),

                // Price and Price Unit
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _priceController,
                        decoration: buildAestheticInputDecoration('Price'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty) return 'Please enter price';
                          if (double.tryParse(value) == null) {
                            return 'Please enter valid price';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: _buildPriceUnitDropdown(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Location
                TextFormField(
                  controller: _locationController,
                  decoration: buildAestheticInputDecoration('Service Location'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter service location' : null,
                ),
                const SizedBox(height: 16),

                // Tags
                _buildTagsSection(),
                const SizedBox(height: 24),

                // Create Button
                ElevatedButton(
                  onPressed: serviceViewModel.isLoading ? null : _submitService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: serviceViewModel.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create Service',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

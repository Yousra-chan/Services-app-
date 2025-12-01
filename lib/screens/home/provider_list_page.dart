import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/ProviderModel.dart';
import 'package:myapp/models/CategoryModel.dart';
import 'package:myapp/models/UserModel.dart';

class ProvidersListPage extends StatefulWidget {
  final String? category;
  final String? subCategory;
  final String? selectedWilaya;
  final String? selectedCommune;

  const ProvidersListPage({
    Key? key,
    required this.category,
    required this.subCategory,
    this.selectedWilaya,
    this.selectedCommune,
  }) : super(key: key);

  @override
  State<ProvidersListPage> createState() => _ProvidersListPageState();
}

class _ProvidersListPageState extends State<ProvidersListPage> {
  List<ProviderModel> _providers = [];
  List<ProviderModel> _filteredProviders = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadProviders();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterProviders();
    });
  }

  void _filterProviders() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredProviders = List.from(_providers);
      });
      return;
    }

    setState(() {
      _filteredProviders = _providers.where((provider) {
        return provider.name.toLowerCase().contains(_searchQuery) ||
            provider.profession.toLowerCase().contains(_searchQuery) ||
            provider.address.toLowerCase().contains(_searchQuery);
      }).toList();
    });
  }

  // Helper method to extract wilaya from address
  String? _extractWilayaFromAddress(String address) {
    if (address.isEmpty) return null;

    final wilayas = [
      'Alger',
      'Boumerdès',
      'Blida',
      'Oran',
      'Tizi Ouzou',
      'Constantine'
    ];

    for (var wilaya in wilayas) {
      if (address.toLowerCase().contains(wilaya.toLowerCase())) {
        return wilaya;
      }
    }

    return null;
  }

  // Helper method to extract commune from address
  String? _extractCommuneFromAddress(String address) {
    if (address.isEmpty) return null;

    final parts = address.split(',');
    if (parts.isNotEmpty) {
      return parts.first.trim();
    }

    return null;
  }

  Future<void> _loadProviders() async {
    try {
      print(
          '🔍 Loading providers for category: ${widget.category}, subcategory: ${widget.subCategory}');

      // Create provider services map
      Map<String, List<Map<String, dynamic>>> providerServicesMap = {};

      // Step 1: Get services with the specified category/subcategory
      Query servicesQuery =
          _firestore.collection('services').where('isActive', isEqualTo: true);

      // Add category filter if provided
      if (widget.category != null && widget.category!.isNotEmpty) {
        servicesQuery =
            servicesQuery.where('category', isEqualTo: widget.category);
      }

      // Add subcategory filter if provided
      if (widget.subCategory != null && widget.subCategory!.isNotEmpty) {
        servicesQuery =
            servicesQuery.where('subcategory', isEqualTo: widget.subCategory);
      }

      final servicesSnapshot = await servicesQuery.get();
      print('📦 Found ${servicesSnapshot.docs.length} matching services');

      // Group services by provider
      for (var serviceDoc in servicesSnapshot.docs) {
        final serviceData =
            serviceDoc.data() as Map<String, dynamic>?; // Add type cast

        if (serviceData != null) {
          // Add null check
          final providerId = serviceData['providerId'] as String?;

          if (providerId != null && providerId.isNotEmpty) {
            if (!providerServicesMap.containsKey(providerId)) {
              providerServicesMap[providerId] = [];
            }
            providerServicesMap[providerId]!.add({
              ...serviceData, // This is now safe because we checked serviceData != null
              'id': serviceDoc.id,
            });
          }
        }
      }

      if (providerServicesMap.isEmpty) {
        print('⚠️ No services found for the selected filters');
        if (mounted) {
          setState(() {
            _providers = [];
            _filteredProviders = [];
            _isLoading = false;
          });
        }
        return;
      }

      // Step 2: Get providers who have matching services
      final providersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'provider')
          .where('subscriptionActive', isEqualTo: true)
          .where(FieldPath.documentId,
              whereIn: providerServicesMap.keys.toList())
          .get();

      print(
          '👥 Found ${providersSnapshot.docs.length} providers with matching services');

      List<ProviderModel> providers = [];

      // Step 3: Convert providers
      for (var providerDoc in providersSnapshot.docs) {
        try {
          final providerId = providerDoc.id;
          final providerData =
              providerDoc.data() as Map<String, dynamic>?; // Add type cast

          if (providerData == null) {
            // Add null check
            print('⚠️ Provider data is null for doc: $providerId');
            continue;
          }

          final user = UserModel.fromMap(providerData, providerId);
          final provider = ProviderModel.fromUser(user);

          // Apply wilaya filter if provided
          if (widget.selectedWilaya != null &&
              widget.selectedWilaya!.isNotEmpty) {
            final providerWilaya = _extractWilayaFromAddress(provider.address);
            if (providerWilaya == null ||
                !providerWilaya
                    .toLowerCase()
                    .contains(widget.selectedWilaya!.toLowerCase())) {
              print('❌ Skipping ${provider.name} - wilaya doesn\'t match');
              continue;
            }
          }

          // Apply commune filter if provided
          if (widget.selectedCommune != null &&
              widget.selectedCommune!.isNotEmpty) {
            final providerCommune =
                _extractCommuneFromAddress(provider.address);
            if (providerCommune == null ||
                !providerCommune
                    .toLowerCase()
                    .contains(widget.selectedCommune!.toLowerCase())) {
              print('❌ Skipping ${provider.name} - commune doesn\'t match');
              continue;
            }
          }

          providers.add(provider);
          print('✅ Added provider: ${provider.name}');
        } catch (e) {
          print('❌ Error creating provider ${providerDoc.id}: $e');
        }
      }

      if (mounted) {
        setState(() {
          _providers = providers;
          _filteredProviders = providers;
          _isLoading = false;
        });
      }

      print('🎉 Loaded ${providers.length} providers after filtering');
    } catch (e) {
      print('❌ Error loading providers: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.subCategory ?? widget.category ?? 'Providers',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            '${_filteredProviders.length} professionals',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search professionals...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Colors.blue),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard(ProviderModel provider) {
    final wilaya = _extractWilayaFromAddress(provider.address) ?? 'Unknown';
    final commune = _extractCommuneFromAddress(provider.address) ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to provider details
          print('Tapped on ${provider.name}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue[50],
                ),
                child:
                    provider.photoUrl != null && provider.photoUrl!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              provider.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  color: Colors.blue[300],
                                  size: 30,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.person,
                            color: Colors.blue[300],
                            size: 30,
                          ),
              ),
              const SizedBox(width: 16),

              // Provider Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.profession.isNotEmpty
                          ? provider.profession
                          : 'Service Provider',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '$commune, $wilaya',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          provider.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (provider.subscriptionActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactButtons(ProviderModel provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Open WhatsApp
                print('Message ${provider.name}');
              },
              icon: const Icon(Icons.chat, size: 16),
              label: const Text('Message'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Make phone call
                print('Call ${provider.name} at ${provider.phone}');
              },
              icon: const Icon(Icons.phone, size: 16),
              label: const Text('Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading professionals...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No professionals found'
                : 'No results found',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Check back later for available professionals'
                : 'Try a different search term',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadProviders,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Filter indicators
          if (widget.selectedWilaya != null || widget.selectedCommune != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[50],
              child: Row(
                children: [
                  if (widget.selectedWilaya != null)
                    Chip(
                      label: Text(widget.selectedWilaya!),
                      backgroundColor: Colors.blue[50],
                      deleteIconColor: Colors.blue,
                      onDeleted: () {
                        // TODO: Remove wilaya filter
                      },
                    ),
                  if (widget.selectedCommune != null) const SizedBox(width: 8),
                  if (widget.selectedCommune != null)
                    Chip(
                      label: Text(widget.selectedCommune!),
                      backgroundColor: Colors.green[50],
                      deleteIconColor: Colors.green,
                      onDeleted: () {
                        // TODO: Remove commune filter
                      },
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // TODO: Clear all filters
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _filteredProviders.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadProviders,
                        child: ListView.builder(
                          itemCount: _filteredProviders.length,
                          itemBuilder: (context, index) {
                            final provider = _filteredProviders[index];
                            return Column(
                              children: [
                                _buildProviderCard(provider),
                                _buildContactButtons(provider),
                                if (index < _filteredProviders.length - 1)
                                  const Divider(height: 20),
                              ],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
}

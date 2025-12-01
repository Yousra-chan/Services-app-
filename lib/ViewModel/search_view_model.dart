import 'dart:math';

import 'package:flutter/material.dart';
import '../services/search_service.dart';
import '../models/ProviderModel.dart';
import '../models/ServicesModel.dart';

class SearchViewModel extends ChangeNotifier {
  final SearchService _searchService = SearchService();

  List<ProviderModel> _providerResults = [];
  List<Service> _serviceResults = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ProviderModel> get providerResults => _providerResults;
  List<Service> get serviceResults => _serviceResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Clears all current search results and error state.
  void clearResults() {
    _providerResults = [];
    _serviceResults = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Executes a search across both providers and services
  Future<void> executeSearch(String query) async {
    if (query.trim().isEmpty) {
      clearResults();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Execute both searches
      final providerResults =
          await _searchService.searchProvidersByProfessionOrName(query);
      final serviceResults = await _searchService.searchServices(query);

      _providerResults = providerResults;
      _serviceResults = serviceResults;
    } catch (e) {
      _error = 'Échec de la recherche: $e';
      _providerResults = [];
      _serviceResults = [];
      print('❌ Search error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Searches only for providers
  Future<void> searchProvidersOnly(String query) async {
    if (query.trim().isEmpty) {
      _providerResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _providerResults =
          await _searchService.searchProvidersByProfessionOrName(query);
      _serviceResults = [];
    } catch (e) {
      _error = 'Échec de la recherche de prestataires: $e';
      _providerResults = [];
      print('❌ Provider search error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Searches only for services
  Future<void> searchServicesOnly(String query) async {
    if (query.trim().isEmpty) {
      _serviceResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _serviceResults = await _searchService.searchServices(query);
      _providerResults = [];
    } catch (e) {
      _error = 'Échec de la recherche de services: $e';
      _serviceResults = [];
      print('❌ Service search error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search services by category
  Future<void> searchServicesByCategory(String category) async {
    if (category.trim().isEmpty) {
      _serviceResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _serviceResults = await _searchService.searchServices(category);
      _providerResults = [];
    } catch (e) {
      _error = 'Échec de la recherche par catégorie: $e';
      _serviceResults = [];
      print('❌ Category search error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get featured services for homepage (fallback to highly rated services)
  Future<void> loadFeaturedServices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get all active services and sort by rating
      _serviceResults = await _searchService.searchServices('');

      // Filter and sort
      _serviceResults = _serviceResults
          .where((service) => service.rating >= 4.0) // Only highly rated
          .toList()
        ..sort((a, b) => b.rating.compareTo(a.rating))
        ..take(10).toList();

      _providerResults = [];
    } catch (e) {
      _error = 'Échec du chargement des services en vedette: $e';
      _serviceResults = [];
      print('❌ Featured services error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Format distance for display
  String formatDistance(double? meters) {
    if (meters == null) return 'Distance non disponible';

    try {
      // Manual formatting
      if (meters < 1000) {
        return '${meters.toStringAsFixed(0)} m';
      } else {
        return '${(meters / 1000).toStringAsFixed(1)} km';
      }
    } catch (e) {
      print('❌ Format distance error: $e');
      return 'Distance non disponible';
    }
  }

  /// SEARCH WITH FILTERS - CRITICAL METHOD
  Future<void> searchWithFilters(Map<String, dynamic> filters) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔍 ViewModel: Searching with filters: $filters');

      // Ensure filters use correct field names
      final Map<String, dynamic> convertedFilters = Map.from(filters);

      // Handle backward compatibility for filter names
      if (convertedFilters.containsKey('service') &&
          !convertedFilters.containsKey('category')) {
        convertedFilters['category'] = convertedFilters['service'];
      }

      if (convertedFilters.containsKey('subService') &&
          !convertedFilters.containsKey('subcategory')) {
        convertedFilters['subcategory'] = convertedFilters['subService'];
      }

      print('🔍 ViewModel: Using converted filters: $convertedFilters');

      _providerResults =
          await _searchService.searchProvidersWithFilters(convertedFilters);
      _serviceResults = [];

      print('✅ ViewModel: Found ${_providerResults.length} providers');
    } catch (e) {
      _error = 'Échec de la recherche avec filtres: $e';
      _providerResults = [];
      _serviceResults = [];
      print('❌❌❌ Filter search error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Check if there are any search results
  bool get hasResults {
    return _providerResults.isNotEmpty || _serviceResults.isNotEmpty;
  }

  /// Get total number of results
  int get totalResults {
    return _providerResults.length + _serviceResults.length;
  }

  /// Get search summary text
  String get searchSummary {
    if (_isLoading) return 'Recherche en cours...';
    if (_error != null) return _error!;
    if (!hasResults) return 'Aucun résultat trouvé';

    if (_providerResults.isNotEmpty && _serviceResults.isNotEmpty) {
      return '${_providerResults.length} prestataires et ${_serviceResults.length} services trouvés';
    } else if (_providerResults.isNotEmpty) {
      return '${_providerResults.length} prestataire${_providerResults.length > 1 ? 's' : ''} trouvé${_providerResults.length > 1 ? 's' : ''}';
    } else {
      return '${_serviceResults.length} service${_serviceResults.length > 1 ? 's' : ''} trouvé${_serviceResults.length > 1 ? 's' : ''}';
    }
  }

  /// Get providers by category
  Future<void> searchProvidersByCategory(String category) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _providerResults = await _searchService.searchProvidersWithFilters({
        'category': category,
      });
      _serviceResults = [];
    } catch (e) {
      _error = 'Échec de la recherche de prestataires par catégorie: $e';
      _providerResults = [];
      print('❌ Providers by category error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get available categories for filters
  Future<Map<String, List<String>>> getAvailableCategories() async {
    try {
      return await _searchService.getAvailableCategories();
    } catch (e) {
      print('❌ Get categories error: $e');
      return {};
    }
  }

  /// Get available wilayas for filters
  Future<List<String>> getAvailableWilayas() async {
    try {
      return await _searchService.getAvailableWilayas();
    } catch (e) {
      print('❌ Get wilayas error: $e');
      return [];
    }
  }
}

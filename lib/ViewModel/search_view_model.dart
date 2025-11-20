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
      // Execute both searches separately to avoid type casting issues
      final providerResults =
          await _searchService.searchProvidersByProfessionOrName(query);
      final serviceResults = await _searchService.searchServices(query);

      _providerResults = providerResults;
      _serviceResults = serviceResults;
    } catch (e) {
      _error = 'Failed to execute search: $e';
      _providerResults = [];
      _serviceResults = [];
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
      _error = 'Failed to search providers: $e';
      _providerResults = [];
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
      _error = 'Failed to search services: $e';
      _serviceResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search services by category
  Future<void> searchServicesByCategory(String category) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _serviceResults = await _searchService.searchServicesByCategory(category);
      _providerResults = [];
    } catch (e) {
      _error = 'Failed to search services by category: $e';
      _serviceResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get nearby providers
  Future<void> loadNearbyProviders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _providerResults = await _searchService.searchProvidersNearby();
      _serviceResults = [];
    } catch (e) {
      _error = 'Failed to load nearby providers: $e';
      _providerResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get featured services for homepage
  Future<void> loadFeaturedServices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _serviceResults = await _searchService.getFeaturedServices();
      _providerResults = [];
    } catch (e) {
      _error = 'Failed to load featured services: $e';
      _serviceResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get distance to provider
  Future<double?> getDistanceToProvider(ProviderModel provider) async {
    return await _searchService.getDistanceToProvider(provider);
  }

  /// Get distance to service
  Future<double?> getDistanceToService(Service service) async {
    return await _searchService.getDistanceToService(service);
  }

  /// Format distance for display
  String formatDistance(double meters) {
    return _searchService.formatDistance(meters);
  }

  /// Get services by provider ID
  Future<List<Service>> getServicesByProvider(String providerId) async {
    try {
      return await _searchService.getServicesByProvider(providerId);
    } catch (e) {
      _error = 'Failed to get provider services: $e';
      return [];
    }
  }
}

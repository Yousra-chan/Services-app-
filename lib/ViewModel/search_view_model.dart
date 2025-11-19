import 'package:flutter/material.dart';
import '../services/search_service.dart';
import '../models/ProviderModel.dart';
import '../models/ServicesModel.dart';

class SearchViewModel extends ChangeNotifier {
  final SearchService _searchService = SearchService();

  List<ProviderModel> providerResults = [];
  List<ServiceModel> serviceResults = [];
  bool isLoading = false;
  String? errorMessage;

  /// Clears all current search results and error state.
  void clearResults() {
    providerResults = [];
    serviceResults = [];
    errorMessage = null;
    isLoading = false;
    notifyListeners();
  }

  /// Executes a search across both providers (by profession/name) and services (by name).
  Future<void> executeSearch(String query) async {
    if (query.trim().isEmpty) {
      clearResults();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Execute both searches concurrently for speed
      final results = await Future.wait([
        // FIX: Use the corrected method name
        _searchService.searchProvidersByProfessionOrName(query),
      ]);

      providerResults = results[0];
      serviceResults = results[1] as List<ServiceModel>;
    } catch (e) {
      errorMessage = 'Failed to execute search: $e';
      providerResults = [];
      serviceResults = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Searches only for providers based on profession or name.
  Future<void> searchProvidersOnly(String query) async {
    if (query.trim().isEmpty) {
      providerResults = [];
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      providerResults = (await _searchService.searchProvidersByProfessionOrName(
        query,
      ))
          .cast<ProviderModel>();
      serviceResults =
          []; // Clear service results when using a dedicated search
    } catch (e) {
      errorMessage = 'Failed to search providers: $e';
      providerResults = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

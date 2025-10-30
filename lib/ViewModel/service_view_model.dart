import 'package:flutter/material.dart';
import '../services/services_service.dart';
import '../models/servicesmodel.dart';

class ServiceViewModel extends ChangeNotifier {
  final ServicesService _serviceService = ServicesService();

  List<ServiceModel> services = [];
  bool isLoading = false;
  String? errorMessage;

  /// General function to fetch and populate the primary 'services' list
  Future<void> fetchServices() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      services = await _serviceService.getAllServices();
    } catch (e) {
      errorMessage = 'Failed to load all services: $e';
      services = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- Focused Read Operations (for non-primary views) ---

  /// Fetches services filtered by category (does NOT update the primary 'services' list)
  Future<List<ServiceModel>> getServicesByCategory(String category) async {
    try {
      return await _serviceService.getServicesByCategory(category);
    } catch (e) {
      print('Error fetching services by category: $e');
      // Throw the exception or return an empty list based on expected UI behavior
      return [];
    }
  }

  /// Fetches services offered by a specific provider (useful for provider profile)
  Future<List<ServiceModel>> getServicesByProvider(String providerId) async {
    try {
      return await _serviceService.getServicesByProvider(providerId);
    } catch (e) {
      print('Error fetching services by provider: $e');
      return [];
    }
  }

  // --- CRUD Operations ---

  /// Creates a new service and updates the local list
  Future<void> createService(ServiceModel service) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _serviceService.createService(service);
      // Immediately add the service to the local list (it now has an ID)
      services.add(service);
    } catch (e) {
      errorMessage = 'Failed to create service: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Updates an existing service and updates the local list
  Future<void> updateService(ServiceModel service) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _serviceService.updateService(service);

      // Find and replace the old service object in the local list
      final index = services.indexWhere((s) => s.id == service.id);
      if (index != -1) {
        services[index] = service;
      }
    } catch (e) {
      errorMessage = 'Failed to update service: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes a service and removes it from the local list
  Future<void> deleteService(String serviceId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _serviceService.deleteService(serviceId);

      // Remove the service from the local list
      services.removeWhere((s) => s.id == serviceId);
    } catch (e) {
      errorMessage = 'Failed to delete service: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

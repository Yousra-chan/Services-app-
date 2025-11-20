import 'package:flutter/foundation.dart';
import 'package:myapp/Services/services_service.dart';
import 'package:myapp/models/ServicesModel.dart';

class ServiceViewModel with ChangeNotifier {
  final ServiceService _serviceService = ServiceService();

  List<Service> _services = [];
  bool _isLoading = false;
  String? _error;

  List<Service> get services => _services;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get services by provider
  List<Service> getServicesByProvider(String providerId) {
    return _services
        .where((service) => service.providerId == providerId)
        .toList();
  }

  // Create new service
  Future<bool> createService({
    required String providerId,
    required String title,
    required String description,
    required String category,
    required double price,
    required String priceUnit,
    required String location,
    double? latitude,
    double? longitude,
    List<String> images = const [],
    List<String> tags = const [],
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final service = await _serviceService.createService(
        providerId: providerId,
        title: title,
        description: description,
        category: category,
        price: price,
        priceUnit: priceUnit,
        location: location,
        latitude: latitude,
        longitude: longitude,
        images: images,
        tags: tags,
      );

      if (service != null) {
        _services.add(service);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to create service: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load services for provider
  Future<void> loadProviderServices(String providerId) async {
    try {
      _setLoading(true);
      _setError(null);

      final services = await _serviceService.getServicesByProvider(providerId);
      _services = services;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load services: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update service
  Future<bool> updateService(Service updatedService) async {
    try {
      _setLoading(true);
      _setError(null);

      final success = await _serviceService.updateService(updatedService);
      if (success) {
        final index = _services.indexWhere((s) => s.id == updatedService.id);
        if (index != -1) {
          _services[index] = updatedService;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to update service: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete service
  Future<bool> deleteService(String serviceId) async {
    try {
      _setLoading(true);
      _setError(null);

      final success = await _serviceService.deleteService(serviceId);
      if (success) {
        _services.removeWhere((s) => s.id == serviceId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to delete service: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

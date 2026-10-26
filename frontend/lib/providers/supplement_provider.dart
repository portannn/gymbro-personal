import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/admin_service.dart';

class SupplementProvider with ChangeNotifier {
  final AdminService _adminService = AdminService();
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _adminService.getSupplements();
    if (result['success']) {
      final List<dynamic> data = result['data'];
      _products = data.map((e) => Product.fromJson(e)).toList();
    } else {
      _error = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addProduct(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    final result = await _adminService.createSupplement(data);
    _isLoading = false;
    if (result['success']) {
      await fetchProducts();
      return true;
    }
    _error = result['message'];
    notifyListeners();
    return false;
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    final result = await _adminService.updateSupplement(id, data);
    _isLoading = false;
    if (result['success']) {
      await fetchProducts();
      return true;
    }
    _error = result['message'];
    notifyListeners();
    return false;
  }

  Future<bool> deleteProduct(int id) async {
    _isLoading = true;
    notifyListeners();

    final result = await _adminService.deleteSupplement(id);
    _isLoading = false;
    if (result['success']) {
      _products.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    }
    _error = result['message'];
    notifyListeners();
    return false;
  }
}

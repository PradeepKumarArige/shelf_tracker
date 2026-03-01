import 'package:flutter/material.dart';
import '../models/deal_model.dart';
import '../repositories/deal_repository.dart';
import '../repositories/user_repository.dart';

class DealService extends ChangeNotifier {
  final DealRepository _dealRepo = DealRepository();
  final UserRepository _userRepo = UserRepository();
  
  List<DealModel> _deals = [];
  List<DealModel> _featuredDeals = [];
  List<DealModel> _savedDeals = [];
  Set<String> _savedDealIds = {};
  bool _isLoading = false;
  String? _error;
  String? _userId;
  String? _selectedCategory;

  List<DealModel> get deals => _deals;
  List<DealModel> get featuredDeals => _featuredDeals;
  List<DealModel> get savedDeals => _savedDeals;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedCategory => _selectedCategory;

  List<DealModel> get filteredDeals {
    if (_selectedCategory == null || _selectedCategory == 'All') {
      return _deals;
    }
    return _deals.where((deal) => deal.category == _selectedCategory).toList();
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _userRepo.createOrGetDefaultUser();
      _userId = user.id;
      
      await _dealRepo.seedSampleDeals();
      await loadDeals();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDeals() async {
    try {
      _deals = await _dealRepo.getAllDeals();
      _featuredDeals = await _dealRepo.getFeaturedDeals();
      
      if (_userId != null) {
        _savedDeals = await _dealRepo.getSavedDeals(_userId!);
        _savedDealIds = _savedDeals.map((d) => d.id).toSet();
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    notifyListeners();
  }

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  bool isDealSaved(String dealId) {
    return _savedDealIds.contains(dealId);
  }

  Future<String?> toggleSaveDeal(String dealId) async {
    if (_userId == null) return 'User not initialized';

    try {
      if (_savedDealIds.contains(dealId)) {
        await _dealRepo.unsaveDeal(_userId!, dealId);
        _savedDealIds.remove(dealId);
      } else {
        await _dealRepo.saveDeal(_userId!, dealId);
        _savedDealIds.add(dealId);
      }
      
      _savedDeals = await _dealRepo.getSavedDeals(_userId!);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<DealModel?> getDealById(String dealId) async {
    return await _dealRepo.getDealById(dealId);
  }

  List<DealModel> getDealsByCategory(String category) {
    return _deals.where((deal) => deal.category == category).toList();
  }
}

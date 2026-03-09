import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../repositories/item_repository.dart';
import '../repositories/user_repository.dart';

class ItemService extends ChangeNotifier {
  final ItemRepository _itemRepo = ItemRepository();
  final UserRepository _userRepo = UserRepository();
  
  List<ItemModel> _items = [];
  List<ItemModel> _expiringSoon = [];
  List<ItemModel> _expiredItems = [];
  Map<String, int> _categoryStats = {};
  Map<String, dynamic> _analyticsStats = {};
  bool _isLoading = false;
  String? _error;
  String? _userId;
  ItemCategory? _selectedCategory;
  String _searchQuery = '';

  List<ItemModel> get items => _items;
  List<ItemModel> get expiringSoon => _expiringSoon;
  List<ItemModel> get expiredItems => _expiredItems;
  Map<String, int> get categoryStats => _categoryStats;
  Map<String, dynamic> get analyticsStats => _analyticsStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ItemCategory? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  List<ItemModel> get filteredItems {
    var filtered = _items;
    
    if (_selectedCategory != null) {
      filtered = filtered.where((item) => item.category == _selectedCategory).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((item) =>
        item.name.toLowerCase().contains(query) ||
        item.categoryName.toLowerCase().contains(query) ||
        (item.location?.toLowerCase().contains(query) ?? false)
      ).toList();
    }
    
    return filtered;
  }

  Future<bool> _ensureUserInitialized() async {
    if (_userId != null) return true;

    try {
      final user = await _userRepo.createOrGetDefaultUser();
      _userId = user.id;
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _userRepo.createOrGetDefaultUser();
      _userId = user.id;
      await loadItems();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadItems() async {
    if (_userId == null) return;

    try {
      _items = await _itemRepo.getAllItems(_userId!);
      _expiringSoon = await _itemRepo.getExpiringSoon(_userId!);
      _expiredItems = await _itemRepo.getExpiredItems(_userId!);
      _categoryStats = await _itemRepo.getCategoryStats(_userId!);
      _analyticsStats = await _itemRepo.getAnalyticsStats(_userId!);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    notifyListeners();
  }

  void setSelectedCategory(ItemCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<String?> addItem(ItemModel item) async {
    if (!await _ensureUserInitialized()) {
      return _error ?? 'User not initialized';
    }

    try {
      await _itemRepo.insertItem(item, _userId!);
      await loadItems();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateItem(ItemModel item) async {
    if (!await _ensureUserInitialized()) {
      return _error ?? 'User not initialized';
    }

    try {
      await _itemRepo.updateItem(item, _userId!);
      await loadItems();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteItem(String itemId) async {
    if (!await _ensureUserInitialized()) {
      return _error ?? 'User not initialized';
    }

    try {
      await _itemRepo.deleteItem(itemId, _userId!);
      await loadItems();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> markAsUsed(String itemId) async {
    if (!await _ensureUserInitialized()) {
      return _error ?? 'User not initialized';
    }

    try {
      await _itemRepo.markAsUsed(itemId, _userId!);
      await loadItems();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<ItemModel?> getItemById(String itemId) async {
    return await _itemRepo.getItemById(itemId);
  }

  Future<List<ItemModel>> searchItems(String query) async {
    if (!await _ensureUserInitialized()) return [];
    return await _itemRepo.searchItems(_userId!, query);
  }
}

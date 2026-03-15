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
  List<ItemModel> _usedItems = [];
  List<ItemModel> _deletedItems = [];
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
  List<ItemModel> get usedItems => _usedItems;
  List<ItemModel> get deletedItems => _deletedItems;
  Map<String, int> get categoryStats => _categoryStats;
  Map<String, dynamic> get analyticsStats => _analyticsStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ItemCategory? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  int get deletedCount => _deletedItems.length;

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

  /// Returns weekly activity data: items added per day (Mon-Sun) for the current week
  Map<int, int> get weeklyActivity {
    final now = DateTime.now();
    // Get the start of the current week (Monday)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    
    // Initialize counts for each day (0=Mon, 6=Sun)
    final Map<int, int> dailyCounts = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
    
    // Count items added this week
    for (final item in _items) {
      final itemDate = DateTime(item.createdAt.year, item.createdAt.month, item.createdAt.day);
      if (itemDate.isAfter(startDate.subtract(const Duration(days: 1))) && 
          itemDate.isBefore(startDate.add(const Duration(days: 7)))) {
        final dayIndex = item.createdAt.weekday - 1; // 0=Mon, 6=Sun
        dailyCounts[dayIndex] = (dailyCounts[dayIndex] ?? 0) + 1;
      }
    }
    
    // Also count used items this week
    for (final item in _usedItems) {
      if (item.deletedAt != null) {
        final usedDate = DateTime(item.deletedAt!.year, item.deletedAt!.month, item.deletedAt!.day);
        if (usedDate.isAfter(startDate.subtract(const Duration(days: 1))) && 
            usedDate.isBefore(startDate.add(const Duration(days: 7)))) {
          final dayIndex = item.deletedAt!.weekday - 1;
          dailyCounts[dayIndex] = (dailyCounts[dayIndex] ?? 0) + 1;
        }
      }
    }
    
    return dailyCounts;
  }

  /// Returns the maximum value in weekly activity for chart scaling
  int get weeklyActivityMax {
    final activity = weeklyActivity;
    int max = 0;
    for (final count in activity.values) {
      if (count > max) max = count;
    }
    return max < 5 ? 5 : max + 2; // Minimum of 5, otherwise max + 2 for padding
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
      _usedItems = await _itemRepo.getUsedItems(_userId!);
      _deletedItems = await _itemRepo.getDeletedItems(_userId!);
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

  Future<String?> restoreItem(String itemId) async {
    if (!await _ensureUserInitialized()) {
      return _error ?? 'User not initialized';
    }

    try {
      await _itemRepo.restoreItem(itemId, _userId!);
      await loadItems();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> permanentlyDeleteItem(String itemId) async {
    if (!await _ensureUserInitialized()) {
      return _error ?? 'User not initialized';
    }

    try {
      await _itemRepo.permanentlyDeleteItem(itemId, _userId!);
      await loadItems();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> emptyTrash() async {
    if (!await _ensureUserInitialized()) {
      return _error ?? 'User not initialized';
    }

    try {
      await _itemRepo.emptyTrash(_userId!);
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

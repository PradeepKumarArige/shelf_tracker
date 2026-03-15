import 'package:uuid/uuid.dart';
import '../models/item_model.dart';
import '../services/database_service.dart';

class ItemRepository {
  final DatabaseService _db = DatabaseService();
  final _uuid = const Uuid();

  Future<List<ItemModel>> getAllItems(String userId) async {
    final db = await _db.database;
    final results = await db.query(
      'items',
      where: 'user_id = ? AND is_used = 0 AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'expiry_date ASC',
    );
    return results.map((map) => ItemModel.fromMap(_convertDbMap(map))).toList();
  }

  Future<List<ItemModel>> getItemsByCategory(String userId, ItemCategory category) async {
    final db = await _db.database;
    final results = await db.query(
      'items',
      where: 'user_id = ? AND category = ? AND is_used = 0 AND is_deleted = 0',
      whereArgs: [userId, category.index],
      orderBy: 'expiry_date ASC',
    );
    return results.map((map) => ItemModel.fromMap(_convertDbMap(map))).toList();
  }

  Future<List<ItemModel>> getExpiringSoon(String userId, {int days = 7}) async {
    final db = await _db.database;
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));
    
    final results = await db.query(
      'items',
      where: 'user_id = ? AND is_used = 0 AND is_deleted = 0 AND expiry_date >= ? AND expiry_date <= ?',
      whereArgs: [userId, now.toIso8601String(), futureDate.toIso8601String()],
      orderBy: 'expiry_date ASC',
    );
    return results.map((map) => ItemModel.fromMap(_convertDbMap(map))).toList();
  }

  Future<List<ItemModel>> getExpiredItems(String userId) async {
    final db = await _db.database;
    final now = DateTime.now();
    
    final results = await db.query(
      'items',
      where: 'user_id = ? AND is_used = 0 AND is_deleted = 0 AND expiry_date < ?',
      whereArgs: [userId, now.toIso8601String()],
      orderBy: 'expiry_date DESC',
    );
    return results.map((map) => ItemModel.fromMap(_convertDbMap(map))).toList();
  }

  Future<List<ItemModel>> getUsedItems(String userId) async {
    final db = await _db.database;
    final results = await db.query(
      'items',
      where: 'user_id = ? AND is_used = 1 AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'used_date DESC',
    );
    return results.map((map) => ItemModel.fromMap(_convertDbMap(map))).toList();
  }

  Future<List<ItemModel>> getDeletedItems(String userId) async {
    final db = await _db.database;
    final results = await db.query(
      'items',
      where: 'user_id = ? AND is_deleted = 1',
      whereArgs: [userId],
      orderBy: 'deleted_at DESC',
    );
    return results.map((map) => ItemModel.fromMap(_convertDbMap(map))).toList();
  }

  Future<ItemModel?> getItemById(String id) async {
    final db = await _db.database;
    final results = await db.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ItemModel.fromMap(_convertDbMap(results.first));
  }

  Future<ItemModel?> getItemByBarcode(String userId, String barcode) async {
    final db = await _db.database;
    final results = await db.query(
      'items',
      where: 'user_id = ? AND barcode = ?',
      whereArgs: [userId, barcode],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ItemModel.fromMap(_convertDbMap(results.first));
  }

  Future<String> insertItem(ItemModel item, String userId) async {
    final db = await _db.database;
    final id = item.id.isEmpty ? _uuid.v4() : item.id;
    final now = DateTime.now();
    
    await db.insert('items', {
      'id': id,
      'user_id': userId,
      'name': item.name,
      'category': item.category.index,
      'purchase_date': item.purchaseDate.toIso8601String(),
      'expiry_date': item.expiryDate.toIso8601String(),
      'quantity': item.quantity,
      'location': item.location,
      'notes': item.notes,
      'barcode': item.barcode,
      'image_url': null,
      'is_used': 0,
      'used_date': null,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    await _logHistory(db, id, userId, 'created', null, item.toMap());
    
    return id;
  }

  Future<void> updateItem(ItemModel item, String userId) async {
    final db = await _db.database;
    final oldItem = await getItemById(item.id);
    
    await db.update(
      'items',
      {
        'name': item.name,
        'category': item.category.index,
        'purchase_date': item.purchaseDate.toIso8601String(),
        'expiry_date': item.expiryDate.toIso8601String(),
        'quantity': item.quantity,
        'location': item.location,
        'notes': item.notes,
        'barcode': item.barcode,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );

    await _logHistory(db, item.id, userId, 'updated', oldItem?.toMap(), item.toMap());
  }

  Future<void> markAsUsed(String itemId, String userId) async {
    final db = await _db.database;
    final now = DateTime.now();
    
    await db.update(
      'items',
      {
        'is_used': 1,
        'used_date': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );

    await _logHistory(db, itemId, userId, 'marked_used', null, {'used_date': now.toIso8601String()});
  }

  Future<void> deleteItem(String itemId, String userId) async {
    final db = await _db.database;
    final now = DateTime.now();
    
    await db.update(
      'items',
      {
        'is_deleted': 1,
        'deleted_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );

    await _logHistory(db, itemId, userId, 'soft_deleted', null, {'deleted_at': now.toIso8601String()});
  }

  Future<void> restoreItem(String itemId, String userId) async {
    final db = await _db.database;
    final now = DateTime.now();
    
    await db.update(
      'items',
      {
        'is_deleted': 0,
        'deleted_at': null,
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );

    await _logHistory(db, itemId, userId, 'restored', null, {'restored_at': now.toIso8601String()});
  }

  Future<void> permanentlyDeleteItem(String itemId, String userId) async {
    final db = await _db.database;
    final oldItem = await getItemById(itemId);
    
    await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [itemId],
    );

    await _logHistory(db, itemId, userId, 'permanently_deleted', oldItem?.toMap(), null);
  }

  Future<void> emptyTrash(String userId) async {
    final db = await _db.database;
    
    await db.delete(
      'items',
      where: 'user_id = ? AND is_deleted = 1',
      whereArgs: [userId],
    );

    await _logHistory(db, 'all', userId, 'trash_emptied', null, null);
  }

  Future<List<ItemModel>> searchItems(String userId, String query) async {
    final db = await _db.database;
    final results = await db.query(
      'items',
      where: 'user_id = ? AND is_deleted = 0 AND (name LIKE ? OR location LIKE ?)',
      whereArgs: [userId, '%$query%', '%$query%'],
      orderBy: 'expiry_date ASC',
    );
    return results.map((map) => ItemModel.fromMap(_convertDbMap(map))).toList();
  }

  Future<Map<String, int>> getCategoryStats(String userId) async {
    final db = await _db.database;
    final results = await db.rawQuery('''
      SELECT category, COUNT(*) as count 
      FROM items 
      WHERE user_id = ? AND is_used = 0 AND is_deleted = 0
      GROUP BY category
    ''', [userId]);

    final stats = <String, int>{};
    for (final row in results) {
      final category = ItemCategory.values[row['category'] as int];
      stats[category.name] = row['count'] as int;
    }
    return stats;
  }

  Future<Map<String, dynamic>> getAnalyticsStats(String userId) async {
    final db = await _db.database;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    final totalItems = await db.rawQuery(
      'SELECT COUNT(*) as count FROM items WHERE user_id = ? AND is_used = 0 AND is_deleted = 0',
      [userId],
    );

    final usedThisMonth = await db.rawQuery('''
      SELECT COUNT(*) as count FROM items 
      WHERE user_id = ? AND is_used = 1 AND is_deleted = 0 AND used_date >= ?
    ''', [userId, monthStart.toIso8601String()]);

    final expiredThisMonth = await db.rawQuery('''
      SELECT COUNT(*) as count FROM items 
      WHERE user_id = ? AND is_used = 0 AND is_deleted = 0 AND expiry_date < ? AND expiry_date >= ?
    ''', [userId, now.toIso8601String(), monthStart.toIso8601String()]);

    final deletedItems = await db.rawQuery(
      'SELECT COUNT(*) as count FROM items WHERE user_id = ? AND is_deleted = 1',
      [userId],
    );

    return {
      'total_items': (totalItems.first['count'] as int?) ?? 0,
      'used_this_month': (usedThisMonth.first['count'] as int?) ?? 0,
      'expired_this_month': (expiredThisMonth.first['count'] as int?) ?? 0,
      'deleted_items': (deletedItems.first['count'] as int?) ?? 0,
    };
  }

  Future<void> _logHistory(
    dynamic db,
    String itemId,
    String userId,
    String action,
    Map<String, dynamic>? previousValues,
    Map<String, dynamic>? newValues,
  ) async {
    await db.insert('item_history', {
      'id': _uuid.v4(),
      'item_id': itemId,
      'user_id': userId,
      'action': action,
      'previous_values': previousValues?.toString(),
      'new_values': newValues?.toString(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Map<String, dynamic> _convertDbMap(Map<String, dynamic> dbMap) {
    return {
      'id': dbMap['id'],
      'name': dbMap['name'],
      'category': dbMap['category'],
      'purchaseDate': dbMap['purchase_date'],
      'expiryDate': dbMap['expiry_date'],
      'quantity': dbMap['quantity'],
      'location': dbMap['location'],
      'notes': dbMap['notes'],
      'barcode': dbMap['barcode'],
      'isDeleted': dbMap['is_deleted'] == 1,
      'deletedAt': dbMap['deleted_at'],
      'createdAt': dbMap['created_at'],
      'updatedAt': dbMap['updated_at'],
    };
  }
}

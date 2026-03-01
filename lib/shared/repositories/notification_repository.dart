import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import '../services/database_service.dart';

class NotificationRepository {
  final DatabaseService _db = DatabaseService();
  final _uuid = const Uuid();

  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    final db = await _db.database;
    final results = await db.query(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return results.map((map) => NotificationModel.fromMap(map)).toList();
  }

  Future<List<NotificationModel>> getUnreadNotifications(String userId) async {
    final db = await _db.database;
    final results = await db.query(
      'notifications',
      where: 'user_id = ? AND is_read = 0',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return results.map((map) => NotificationModel.fromMap(map)).toList();
  }

  Future<int> getUnreadCount(String userId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = 0',
      [userId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<NotificationModel?> getNotificationById(String id) async {
    final db = await _db.database;
    final results = await db.query(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return NotificationModel.fromMap(results.first);
  }

  Future<String> createNotification(NotificationModel notification) async {
    final db = await _db.database;
    final id = notification.id.isEmpty ? _uuid.v4() : notification.id;
    
    final newNotification = NotificationModel(
      id: id,
      userId: notification.userId,
      itemId: notification.itemId,
      type: notification.type,
      title: notification.title,
      body: notification.body,
      scheduledAt: notification.scheduledAt,
    );
    
    await db.insert('notifications', newNotification.toMap());
    return id;
  }

  Future<void> markAsRead(String notificationId) async {
    final db = await _db.database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  Future<void> markAllAsRead(String userId) async {
    final db = await _db.database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'user_id = ? AND is_read = 0',
      whereArgs: [userId],
    );
  }

  Future<void> deleteNotification(String notificationId) async {
    final db = await _db.database;
    await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  Future<void> deleteAllNotifications(String userId) async {
    final db = await _db.database;
    await db.delete(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> createExpiryNotification({
    required String userId,
    required String itemId,
    required String itemName,
    required int daysUntilExpiry,
  }) async {
    String title;
    String body;

    if (daysUntilExpiry <= 0) {
      title = 'Item Expired!';
      body = '$itemName has expired. Consider disposing it safely.';
    } else if (daysUntilExpiry == 1) {
      title = 'Expiring Tomorrow';
      body = '$itemName expires tomorrow. Use it soon!';
    } else {
      title = 'Expiring Soon';
      body = '$itemName expires in $daysUntilExpiry days.';
    }

    await createNotification(NotificationModel(
      id: '',
      userId: userId,
      itemId: itemId,
      type: NotificationType.expiry,
      title: title,
      body: body,
    ));
  }
}

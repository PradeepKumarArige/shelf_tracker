import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class UserRepository {
  final DatabaseService _db = DatabaseService();
  final _uuid = const Uuid();

  Future<UserModel?> getCurrentUser() async {
    final db = await _db.database;
    final results = await db.query('users', limit: 1);
    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  Future<UserModel?> getUserById(String id) async {
    final db = await _db.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await _db.database;
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  Future<String> createUser(UserModel user) async {
    final db = await _db.database;
    final id = user.id.isEmpty ? _uuid.v4() : user.id;
    
    final newUser = UserModel(
      id: id,
      email: user.email,
      name: user.name,
      avatarUrl: user.avatarUrl,
      notificationEnabled: user.notificationEnabled,
      emailAlertsEnabled: user.emailAlertsEnabled,
      dealNotificationsEnabled: user.dealNotificationsEnabled,
      defaultExpiryDays: user.defaultExpiryDays,
      language: user.language,
    );
    
    await db.insert('users', newUser.toMap());
    return id;
  }

  Future<UserModel> createOrGetDefaultUser() async {
    var user = await getCurrentUser();
    if (user != null) return user;

    final id = _uuid.v4();
    user = UserModel(
      id: id,
      email: 'user@shelftracker.app',
      name: 'User',
    );
    
    await createUser(user);
    return user;
  }

  Future<void> updateUser(UserModel user) async {
    final db = await _db.database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> updateUserSettings({
    required String userId,
    bool? notificationEnabled,
    bool? emailAlertsEnabled,
    bool? dealNotificationsEnabled,
    int? defaultExpiryDays,
    String? language,
  }) async {
    final db = await _db.database;
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (notificationEnabled != null) {
      updates['notification_enabled'] = notificationEnabled ? 1 : 0;
    }
    if (emailAlertsEnabled != null) {
      updates['email_alerts_enabled'] = emailAlertsEnabled ? 1 : 0;
    }
    if (dealNotificationsEnabled != null) {
      updates['deal_notifications_enabled'] = dealNotificationsEnabled ? 1 : 0;
    }
    if (defaultExpiryDays != null) {
      updates['default_expiry_days'] = defaultExpiryDays;
    }
    if (language != null) {
      updates['language'] = language;
    }

    await db.update(
      'users',
      updates,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteUser(String userId) async {
    final db = await _db.database;
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}

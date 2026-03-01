import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

class UserService extends ChangeNotifier {
  final UserRepository _userRepo = UserRepository();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _userRepo.createOrGetDefaultUser();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> updateProfile({
    String? name,
    String? email,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return 'User not initialized';

    try {
      final updatedUser = _currentUser!.copyWith(
        name: name,
        email: email,
        avatarUrl: avatarUrl,
      );
      
      await _userRepo.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateSettings({
    bool? notificationEnabled,
    bool? emailAlertsEnabled,
    bool? dealNotificationsEnabled,
    int? defaultExpiryDays,
    String? language,
  }) async {
    if (_currentUser == null) return 'User not initialized';

    try {
      await _userRepo.updateUserSettings(
        userId: _currentUser!.id,
        notificationEnabled: notificationEnabled,
        emailAlertsEnabled: emailAlertsEnabled,
        dealNotificationsEnabled: dealNotificationsEnabled,
        defaultExpiryDays: defaultExpiryDays,
        language: language,
      );

      _currentUser = _currentUser!.copyWith(
        notificationEnabled: notificationEnabled,
        emailAlertsEnabled: emailAlertsEnabled,
        dealNotificationsEnabled: dealNotificationsEnabled,
        defaultExpiryDays: defaultExpiryDays,
        language: language,
      );
      
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> refreshUser() async {
    if (_currentUser == null) return;

    try {
      _currentUser = await _userRepo.getUserById(_currentUser!.id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/item_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();
    
    // Get device timezone and set it as local
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      debugPrint('Device timezone: $timeZoneName');
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('Timezone set to: ${tz.local}');
    } catch (e) {
      debugPrint('Failed to get timezone: $e, using UTC');
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<bool> requestPermissions() async {
    // Request notification permission using permission_handler
    final notificationStatus = await Permission.notification.request();
    debugPrint('Notification permission status: $notificationStatus');
    
    if (!notificationStatus.isGranted) {
      debugPrint('Notification permission not granted');
      return false;
    }

    // Request exact alarm permission for Android 12+
    final alarmStatus = await Permission.scheduleExactAlarm.request();
    debugPrint('Exact alarm permission status: $alarmStatus');

    // Also request through flutter_local_notifications for iOS
    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return notificationStatus.isGranted;
  }

  Future<bool> areNotificationsEnabled() async {
    final status = await Permission.notification.status;
    debugPrint('Checking notification status: $status');
    return status.isGranted;
  }

  Future<void> openNotificationSettings() async {
    await openAppSettings();
  }

  Future<void> scheduleItemReminder({
    required ItemModel item,
    required int daysBefore,
  }) async {
    final reminderDate = item.expiryDate.subtract(Duration(days: daysBefore));
    
    if (reminderDate.isBefore(DateTime.now())) {
      return;
    }

    final notificationId = item.id.hashCode + daysBefore;

    await _notifications.zonedSchedule(
      notificationId,
      'Item Expiring Soon!',
      '${item.name} will expire in $daysBefore day${daysBefore > 1 ? 's' : ''}',
      tz.TZDateTime.from(reminderDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'item_reminders',
          'Item Reminders',
          channelDescription: 'Reminders for expiring items',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF4CAF50),
          styleInformation: BigTextStyleInformation(
            '${item.name} will expire in $daysBefore day${daysBefore > 1 ? 's' : ''}. Don\'t forget to use it!',
            contentTitle: 'Item Expiring Soon!',
            summaryText: item.categoryName,
          ),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          subtitle: item.categoryName,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: item.id,
    );
  }

  Future<void> scheduleMultipleReminders({
    required ItemModel item,
    required List<int> daysBefore,
  }) async {
    for (final days in daysBefore) {
      await scheduleItemReminder(item: item, daysBefore: days);
    }
  }

  Future<void> cancelItemReminders(String itemId) async {
    final baseId = itemId.hashCode;
    for (int i = 0; i <= 30; i++) {
      await _notifications.cancel(baseId + i);
    }
  }

  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_notifications',
          'Instant Notifications',
          channelDescription: 'Instant app notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<List<PendingNotificationRequest>> getPendingReminders() async {
    return await _notifications.pendingNotificationRequests();
  }
}

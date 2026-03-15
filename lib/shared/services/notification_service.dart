import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/item_model.dart';
import 'tts_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final TtsService _ttsService = TtsService();
  bool _isInitialized = false;
  bool _voiceNotificationsEnabled = true;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();
    
    // Get device timezone and set it as local
    try {
      String timeZoneName = await FlutterTimezone.getLocalTimezone();
      debugPrint('Device timezone: $timeZoneName');
      
      // Handle timezone name aliases (old names to new names)
      final Map<String, String> timezoneAliases = {
        'Asia/Calcutta': 'Asia/Kolkata',
        'US/Eastern': 'America/New_York',
        'US/Pacific': 'America/Los_Angeles',
        'US/Central': 'America/Chicago',
        'US/Mountain': 'America/Denver',
      };
      
      if (timezoneAliases.containsKey(timeZoneName)) {
        timeZoneName = timezoneAliases[timeZoneName]!;
        debugPrint('Mapped timezone to: $timeZoneName');
      }
      
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

    // Initialize TTS service
    await _ttsService.initialize();

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    
    // Check if this is a medicine reminder notification and speak it
    final notificationId = response.id;
    final payload = response.payload;
    
    if (notificationId != null && payload != null) {
      // Check the notification title/body from the response if available
      // For medicine reminders, speak the content
      _speakNotificationContent(response);
    }
  }

  Future<void> _speakNotificationContent(NotificationResponse response) async {
    if (!_voiceNotificationsEnabled) return;
    
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      // Parse the payload: medicineName|dosage|dosageUnit|mealTime
      final parts = payload.split('|');
      if (parts.length >= 4) {
        final medicineName = parts[0];
        final dosage = int.tryParse(parts[1]) ?? 1;
        final dosageUnit = parts[2];
        final mealTime = parts[3];
        
        await _ttsService.speakMedicineReminder(
          medicineName: medicineName,
          dosage: dosage,
          dosageUnit: dosageUnit,
          mealTime: mealTime,
        );
      } else {
        // Fallback for older format or item reminders
        await _ttsService.speak('Reminder. Please check your notification for details.');
      }
    }
  }

  // Voice notification controls
  bool get voiceNotificationsEnabled => _voiceNotificationsEnabled;
  
  void setVoiceNotificationsEnabled(bool enabled) {
    _voiceNotificationsEnabled = enabled;
  }

  Future<void> speakNotification(String message) async {
    if (_voiceNotificationsEnabled) {
      await _ttsService.speak(message);
    }
  }

  Future<void> speakMedicineReminder({
    required String medicineName,
    required int dosage,
    required String dosageUnit,
    String? mealTime,
  }) async {
    if (_voiceNotificationsEnabled) {
      await _ttsService.speakMedicineReminder(
        medicineName: medicineName,
        dosage: dosage,
        dosageUnit: dosageUnit,
        mealTime: mealTime,
      );
    }
  }

  Future<void> stopSpeaking() async {
    await _ttsService.stop();
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

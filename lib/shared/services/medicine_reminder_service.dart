import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';
import '../models/medicine_reminder_model.dart';
import 'notification_service.dart';

class MedicineReminderService extends ChangeNotifier {
  static final MedicineReminderService _instance = MedicineReminderService._internal();
  factory MedicineReminderService() => _instance;
  MedicineReminderService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final List<MedicineReminder> _reminders = [];
  static const String _storageKey = 'medicine_reminders';

  List<MedicineReminder> get reminders => List.unmodifiable(_reminders);

  List<MedicineReminder> getRemindersForItem(String itemId) {
    return _reminders.where((r) => r.itemId == itemId && r.isActive).toList();
  }

  Future<void> initialize() async {
    await _loadReminders();
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      _reminders.clear();
      _reminders.addAll(
        jsonList.map((json) => MedicineReminder.fromMap(json as Map<String, dynamic>)),
      );
      notifyListeners();
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _reminders.map((r) => r.toMap()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  Future<void> addReminder(MedicineReminder reminder) async {
    _reminders.add(reminder);
    await _saveReminders();
    await _scheduleNotifications(reminder);
    notifyListeners();
  }

  Future<void> updateReminder(MedicineReminder reminder) async {
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      await _cancelNotifications(_reminders[index]);
      _reminders[index] = reminder;
      await _saveReminders();
      if (reminder.isActive) {
        await _scheduleNotifications(reminder);
      }
      notifyListeners();
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    final reminder = _reminders.firstWhere((r) => r.id == reminderId);
    await _cancelNotifications(reminder);
    _reminders.removeWhere((r) => r.id == reminderId);
    await _saveReminders();
    notifyListeners();
  }

  Future<void> deleteRemindersForItem(String itemId) async {
    final itemReminders = _reminders.where((r) => r.itemId == itemId).toList();
    for (final reminder in itemReminders) {
      await _cancelNotifications(reminder);
    }
    _reminders.removeWhere((r) => r.itemId == itemId);
    await _saveReminders();
    notifyListeners();
  }

  Future<void> toggleReminder(String reminderId, bool isActive) async {
    final index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index != -1) {
      final reminder = _reminders[index].copyWith(isActive: isActive);
      if (!isActive) {
        await _cancelNotifications(_reminders[index]);
      }
      _reminders[index] = reminder;
      await _saveReminders();
      if (isActive) {
        await _scheduleNotifications(reminder);
      }
      notifyListeners();
    }
  }

  Future<void> _scheduleNotifications(MedicineReminder reminder) async {
    for (int i = 0; i < reminder.schedules.length; i++) {
      final schedule = reminder.schedules[i];
      if (!schedule.isEnabled) continue;

      final notificationId = _generateNotificationId(reminder.id, i);
      final scheduledTime = _nextInstanceOfTime(schedule.time);
      
      debugPrint('Scheduling alarm: ${reminder.itemName} - ${schedule.label}');
      debugPrint('  Notification ID: $notificationId');
      debugPrint('  Scheduled for: $scheduledTime');
      
      await _notifications.zonedSchedule(
        notificationId,
        'Medicine Reminder 💊',
        'Time to take ${reminder.dosage} ${reminder.dosageUnit}${reminder.dosage > 1 ? 's' : ''} of ${reminder.itemName} (${schedule.label})',
        scheduledTime,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'shelf_medicine_alerts',
            'Medicine Alerts',
            channelDescription: 'Medicine reminder alerts with sound',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            subtitle: schedule.label,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: reminder.itemId,
      );
      
      debugPrint('  Alarm scheduled successfully!');
    }
    
    // Log pending notifications
    final pending = await _notifications.pendingNotificationRequests();
    debugPrint('Total pending notifications: ${pending.length}');
    for (final p in pending) {
      debugPrint('  Pending: id=${p.id}, title=${p.title}');
    }
  }

  Future<void> _cancelNotifications(MedicineReminder reminder) async {
    for (int i = 0; i < reminder.schedules.length; i++) {
      final notificationId = _generateNotificationId(reminder.id, i);
      await _notifications.cancel(notificationId);
    }
  }

  int _generateNotificationId(String reminderId, int scheduleIndex) {
    return (reminderId.hashCode + scheduleIndex * 1000).abs() % 2147483647;
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  MedicineReminder createDefaultReminder({
    required String itemId,
    required String itemName,
  }) {
    return MedicineReminder(
      id: const Uuid().v4(),
      itemId: itemId,
      itemName: itemName,
      dosage: 1,
      dosageUnit: 'tablet',
      schedules: [
        MedicineSchedule(
          mealTime: MealTime.morning,
          medicineTime: MedicineTime.after,
          time: const TimeOfDay(hour: 8, minute: 0),
          isEnabled: false,
        ),
        MedicineSchedule(
          mealTime: MealTime.lunch,
          medicineTime: MedicineTime.after,
          time: const TimeOfDay(hour: 13, minute: 0),
          isEnabled: false,
        ),
        MedicineSchedule(
          mealTime: MealTime.dinner,
          medicineTime: MedicineTime.after,
          time: const TimeOfDay(hour: 20, minute: 0),
          isEnabled: false,
        ),
      ],
      createdAt: DateTime.now(),
      isActive: true,
    );
  }

  static List<String> get dosageUnits => [
    'tablet',
    'capsule',
    'ml',
    'drop',
    'spoon',
    'sachet',
  ];

  Future<bool> requestNotificationPermissions() async {
    final notificationService = NotificationService();
    return await notificationService.requestPermissions();
  }

  Future<bool> areNotificationsEnabled() async {
    final notificationService = NotificationService();
    return await notificationService.areNotificationsEnabled();
  }

  Future<void> sendTestNotification(String itemName) async {
    debugPrint('Sending test notification for: $itemName');
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Test Medicine Reminder 💊',
      'This is a test notification for $itemName. If you hear the alarm, it\'s working!',
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'shelf_medicine_alerts',
          'Medicine Alerts',
          channelDescription: 'Medicine reminder alerts with sound',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        ),
      ),
    );
    debugPrint('Test notification sent!');
  }

  Future<void> scheduleTestAlarm(String itemName) async {
    final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 30));
    debugPrint('Scheduling test alarm for: $scheduledTime');
    
    await _notifications.zonedSchedule(
      99999,
      'Test Scheduled Alarm 💊',
      'This is a scheduled alarm test for $itemName - Should arrive 30 seconds after setting!',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'shelf_medicine_alerts',
          'Medicine Alerts',
          channelDescription: 'Medicine reminder alerts with sound',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          visibility: NotificationVisibility.public,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    
    debugPrint('Test alarm scheduled successfully!');
    
    final pending = await _notifications.pendingNotificationRequests();
    debugPrint('Pending notifications after test: ${pending.length}');
    for (final p in pending) {
      debugPrint('  id=${p.id}, title=${p.title}');
    }
  }
}

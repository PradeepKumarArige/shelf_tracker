import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';
import '../models/medicine_reminder_model.dart';
import 'notification_service.dart';
import 'background_alarm_service.dart';

class MedicineReminderService extends ChangeNotifier {
  static final MedicineReminderService _instance = MedicineReminderService._internal();
  factory MedicineReminderService() => _instance;
  MedicineReminderService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final List<MedicineReminder> _reminders = [];
  static const String _storageKey = 'medicine_reminders';
  static const String _lastSpokenKey = 'last_spoken_alarms';
  
  Timer? _foregroundAlarmChecker;
  final Set<String> _spokenAlarms = {}; // Track which alarms have been spoken today
  final Map<int, Timer> _foregroundTimers = {}; // Track scheduled foreground timers

  List<MedicineReminder> get reminders => List.unmodifiable(_reminders);

  List<MedicineReminder> getRemindersForItem(String itemId) {
    return _reminders.where((r) => r.itemId == itemId && r.isActive).toList();
  }

  Future<void> initialize() async {
    await _loadReminders();
    await _loadSpokenAlarms();
    _startForegroundAlarmChecker();
  }
  
  @override
  void dispose() {
    _foregroundAlarmChecker?.cancel();
    super.dispose();
  }
  
  // Call this when app resumes from background to immediately check alarms
  void onAppResumed() {
    debugPrint('App resumed - checking for due alarms');
    _checkAndSpeakDueAlarms();
  }
  
  // Start a timer that checks for due alarms every 30 seconds when app is running
  void _startForegroundAlarmChecker() {
    _foregroundAlarmChecker?.cancel();
    _foregroundAlarmChecker = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkAndSpeakDueAlarms();
    });
    debugPrint('Foreground alarm checker started');
  }
  
  // Load previously spoken alarms to avoid repeating
  Future<void> _loadSpokenAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_lastSpokenKey) ?? [];
    _spokenAlarms.clear();
    _spokenAlarms.addAll(data);
    
    // Clean up old entries (only keep today's)
    final today = DateTime.now();
    final todayPrefix = '${today.year}-${today.month}-${today.day}';
    _spokenAlarms.removeWhere((key) => !key.startsWith(todayPrefix));
    await _saveSpokenAlarms();
  }
  
  Future<void> _saveSpokenAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_lastSpokenKey, _spokenAlarms.toList());
  }
  
  // Check if any alarms are due and speak them (for foreground operation)
  Future<void> _checkAndSpeakDueAlarms() async {
    final now = DateTime.now();
    final notificationService = NotificationService();
    
    for (final reminder in _reminders) {
      if (!reminder.isActive) continue;
      
      for (int i = 0; i < reminder.schedules.length; i++) {
        final schedule = reminder.schedules[i];
        if (!schedule.isEnabled) continue;
        
        // Check if this alarm is due (within 1 minute window)
        final alarmTime = DateTime(
          now.year, now.month, now.day,
          schedule.time.hour, schedule.time.minute,
        );
        
        final diff = now.difference(alarmTime).inSeconds.abs();
        if (diff <= 60) { // Within 1 minute of scheduled time
          // Create unique key for this alarm instance
          final alarmKey = '${now.year}-${now.month}-${now.day}-${reminder.id}-$i';
          
          if (!_spokenAlarms.contains(alarmKey)) {
            debugPrint('Foreground alarm due: ${reminder.itemName} - ${schedule.label}');
            
            await notificationService.speakMedicineReminder(
              medicineName: reminder.itemName,
              dosage: reminder.dosage,
              dosageUnit: reminder.dosageUnit,
              mealTime: schedule.label,
            );
            
            _spokenAlarms.add(alarmKey);
            await _saveSpokenAlarms();
          }
        }
      }
    }
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
    final notificationService = NotificationService();
    
    for (int i = 0; i < reminder.schedules.length; i++) {
      final schedule = reminder.schedules[i];
      if (!schedule.isEnabled) continue;

      final notificationId = _generateNotificationId(reminder.id, i);
      final scheduledTime = _nextInstanceOfTime(schedule.time);
      
      debugPrint('Scheduling alarm: ${reminder.itemName} - ${schedule.label}');
      debugPrint('  Notification ID: $notificationId');
      debugPrint('  Local timezone: ${tz.local}');
      debugPrint('  Current local time: ${tz.TZDateTime.now(tz.local)}');
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
        payload: '${reminder.itemName}|${reminder.dosage}|${reminder.dosageUnit}|${schedule.label}',
      );
      
      // Also schedule background voice alarm for TTS when app is closed
      final backgroundService = BackgroundAlarmService();
      await backgroundService.scheduleVoiceAlarm(
        alarmId: notificationId + 100000, // Offset to avoid ID collision
        scheduledTime: scheduledTime.toLocal(),
        medicineName: reminder.itemName,
        dosage: reminder.dosage,
        dosageUnit: reminder.dosageUnit,
        mealTime: schedule.label,
        repeating: true, // Daily recurring
      );
      
      // Schedule foreground voice timer for when app is open
      _scheduleForegroundVoiceTimer(
        timerId: notificationId,
        scheduledTime: scheduledTime,
        medicineName: reminder.itemName,
        dosage: reminder.dosage,
        dosageUnit: reminder.dosageUnit,
        mealTime: schedule.label,
        notificationService: notificationService,
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
  
  void _scheduleForegroundVoiceTimer({
    required int timerId,
    required tz.TZDateTime scheduledTime,
    required String medicineName,
    required int dosage,
    required String dosageUnit,
    required String mealTime,
    required NotificationService notificationService,
  }) {
    // Cancel existing timer for this ID
    _foregroundTimers[timerId]?.cancel();
    
    final now = DateTime.now();
    final targetTime = scheduledTime.toLocal();
    final duration = targetTime.difference(now);
    
    if (duration.isNegative) {
      debugPrint('  Foreground timer: Time already passed for today');
      return;
    }
    
    debugPrint('  Foreground voice timer scheduled in ${duration.inSeconds} seconds');
    
    _foregroundTimers[timerId] = Timer(duration, () async {
      debugPrint('Foreground voice timer triggered for: $medicineName - $mealTime');
      await notificationService.speakMedicineReminder(
        medicineName: medicineName,
        dosage: dosage,
        dosageUnit: dosageUnit,
        mealTime: mealTime,
      );
    });
  }

  Future<void> _cancelNotifications(MedicineReminder reminder) async {
    final backgroundService = BackgroundAlarmService();
    for (int i = 0; i < reminder.schedules.length; i++) {
      final notificationId = _generateNotificationId(reminder.id, i);
      await _notifications.cancel(notificationId);
      // Cancel the background voice alarm
      await backgroundService.cancelVoiceAlarm(notificationId + 100000);
      // Cancel the foreground voice timer
      _foregroundTimers[notificationId]?.cancel();
      _foregroundTimers.remove(notificationId);
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

  Future<void> sendTestNotification(String itemName, {int dosage = 1, String dosageUnit = 'tablet'}) async {
    debugPrint('Sending test notification for: $itemName');
    
    // Speak the reminder
    final notificationService = NotificationService();
    await notificationService.speakMedicineReminder(
      medicineName: itemName,
      dosage: dosage,
      dosageUnit: dosageUnit,
      mealTime: 'This is a test reminder',
    );
    
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

  Future<void> scheduleTestAlarm(String itemName, {int dosage = 1, String dosageUnit = 'tablet'}) async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = now.add(const Duration(seconds: 30));
    debugPrint('Current local time: $now');
    debugPrint('Local timezone: ${tz.local}');
    debugPrint('Scheduling test alarm for: $scheduledTime');
    
    // Speak confirmation that alarm is set
    final notificationService = NotificationService();
    await notificationService.speakNotification(
      'Alarm set for $itemName. You will be reminded in 30 seconds.',
    );
    
    // Schedule background voice alarm that works when app is closed/screen locked
    final backgroundService = BackgroundAlarmService();
    await backgroundService.scheduleVoiceAlarm(
      alarmId: 99999,
      scheduledTime: DateTime.now().add(const Duration(seconds: 30)),
      medicineName: itemName,
      dosage: dosage,
      dosageUnit: dosageUnit,
      mealTime: 'Test alarm',
      repeating: false,
    );
    
    // Also schedule foreground voice reminder (works when app is open/in background)
    Future.delayed(const Duration(seconds: 30), () async {
      debugPrint('Foreground timer triggered for: $itemName');
      await notificationService.speakMedicineReminder(
        medicineName: itemName,
        dosage: dosage,
        dosageUnit: dosageUnit,
        mealTime: 'Test alarm',
      );
    });
    
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

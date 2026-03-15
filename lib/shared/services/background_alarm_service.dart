import 'dart:ui';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundAlarmService {
  static final BackgroundAlarmService _instance = BackgroundAlarmService._internal();
  factory BackgroundAlarmService() => _instance;
  BackgroundAlarmService._internal();

  static const String _alarmDataKey = 'pending_voice_alarms';
  
  Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
    debugPrint('BackgroundAlarmService initialized');
  }

  Future<void> scheduleVoiceAlarm({
    required int alarmId,
    required DateTime scheduledTime,
    required String medicineName,
    required int dosage,
    required String dosageUnit,
    required String mealTime,
    bool repeating = false,
  }) async {
    // Store alarm data for background callback
    await _storeAlarmData(
      alarmId: alarmId,
      medicineName: medicineName,
      dosage: dosage,
      dosageUnit: dosageUnit,
      mealTime: mealTime,
    );

    if (repeating) {
      // For daily alarms
      await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        alarmId,
        _alarmCallback,
        startAt: scheduledTime,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
    } else {
      // For one-time alarms (like test alarms)
      await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        alarmId,
        _alarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
    }
    
    debugPrint('Voice alarm scheduled: $medicineName at $scheduledTime (id: $alarmId)');
  }

  Future<void> cancelVoiceAlarm(int alarmId) async {
    await AndroidAlarmManager.cancel(alarmId);
    await _removeAlarmData(alarmId);
    debugPrint('Voice alarm cancelled: $alarmId');
  }

  Future<void> _storeAlarmData({
    required int alarmId,
    required String medicineName,
    required int dosage,
    required String dosageUnit,
    required String mealTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_alarmDataKey}_$alarmId';
    final data = '$medicineName|$dosage|$dosageUnit|$mealTime';
    await prefs.setString(key, data);
  }

  Future<void> _removeAlarmData(int alarmId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_alarmDataKey}_$alarmId';
    await prefs.remove(key);
  }
}

// This must be a top-level function for background execution
@pragma('vm:entry-point')
Future<void> _alarmCallback(int alarmId) async {
  debugPrint('Alarm callback triggered: $alarmId');
  
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  
  try {
    // Get alarm data from shared preferences
    final prefs = await SharedPreferences.getInstance();
    final key = 'pending_voice_alarms_$alarmId';
    final data = prefs.getString(key);
    
    if (data != null) {
      final parts = data.split('|');
      if (parts.length >= 4) {
        final medicineName = parts[0];
        final dosage = int.tryParse(parts[1]) ?? 1;
        final dosageUnit = parts[2];
        final mealTime = parts[3];
        
        // Initialize TTS early to give it time to connect
        final tts = FlutterTts();
        final ttsInitFuture = _initializeTts(tts);
        
        // Show notification (this will wake the device)
        await _showWakeUpNotification(
          alarmId: alarmId,
          medicineName: medicineName,
          dosage: dosage,
          dosageUnit: dosageUnit,
          mealTime: mealTime,
        );
        
        // Wait for TTS to be initialized
        await ttsInitFuture;
        
        // Give the device a moment to fully wake up
        await Future.delayed(const Duration(seconds: 1));
        
        // Speak the reminder
        await _speakReminderWithTts(
          tts: tts,
          medicineName: medicineName,
          dosage: dosage,
          dosageUnit: dosageUnit,
          mealTime: mealTime,
        );
      }
    }
  } catch (e) {
    debugPrint('Error in alarm callback: $e');
  }
}

Future<void> _initializeTts(FlutterTts tts) async {
  try {
    await tts.setLanguage('en-IN');
    await tts.setSpeechRate(0.45);
    await tts.setVolume(1.0);
    await tts.setPitch(1.0);
    await tts.awaitSpeakCompletion(true);
    debugPrint('TTS initialized in background');
  } catch (e) {
    debugPrint('Error initializing TTS: $e');
  }
}

Future<void> _speakReminderWithTts({
  required FlutterTts tts,
  required String medicineName,
  required int dosage,
  required String dosageUnit,
  required String mealTime,
}) async {
  try {
    final unitText = dosage > 1 ? '${dosageUnit}s' : dosageUnit;
    final message = 'Medicine reminder. Time to take $dosage $unitText of $medicineName. $mealTime.';
    
    debugPrint('TTS Speaking (background): $message');
    
    // Speak the reminder
    await tts.speak(message);
    
    // Wait and repeat for emphasis
    await Future.delayed(const Duration(seconds: 4));
    await tts.speak('Please take your medicine now.');
    
  } catch (e) {
    debugPrint('Error speaking in background: $e');
  }
}

Future<void> _showWakeUpNotification({
  required int alarmId,
  required String medicineName,
  required int dosage,
  required String dosageUnit,
  required String mealTime,
}) async {
  final notifications = FlutterLocalNotificationsPlugin();
  
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await notifications.initialize(initSettings);
  
  final unitText = dosage > 1 ? '${dosageUnit}s' : dosageUnit;
  
  await notifications.show(
    alarmId,
    'Medicine Reminder 💊',
    'Time to take $dosage $unitText of $medicineName ($mealTime)',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'medicine_voice_alarms',
        'Medicine Voice Alarms',
        channelDescription: 'Medicine alarms with voice notification',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        visibility: NotificationVisibility.public,
        ongoing: true,
        autoCancel: false,
      ),
    ),
  );
}


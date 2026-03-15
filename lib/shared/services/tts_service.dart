import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _flutterTts.setLanguage('en-IN');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    // Set audio attributes for alarm-like behavior
    await _flutterTts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
      ],
      IosTextToSpeechAudioMode.voicePrompt,
    );

    _isInitialized = true;
    debugPrint('TTS Service initialized');
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    debugPrint('TTS Speaking: $text');
    await _flutterTts.speak(text);
  }

  Future<void> speakMedicineReminder({
    required String medicineName,
    required int dosage,
    required String dosageUnit,
    String? mealTime,
  }) async {
    final unitText = dosage > 1 ? '${dosageUnit}s' : dosageUnit;
    String message = 'Medicine reminder. Time to take $dosage $unitText of $medicineName.';
    
    if (mealTime != null) {
      message += ' $mealTime.';
    }
    
    await speak(message);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate.clamp(0.0, 1.0));
  }
}

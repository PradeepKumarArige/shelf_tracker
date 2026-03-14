import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum VoiceAssistantState {
  idle,
  listening,
  processing,
  speaking,
  error,
}

class VoiceCommand {
  final String type;
  final Map<String, dynamic> data;

  VoiceCommand({required this.type, this.data = const {}});
}

class VoiceAssistantService extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  VoiceAssistantState _state = VoiceAssistantState.idle;
  String _lastWords = '';
  String _errorMessage = '';
  bool _isAvailable = false;
  VoiceCommand? _lastCommand;

  VoiceAssistantState get state => _state;
  String get lastWords => _lastWords;
  String get errorMessage => _errorMessage;
  bool get isAvailable => _isAvailable;
  bool get isListening => _state == VoiceAssistantState.listening;
  VoiceCommand? get lastCommand => _lastCommand;

  Future<void> initialize() async {
    try {
      _isAvailable = await _speechToText.initialize(
        onError: (error) {
          _errorMessage = error.errorMsg;
          _state = VoiceAssistantState.error;
          notifyListeners();
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (_state == VoiceAssistantState.listening) {
              _processCommand();
            }
          }
        },
      );

      await _initializeTts();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to initialize voice assistant: $e';
      _isAvailable = false;
      notifyListeners();
    }
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      _state = VoiceAssistantState.speaking;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _state = VoiceAssistantState.idle;
      notifyListeners();
    });

    _flutterTts.setErrorHandler((error) {
      _errorMessage = error.toString();
      _state = VoiceAssistantState.error;
      notifyListeners();
    });
  }

  Future<void> startListening() async {
    if (!_isAvailable) {
      _errorMessage = 'Voice recognition not available';
      _state = VoiceAssistantState.error;
      notifyListeners();
      return;
    }

    _lastWords = '';
    _lastCommand = null;
    _state = VoiceAssistantState.listening;
    notifyListeners();

    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
      cancelOnError: true,
      partialResults: true,
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    _state = VoiceAssistantState.idle;
    notifyListeners();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    notifyListeners();

    if (result.finalResult) {
      _processCommand();
    }
  }

  void _processCommand() {
    if (_lastWords.isEmpty) {
      _state = VoiceAssistantState.idle;
      notifyListeners();
      return;
    }

    _state = VoiceAssistantState.processing;
    notifyListeners();

    final words = _lastWords.toLowerCase().trim();
    VoiceCommand? command;

    if (_matchesCommand(words, ['add item', 'add new item', 'new item', 'add product'])) {
      command = VoiceCommand(type: 'add_item');
    } else if (_matchesCommand(words, ['show expiring', 'expiring soon', 'what is expiring', "what's expiring"])) {
      command = VoiceCommand(type: 'show_expiring');
    } else if (_matchesCommand(words, ['show expired', 'expired items', 'what has expired', "what's expired"])) {
      command = VoiceCommand(type: 'show_expired');
    } else if (_matchesCommand(words, ['show analytics', 'analytics', 'show stats', 'statistics', 'show statistics'])) {
      command = VoiceCommand(type: 'show_analytics');
    } else if (_matchesCommand(words, ['show deals', 'deals', 'show offers', 'offers', 'discounts'])) {
      command = VoiceCommand(type: 'show_deals');
    } else if (_matchesCommand(words, ['go home', 'home', 'show home', 'dashboard', 'main screen'])) {
      command = VoiceCommand(type: 'go_home');
    } else if (_matchesCommand(words, ['show profile', 'profile', 'my profile', 'settings', 'show settings'])) {
      command = VoiceCommand(type: 'show_profile');
    } else if (words.startsWith('search') || words.startsWith('find') || words.startsWith('look for')) {
      String searchTerm = words
          .replaceFirst(RegExp(r'^(search for|search|find|look for)\s*'), '')
          .trim();
      if (searchTerm.isNotEmpty) {
        command = VoiceCommand(type: 'search', data: {'query': searchTerm});
      }
    } else if (_matchesCommand(words, ['help', 'what can you do', 'commands', 'show commands'])) {
      command = VoiceCommand(type: 'help');
    }

    _lastCommand = command;
    _state = VoiceAssistantState.idle;
    notifyListeners();
  }

  bool _matchesCommand(String input, List<String> patterns) {
    for (final pattern in patterns) {
      if (input.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    _state = VoiceAssistantState.speaking;
    notifyListeners();

    await _flutterTts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    _state = VoiceAssistantState.idle;
    notifyListeners();
  }

  void clearCommand() {
    _lastCommand = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    if (_state == VoiceAssistantState.error) {
      _state = VoiceAssistantState.idle;
    }
    notifyListeners();
  }

  String getHelpText() {
    return '''
You can say:
• "Add item" - Add a new item
• "Show expiring" - View items expiring soon
• "Show expired" - View expired items
• "Show analytics" - View analytics
• "Show deals" - View available deals
• "Go home" - Go to home screen
• "Show profile" - View your profile
• "Search [item name]" - Search for items
• "Help" - Show this help
''';
  }

  @override
  void dispose() {
    _speechToText.stop();
    _flutterTts.stop();
    super.dispose();
  }
}

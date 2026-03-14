import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

enum VoiceAssistantState {
  idle,
  listening,
  processing,
  speaking,
  error,
  permissionDenied,
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
  bool _isInitialized = false;
  VoiceCommand? _lastCommand;

  VoiceAssistantState get state => _state;
  String get lastWords => _lastWords;
  String get errorMessage => _errorMessage;
  bool get isAvailable => _isAvailable;
  bool get isListening => _state == VoiceAssistantState.listening;
  VoiceCommand? get lastCommand => _lastCommand;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _initializeTts();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to initialize text-to-speech: $e';
      notifyListeners();
    }
  }

  Future<bool> _requestPermissions() async {
    final micStatus = await Permission.microphone.status;
    
    if (micStatus.isGranted) {
      return true;
    }
    
    if (micStatus.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    
    if (micStatus.isPermanentlyDenied) {
      _errorMessage = 'Microphone permission permanently denied. Please enable it in Settings.';
      _state = VoiceAssistantState.permissionDenied;
      notifyListeners();
      return false;
    }
    
    return false;
  }

  Future<bool> _initializeSpeechRecognition() async {
    if (_isAvailable) return true;
    
    try {
      _isAvailable = await _speechToText.initialize(
        onError: (error) {
          _handleSpeechError(error.errorMsg);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (_state == VoiceAssistantState.listening) {
              _processCommand();
            }
          }
        },
      );
      
      if (!_isAvailable) {
        _errorMessage = 'Speech recognition not supported on this device';
      }
      
      return _isAvailable;
    } catch (e) {
      _errorMessage = 'Failed to initialize speech recognition: $e';
      _isAvailable = false;
      return false;
    }
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(0.7);
    await _flutterTts.setPitch(1.05);

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
    _errorMessage = '';
    
    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      if (_state != VoiceAssistantState.permissionDenied) {
        _errorMessage = 'Microphone permission required for voice commands';
        _state = VoiceAssistantState.error;
      }
      notifyListeners();
      return;
    }

    final initialized = await _initializeSpeechRecognition();
    if (!initialized) {
      _state = VoiceAssistantState.error;
      notifyListeners();
      return;
    }

    _lastWords = '';
    _lastCommand = null;
    _state = VoiceAssistantState.listening;
    notifyListeners();

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
        cancelOnError: true,
        partialResults: true,
      );
    } catch (e) {
      _errorMessage = 'Failed to start listening: $e';
      _state = VoiceAssistantState.error;
      notifyListeners();
    }
  }

  Future<void> openSettings() async {
    await openAppSettings();
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

    if (_matchesCommand(words, ['add item', 'add new item', 'new item', 'add product']) && 
        !_hasItemDetails(words)) {
      command = VoiceCommand(type: 'add_item');
    } else if (_startsWithAddCommand(words)) {
      final itemData = _parseAddItemCommand(words);
      if (itemData != null) {
        command = VoiceCommand(type: 'add_item_voice', data: itemData);
      }
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

  void _handleSpeechError(String errorMsg) {
    final errorLower = errorMsg.toLowerCase();
    
    if (errorLower.contains('no_match') || errorLower.contains('no match')) {
      _lastWords = '';
      _errorMessage = '';
      _state = VoiceAssistantState.idle;
      _lastCommand = VoiceCommand(type: 'no_speech');
      notifyListeners();
      return;
    }
    
    if (errorLower.contains('speech_timeout') || errorLower.contains('timeout')) {
      _lastWords = '';
      _errorMessage = '';
      _state = VoiceAssistantState.idle;
      _lastCommand = VoiceCommand(type: 'timeout');
      notifyListeners();
      return;
    }
    
    if (errorLower.contains('network')) {
      _errorMessage = 'Network error. Please check your connection.';
      _state = VoiceAssistantState.error;
      notifyListeners();
      return;
    }
    
    if (errorLower.contains('busy') || errorLower.contains('unavailable')) {
      _errorMessage = 'Voice service busy. Please try again.';
      _state = VoiceAssistantState.error;
      notifyListeners();
      return;
    }
    
    _errorMessage = errorMsg;
    _state = VoiceAssistantState.error;
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

  bool _hasItemDetails(String input) {
    final addPrefixes = ['add item ', 'add new item ', 'new item ', 'add product ', 'add '];
    for (final prefix in addPrefixes) {
      if (input.startsWith(prefix)) {
        final remainder = input.substring(prefix.length).trim();
        if (remainder.isNotEmpty && !_matchesCommand(remainder, ['item', 'new', 'product'])) {
          return true;
        }
      }
    }
    return false;
  }

  bool _startsWithAddCommand(String input) {
    return input.startsWith('add ');
  }

  Map<String, dynamic>? _parseAddItemCommand(String input) {
    String text = input
        .replaceFirst(RegExp(r'^add (new )?(item |product )?'), '')
        .trim();
    
    if (text.isEmpty) return null;

    final result = <String, dynamic>{};
    
    String? category = _extractCategory(text);
    if (category != null) {
      result['category'] = category;
      text = _removeCategoryFromText(text, category);
    }
    
    final expiryData = _extractExpiryInfo(text);
    if (expiryData != null) {
      result['expiryDays'] = expiryData['days'];
      text = expiryData['remainingText'] as String;
    }
    
    final quantity = _extractQuantity(text);
    if (quantity != null) {
      result['quantity'] = quantity['quantity'];
      text = quantity['remainingText'] as String;
    }
    
    final location = _extractLocation(text);
    if (location != null) {
      result['location'] = location['location'];
      text = location['remainingText'] as String;
    }
    
    text = text.trim();
    if (text.isNotEmpty) {
      result['name'] = _capitalizeWords(text);
    }
    
    return result.isEmpty ? null : result;
  }

  String? _extractCategory(String text) {
    final categories = {
      'food': ['food', 'food category', 'food item'],
      'grocery': ['grocery', 'grocery category', 'groceries'],
      'medicine': ['medicine', 'medicine category', 'medical', 'medication'],
      'cosmetics': ['cosmetics', 'cosmetic', 'cosmetics category', 'beauty'],
    };
    
    for (final entry in categories.entries) {
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  String _removeCategoryFromText(String text, String category) {
    final patterns = [
      '$category category',
      'category $category',
      category,
      'food item',
      'groceries',
      'medical',
      'medication',
      'beauty',
      'cosmetic',
    ];
    
    for (final pattern in patterns) {
      text = text.replaceAll(pattern, '');
    }
    return text.trim();
  }

  Map<String, dynamic>? _extractExpiryInfo(String text) {
    final patterns = [
      RegExp(r'expir(?:ing|es?) in (\d+) days?'),
      RegExp(r'expires? (\d+) days?'),
      RegExp(r'(\d+) days? (?:until )?expir'),
      RegExp(r'expir(?:ing|es?) tomorrow'),
      RegExp(r'expir(?:ing|es?) today'),
      RegExp(r'expir(?:ing|es?) in (\d+) weeks?'),
      RegExp(r'expir(?:ing|es?) in (\d+) months?'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        int days = 7;
        
        if (text.contains('tomorrow')) {
          days = 1;
        } else if (text.contains('today')) {
          days = 0;
        } else if (match.groupCount >= 1) {
          final number = int.tryParse(match.group(1) ?? '');
          if (number != null) {
            if (text.contains('week')) {
              days = number * 7;
            } else if (text.contains('month')) {
              days = number * 30;
            } else {
              days = number;
            }
          }
        }
        
        return {
          'days': days,
          'remainingText': text.replaceAll(match.group(0)!, '').trim(),
        };
      }
    }
    return null;
  }

  Map<String, dynamic>? _extractQuantity(String text) {
    final patterns = [
      RegExp(r'quantity (\d+)'),
      RegExp(r'(\d+) (?:pieces?|items?|units?)'),
      RegExp(r'(\d+) of'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final quantity = int.tryParse(match.group(1) ?? '');
        if (quantity != null && quantity > 0) {
          return {
            'quantity': quantity,
            'remainingText': text.replaceAll(match.group(0)!, '').trim(),
          };
        }
      }
    }
    return null;
  }

  Map<String, dynamic>? _extractLocation(String text) {
    final patterns = [
      RegExp(r'(?:in|at|store in|stored in) (?:the )?(refrigerator|fridge|freezer|pantry|cabinet|shelf|drawer|kitchen|bathroom)'),
      RegExp(r'location (refrigerator|fridge|freezer|pantry|cabinet|shelf|drawer|kitchen|bathroom)'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        String location = match.group(1) ?? '';
        if (location == 'fridge') location = 'Refrigerator';
        return {
          'location': _capitalizeWords(location),
          'remainingText': text.replaceAll(match.group(0)!, '').trim(),
        };
      }
    }
    return null;
  }

  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
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
• "Add item" - Open add item screen
• "Add [item name]" - Quick add item
• "Add milk expiring in 5 days"
• "Add eggs food category"
• "Add aspirin medicine in refrigerator"
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

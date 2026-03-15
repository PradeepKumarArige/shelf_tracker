import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:uuid/uuid.dart';
import '../models/item_model.dart';

class ScannedItem {
  String id;
  String name;
  int quantity;
  ItemCategory category;
  DateTime expiryDate;
  bool isSelected;

  ScannedItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.category = ItemCategory.grocery,
    DateTime? expiryDate,
    this.isSelected = true,
  }) : expiryDate = expiryDate ?? DateTime.now().add(const Duration(days: 30));

  ItemModel toItemModel() {
    return ItemModel(
      id: const Uuid().v4(),
      name: name,
      category: category,
      purchaseDate: DateTime.now(),
      expiryDate: expiryDate,
      quantity: quantity,
      location: null,
      notes: 'Added from receipt scan',
    );
  }
}

class ReceiptScannerService extends ChangeNotifier {
  final ImagePicker _imagePicker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  List<ScannedItem> _scannedItems = [];
  String _rawText = '';
  bool _isProcessing = false;
  String? _error;
  File? _selectedImage;

  List<ScannedItem> get scannedItems => _scannedItems;
  String get rawText => _rawText;
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  File? get selectedImage => _selectedImage;

  int get selectedCount => _scannedItems.where((item) => item.isSelected).length;

  Future<bool> captureReceipt(BuildContext context) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );

      if (image == null) return false;

      final croppedFile = await _cropImage(image.path, context);
      if (croppedFile == null) return false;

      _selectedImage = File(croppedFile.path);
      notifyListeners();

      return await _processImage(_selectedImage!);
    } catch (e) {
      _error = 'Failed to capture image: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> pickReceiptFromGallery(BuildContext context) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );

      if (image == null) return false;

      final croppedFile = await _cropImage(image.path, context);
      if (croppedFile == null) return false;

      _selectedImage = File(croppedFile.path);
      notifyListeners();

      return await _processImage(_selectedImage!);
    } catch (e) {
      _error = 'Failed to pick image: $e';
      notifyListeners();
      return false;
    }
  }

  Future<CroppedFile?> _cropImage(String imagePath, BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return await ImageCropper().cropImage(
      sourcePath: imagePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Receipt',
          toolbarColor: colorScheme.primary,
          toolbarWidgetColor: colorScheme.onPrimary,
          activeControlsWidgetColor: colorScheme.primary,
          backgroundColor: colorScheme.surface,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Crop Receipt',
          doneButtonTitle: 'Done',
          cancelButtonTitle: 'Cancel',
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,
          aspectRatioPickerButtonHidden: false,
          rotateButtonsHidden: false,
          rotateClockwiseButtonHidden: true,
        ),
      ],
    );
  }

  Future<bool> _processImage(File imageFile) async {
    _isProcessing = true;
    _error = null;
    _scannedItems = [];
    notifyListeners();

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      _rawText = recognizedText.text;
      _scannedItems = _parseReceiptText(recognizedText);

      _isProcessing = false;
      notifyListeners();
      return _scannedItems.isNotEmpty;
    } catch (e) {
      _error = 'Failed to process receipt: $e';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  List<ScannedItem> _parseReceiptText(RecognizedText recognizedText) {
    final List<ScannedItem> items = [];
    final Set<String> addedNames = {};

    final List<String> skipWords = [
      'total', 'subtotal', 'grand', 'net',
      'tax', 'vat', 'gst', 'cgst', 'sgst',
      'cash', 'card', 'change', 'balance', 'tender', 'paid',
      'thank', 'thanks', 'receipt', 'invoice',
      'welcome', 'visit', 'again',
      'cashier', 'counter', 'terminal',
      'gstin', 'fssai',
      'www', 'http',
    ];

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        String text = line.text.trim();

        if (text.length < 3) continue;
        if (RegExp(r'^[\d\s\.\,\-\+\*\/\=\:\;\$\₹\%\@\#\(\)]+$').hasMatch(text)) continue;
        if (RegExp(r'^\d{2}[\/\-]\d{2}[\/\-]\d{2,4}').hasMatch(text)) continue;
        if (RegExp(r'^\d{1,2}:\d{2}').hasMatch(text)) continue;

        final lowerText = text.toLowerCase();
        
        bool shouldSkip = false;
        for (final word in skipWords) {
          if (lowerText == word || lowerText.startsWith('$word ') || lowerText.startsWith('$word:')) {
            shouldSkip = true;
            break;
          }
        }
        if (shouldSkip) continue;
        if (lowerText.contains('total') && RegExp(r'\d').hasMatch(text)) continue;

        final parsed = _parseLineForItem(text);
        if (parsed != null) {
          final name = parsed['name'] as String;
          final normalizedName = name.toLowerCase().trim();
          
          if (name.length >= 2 && !addedNames.contains(normalizedName)) {
            if (!_isNonProductText(name)) {
              addedNames.add(normalizedName);
              items.add(ScannedItem(
                id: const Uuid().v4(),
                name: name,
                quantity: parsed['quantity'] ?? 1,
                category: _guessCategory(name),
              ));
            }
          }
        }
      }
    }

    return items;
  }

  bool _isNonProductText(String name) {
    final lowerName = name.toLowerCase();
    
    final nonProductPatterns = [
      'thank', 'welcome', 'visit', 'come again',
      'cashier', 'counter', 'terminal', 'pos',
      'address', 'phone', 'mobile', 'email',
      'gstin', 'fssai', 'license',
      'payment', 'paid', 'change', 'balance',
    ];
    
    for (final pattern in nonProductPatterns) {
      if (lowerName.contains(pattern)) return true;
    }
    
    if (RegExp(r'^\d{10,}$').hasMatch(name.replaceAll(' ', ''))) return true;
    
    return false;
  }

  Map<String, dynamic>? _parseLineForItem(String text) {
    text = text.replaceAll(RegExp(r'[^\w\s\d\.\,\-]'), ' ').trim();
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    final qtyAtStart = RegExp(r'^(\d{1,2})\s*[xX\*]?\s+(.+)').firstMatch(text);
    if (qtyAtStart != null) {
      final qty = int.tryParse(qtyAtStart.group(1)!) ?? 1;
      if (qty > 0 && qty <= 50) {
        final rest = qtyAtStart.group(2)!;
        final name = _cleanItemName(rest);
        if (name.isNotEmpty) {
          return {'name': name, 'quantity': qty};
        }
      }
    }

    final itemWithPrice = RegExp(r'^(.+?)\s+[\d\.\,]{1,10}$').firstMatch(text);
    if (itemWithPrice != null) {
      final name = _cleanItemName(itemWithPrice.group(1)!);
      if (name.isNotEmpty) {
        final qtyInName = RegExp(r'^(\d{1,2})\s*[xX\*]?\s+(.+)').firstMatch(name);
        if (qtyInName != null) {
          final qty = int.tryParse(qtyInName.group(1)!) ?? 1;
          final cleanName = _cleanItemName(qtyInName.group(2)!);
          if (cleanName.isNotEmpty && qty > 0 && qty <= 50) {
            return {'name': cleanName, 'quantity': qty};
          }
        }
        return {'name': name, 'quantity': 1};
      }
    }

    final multiPrice = RegExp(r'^(.+?)\s+(\d{1,2})\s*[xX\*@]\s*[\d\.\,]+').firstMatch(text);
    if (multiPrice != null) {
      final name = _cleanItemName(multiPrice.group(1)!);
      final qty = int.tryParse(multiPrice.group(2)!) ?? 1;
      if (name.isNotEmpty && qty > 0 && qty <= 50) {
        return {'name': name, 'quantity': qty};
      }
    }

    final cleanedText = _cleanItemName(text);
    if (cleanedText.isNotEmpty && cleanedText.length >= 2) {
      if (RegExp(r'[a-zA-Z]{2,}').hasMatch(cleanedText)) {
        return {'name': cleanedText, 'quantity': 1};
      }
    }

    return null;
  }

  String _cleanItemName(String name) {
    name = name.replaceAll(RegExp(r'[\d\.\,]+\s*$'), '').trim();
    
    name = name.replaceAll(RegExp(r'^\d+\s*[xX\*@]?\s*'), '').trim();
    
    name = name.replaceAll(RegExp(r'\s+'), ' ');
    
    name = name.replaceAll(RegExp(r'^[^a-zA-Z]+'), '');
    name = name.replaceAll(RegExp(r'[^a-zA-Z0-9\s\-]+$'), '');

    if (name.length > 50) {
      name = name.substring(0, 50);
    }

    final words = name.split(' ').where((w) => w.isNotEmpty).toList();
    final capitalizedWords = words.map((word) {
      if (word.isEmpty) return word;
      if (RegExp(r'^\d').hasMatch(word)) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).toList();

    return capitalizedWords.join(' ').trim();
  }

  ItemCategory _guessCategory(String name) {
    final lowerName = name.toLowerCase();

    final foodKeywords = [
      'milk', 'bread', 'egg', 'cheese', 'butter', 'yogurt', 'cream',
      'chicken', 'meat', 'fish', 'beef', 'pork', 'lamb', 'bacon',
      'fruit', 'apple', 'banana', 'orange', 'grape', 'mango', 'berry',
      'vegetable', 'tomato', 'potato', 'onion', 'carrot', 'lettuce',
      'rice', 'pasta', 'noodle', 'cereal', 'oat', 'flour', 'sugar',
      'juice', 'soda', 'water', 'coffee', 'tea', 'drink',
      'pizza', 'burger', 'sandwich', 'wrap', 'salad', 'soup',
      'cake', 'cookie', 'biscuit', 'chocolate', 'candy', 'ice cream',
      'sauce', 'ketchup', 'mayo', 'mustard', 'oil', 'vinegar',
      'snack', 'chip', 'crisp', 'popcorn', 'nut', 'almond',
      'paneer', 'dal', 'ghee', 'curd', 'lassi', 'roti', 'paratha',
    ];

    final medicineKeywords = [
      'tablet', 'capsule', 'syrup', 'medicine', 'drug', 'pill',
      'vitamin', 'supplement', 'paracetamol', 'aspirin', 'antibiotic',
      'cream', 'ointment', 'drops', 'spray', 'inhaler', 'bandage',
      'painkiller', 'cough', 'cold', 'fever', 'allergy', 'antacid',
    ];

    final cosmeticsKeywords = [
      'shampoo', 'conditioner', 'soap', 'body wash', 'lotion',
      'moisturizer', 'sunscreen', 'lipstick', 'mascara', 'foundation',
      'perfume', 'deodorant', 'face wash', 'cleanser', 'toner',
      'serum', 'mask', 'scrub', 'nail polish', 'makeup', 'cosmetic',
      'hair oil', 'gel', 'cream', 'fairness', 'beauty',
    ];

    for (String keyword in medicineKeywords) {
      if (lowerName.contains(keyword)) return ItemCategory.medicine;
    }

    for (String keyword in cosmeticsKeywords) {
      if (lowerName.contains(keyword)) return ItemCategory.cosmetics;
    }

    for (String keyword in foodKeywords) {
      if (lowerName.contains(keyword)) return ItemCategory.food;
    }

    return ItemCategory.grocery;
  }

  void toggleItemSelection(String id) {
    final index = _scannedItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      _scannedItems[index].isSelected = !_scannedItems[index].isSelected;
      notifyListeners();
    }
  }

  void selectAllItems() {
    for (var item in _scannedItems) {
      item.isSelected = true;
    }
    notifyListeners();
  }

  void deselectAllItems() {
    for (var item in _scannedItems) {
      item.isSelected = false;
    }
    notifyListeners();
  }

  void updateItemName(String id, String newName) {
    final index = _scannedItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      _scannedItems[index].name = newName;
      notifyListeners();
    }
  }

  void updateItemQuantity(String id, int quantity) {
    final index = _scannedItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      _scannedItems[index].quantity = quantity;
      notifyListeners();
    }
  }

  void updateItemCategory(String id, ItemCategory category) {
    final index = _scannedItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      _scannedItems[index].category = category;
      notifyListeners();
    }
  }

  void updateItemExpiry(String id, DateTime expiryDate) {
    final index = _scannedItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      _scannedItems[index].expiryDate = expiryDate;
      notifyListeners();
    }
  }

  void removeItem(String id) {
    _scannedItems.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void addManualItem(String name) {
    _scannedItems.add(ScannedItem(
      id: const Uuid().v4(),
      name: name,
      category: _guessCategory(name),
    ));
    notifyListeners();
  }

  List<ItemModel> getSelectedItemModels() {
    return _scannedItems
        .where((item) => item.isSelected)
        .map((item) => item.toItemModel())
        .toList();
  }

  void clearAll() {
    _scannedItems = [];
    _rawText = '';
    _error = null;
    _selectedImage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }
}

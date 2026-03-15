import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<bool> captureReceipt() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (image == null) return false;

      _selectedImage = File(image.path);
      notifyListeners();

      return await _processImage(_selectedImage!);
    } catch (e) {
      _error = 'Failed to capture image: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> pickReceiptFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (image == null) return false;

      _selectedImage = File(image.path);
      notifyListeners();

      return await _processImage(_selectedImage!);
    } catch (e) {
      _error = 'Failed to pick image: $e';
      notifyListeners();
      return false;
    }
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

    final List<String> skipPatterns = [
      'total', 'subtotal', 'tax', 'cash', 'card', 'change', 'balance',
      'thank', 'receipt', 'date', 'time', 'store', 'address', 'phone',
      'qty', 'price', 'amount', 'discount', 'savings', 'payment',
      'visa', 'mastercard', 'debit', 'credit', 'transaction',
      'welcome', 'visit', 'again', 'gst', 'cgst', 'sgst', 'igst',
      'invoice', 'bill', 'no.', 'sr.', 'sl.', '#', 'mrp', 'rate',
    ];

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        String text = line.text.trim();

        if (text.length < 3) continue;
        if (RegExp(r'^[\d\s\.\,\-\+\*\/\=\:\;\$\₹\%]+$').hasMatch(text)) continue;

        final lowerText = text.toLowerCase();
        bool shouldSkip = skipPatterns.any((pattern) => lowerText.contains(pattern));
        if (shouldSkip) continue;

        final parsed = _parseLineForItem(text);
        if (parsed != null) {
          final normalizedName = parsed['name']!.toLowerCase();
          if (!addedNames.contains(normalizedName) && parsed['name']!.length >= 3) {
            addedNames.add(normalizedName);
            items.add(ScannedItem(
              id: const Uuid().v4(),
              name: parsed['name']!,
              quantity: parsed['quantity'] ?? 1,
              category: _guessCategory(parsed['name']!),
            ));
          }
        }
      }
    }

    return items;
  }

  Map<String, dynamic>? _parseLineForItem(String text) {
    text = text.replaceAll(RegExp(r'[^\w\s\d\.\,]'), ' ').trim();

    final quantityMatch = RegExp(r'^(\d+)\s*[xX\*]?\s*(.+)').firstMatch(text);
    if (quantityMatch != null) {
      final qty = int.tryParse(quantityMatch.group(1)!) ?? 1;
      final name = _cleanItemName(quantityMatch.group(2)!);
      if (name.isNotEmpty) {
        return {'name': name, 'quantity': qty};
      }
    }

    final priceMatch = RegExp(r'^(.+?)\s+[\d\.\,]+\s*$').firstMatch(text);
    if (priceMatch != null) {
      final name = _cleanItemName(priceMatch.group(1)!);
      if (name.isNotEmpty) {
        return {'name': name, 'quantity': 1};
      }
    }

    final cleanedName = _cleanItemName(text);
    if (cleanedName.isNotEmpty && cleanedName.length >= 3) {
      return {'name': cleanedName, 'quantity': 1};
    }

    return null;
  }

  String _cleanItemName(String name) {
    name = name.replaceAll(RegExp(r'\d+[\.\,]?\d*\s*$'), '').trim();
    name = name.replaceAll(RegExp(r'^\d+\s*'), '').trim();
    name = name.replaceAll(RegExp(r'\s+'), ' ');

    if (name.length > 50) {
      name = name.substring(0, 50);
    }

    final words = name.split(' ');
    final capitalizedWords = words.map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).toList();

    return capitalizedWords.join(' ');
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

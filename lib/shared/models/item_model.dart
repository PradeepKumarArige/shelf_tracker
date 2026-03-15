import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum ItemCategory { food, grocery, medicine, cosmetics }

enum ItemStatus { fresh, warning, expired, used }

class ItemModel {
  final String id;
  final String name;
  final ItemCategory category;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final int quantity;
  final String? location;
  final String? notes;
  final String? barcode;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.purchaseDate,
    required this.expiryDate,
    this.quantity = 1,
    this.location,
    this.notes,
    this.barcode,
    this.isDeleted = false,
    this.deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  ItemStatus get status {
    final now = DateTime.now();
    final daysUntilExpiry = expiryDate.difference(now).inDays;

    if (daysUntilExpiry < 0) return ItemStatus.expired;
    if (daysUntilExpiry <= 7) return ItemStatus.warning;
    return ItemStatus.fresh;
  }

  int get daysRemaining {
    return expiryDate.difference(DateTime.now()).inDays;
  }

  Color getCategoryColor(bool isDark) {
    switch (category) {
      case ItemCategory.food:
        return isDark ? AppColors.foodDark : AppColors.foodLight;
      case ItemCategory.grocery:
        return isDark ? AppColors.groceryDark : AppColors.groceryLight;
      case ItemCategory.medicine:
        return isDark ? AppColors.medicineDark : AppColors.medicineLight;
      case ItemCategory.cosmetics:
        return isDark ? AppColors.cosmeticsDark : AppColors.cosmeticsLight;
    }
  }

  Color getStatusColor(bool isDark) {
    switch (status) {
      case ItemStatus.fresh:
        return isDark ? AppColors.freshDark : AppColors.freshLight;
      case ItemStatus.warning:
        return isDark ? AppColors.warningDark : AppColors.warningLight;
      case ItemStatus.expired:
        return isDark ? AppColors.expiredDark : AppColors.expiredLight;
      case ItemStatus.used:
        return isDark ? AppColors.usedDark : AppColors.usedLight;
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case ItemCategory.food:
        return Icons.restaurant_rounded;
      case ItemCategory.grocery:
        return Icons.shopping_basket_rounded;
      case ItemCategory.medicine:
        return Icons.medical_services_rounded;
      case ItemCategory.cosmetics:
        return Icons.face_rounded;
    }
  }

  String get categoryName {
    switch (category) {
      case ItemCategory.food:
        return 'Food';
      case ItemCategory.grocery:
        return 'Grocery';
      case ItemCategory.medicine:
        return 'Medicine';
      case ItemCategory.cosmetics:
        return 'Cosmetics';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.index,
      'purchaseDate': purchaseDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'quantity': quantity,
      'location': location,
      'notes': notes,
      'barcode': barcode,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id'],
      name: map['name'],
      category: ItemCategory.values[map['category']],
      purchaseDate: DateTime.parse(map['purchaseDate']),
      expiryDate: DateTime.parse(map['expiryDate']),
      quantity: map['quantity'] ?? 1,
      location: map['location'],
      notes: map['notes'],
      barcode: map['barcode'],
      isDeleted: map['isDeleted'] == true || map['isDeleted'] == 1,
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt']) : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  ItemModel copyWith({
    String? id,
    String? name,
    ItemCategory? category,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    int? quantity,
    String? location,
    String? notes,
    String? barcode,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return ItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      quantity: quantity ?? this.quantity,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      barcode: barcode ?? this.barcode,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

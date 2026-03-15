import 'package:flutter/material.dart';

enum MealTime {
  morning,
  lunch,
  dinner,
}

enum MedicineTime {
  before,
  after,
}

class MedicineSchedule {
  final MealTime mealTime;
  final MedicineTime medicineTime;
  final TimeOfDay time;
  final bool isEnabled;

  MedicineSchedule({
    required this.mealTime,
    required this.medicineTime,
    required this.time,
    this.isEnabled = true,
  });

  String get label {
    final mealLabel = mealTime == MealTime.morning
        ? 'Morning'
        : mealTime == MealTime.lunch
            ? 'Lunch'
            : 'Dinner';
    final timeLabel = medicineTime == MedicineTime.before ? 'Before' : 'After';
    return '$timeLabel $mealLabel';
  }

  IconData get icon {
    switch (mealTime) {
      case MealTime.morning:
        return Icons.wb_sunny_rounded;
      case MealTime.lunch:
        return Icons.lunch_dining_rounded;
      case MealTime.dinner:
        return Icons.nightlight_round;
    }
  }

  String get timeString {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Map<String, dynamic> toMap() {
    return {
      'meal_time': mealTime.index,
      'medicine_time': medicineTime.index,
      'hour': time.hour,
      'minute': time.minute,
      'is_enabled': isEnabled ? 1 : 0,
    };
  }

  factory MedicineSchedule.fromMap(Map<String, dynamic> map) {
    return MedicineSchedule(
      mealTime: MealTime.values[map['meal_time'] as int],
      medicineTime: MedicineTime.values[map['medicine_time'] as int],
      time: TimeOfDay(
        hour: map['hour'] as int,
        minute: map['minute'] as int,
      ),
      isEnabled: (map['is_enabled'] as int) == 1,
    );
  }

  MedicineSchedule copyWith({
    MealTime? mealTime,
    MedicineTime? medicineTime,
    TimeOfDay? time,
    bool? isEnabled,
  }) {
    return MedicineSchedule(
      mealTime: mealTime ?? this.mealTime,
      medicineTime: medicineTime ?? this.medicineTime,
      time: time ?? this.time,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

class MedicineReminder {
  final String id;
  final String itemId;
  final String itemName;
  final int dosage;
  final String dosageUnit;
  final List<MedicineSchedule> schedules;
  final DateTime createdAt;
  final bool isActive;

  MedicineReminder({
    required this.id,
    required this.itemId,
    required this.itemName,
    this.dosage = 1,
    this.dosageUnit = 'tablet',
    required this.schedules,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'item_name': itemName,
      'dosage': dosage,
      'dosage_unit': dosageUnit,
      'schedules': schedules.map((s) => s.toMap()).toList(),
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory MedicineReminder.fromMap(Map<String, dynamic> map) {
    return MedicineReminder(
      id: map['id'] as String,
      itemId: map['item_id'] as String,
      itemName: map['item_name'] as String,
      dosage: map['dosage'] as int? ?? 1,
      dosageUnit: map['dosage_unit'] as String? ?? 'tablet',
      schedules: (map['schedules'] as List)
          .map((s) => MedicineSchedule.fromMap(s as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(map['created_at'] as String),
      isActive: (map['is_active'] as int?) == 1,
    );
  }

  MedicineReminder copyWith({
    String? id,
    String? itemId,
    String? itemName,
    int? dosage,
    String? dosageUnit,
    List<MedicineSchedule>? schedules,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return MedicineReminder(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      dosage: dosage ?? this.dosage,
      dosageUnit: dosageUnit ?? this.dosageUnit,
      schedules: schedules ?? this.schedules,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

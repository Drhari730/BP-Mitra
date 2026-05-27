// Models for Module 2 – DASH Diet Engine.
// DashFoodItem mirrors the local JSON asset; FoodLogEntry mirrors the API.

import 'package:equatable/equatable.dart';

// ── Meal Slot Enum ──────────────────────────────────────────────────────
enum MealSlot { breakfast, lunch, dinner, snack }

extension MealSlotExtension on MealSlot {
  String get label {
    switch (this) {
      case MealSlot.breakfast: return 'Breakfast';
      case MealSlot.lunch:     return 'Lunch';
      case MealSlot.dinner:    return 'Dinner';
      case MealSlot.snack:     return 'Snack';
    }
  }
  String get apiValue => name;

  static MealSlot fromString(String value) =>
      MealSlot.values.firstWhere((e) => e.name == value, orElse: () => MealSlot.snack);
}

// ── DASH Food Item (local asset model) ─────────────────────────────────
// Mirrors dash_diet_db.json structure for clinical nutritional data.
class DashFoodItem extends Equatable {
  final String key;               // unique identifier used as food_item_key in logs
  final String name;
  final String nameTransliterated; // Tamil/Kannada phonetic name for UI display
  final MealSlot suggestedSlot;
  final double servingSizeG;
  final double sodiumMg;          // per serving; DASH cap driver
  final double potassiumMg;
  final double magnesiumMg;
  final double caloriesKcal;
  final String category;          // grains | protein | vegetable | dairy | beverage
  final bool isDashOptimal;       // Pre-screened compliant item
  final String preparationNote;   // Clinical tip for DASH-safe preparation

  const DashFoodItem({
    required this.key,
    required this.name,
    required this.nameTransliterated,
    required this.suggestedSlot,
    required this.servingSizeG,
    required this.sodiumMg,
    required this.potassiumMg,
    required this.magnesiumMg,
    required this.caloriesKcal,
    required this.category,
    required this.isDashOptimal,
    required this.preparationNote,
  });

  factory DashFoodItem.fromJson(Map<String, dynamic> json) {
    return DashFoodItem(
      key: json['key'] as String,
      name: json['name'] as String,
      nameTransliterated: json['name_transliterated'] as String? ?? '',
      suggestedSlot: MealSlotExtension.fromString(json['suggested_slot'] as String? ?? 'snack'),
      servingSizeG: (json['serving_size_g'] as num).toDouble(),
      sodiumMg: (json['sodium_mg'] as num).toDouble(),
      potassiumMg: (json['potassium_mg'] as num).toDouble(),
      magnesiumMg: (json['magnesium_mg'] as num? ?? 0).toDouble(),
      caloriesKcal: (json['calories_kcal'] as num).toDouble(),
      category: json['category'] as String? ?? 'other',
      isDashOptimal: json['is_dash_optimal'] as bool? ?? false,
      preparationNote: json['preparation_note'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [key, name, sodiumMg, potassiumMg];
}

// ── Food Log Entry (API model) ──────────────────────────────────────────
class FoodLogEntry extends Equatable {
  final String id;
  final String userId;
  final DateTime logDate;
  final MealSlot mealSlot;
  final String foodItemKey;
  final String foodName;
  final double servingSizeG;
  final double sodiumMg;
  final double potassiumMg;
  final double magnesiumMg;
  final double caloriesKcal;
  final DateTime createdAt;

  const FoodLogEntry({
    required this.id,
    required this.userId,
    required this.logDate,
    required this.mealSlot,
    required this.foodItemKey,
    required this.foodName,
    required this.servingSizeG,
    required this.sodiumMg,
    required this.potassiumMg,
    required this.magnesiumMg,
    required this.caloriesKcal,
    required this.createdAt,
  });

  factory FoodLogEntry.fromJson(Map<String, dynamic> json) {
    return FoodLogEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      logDate: DateTime.parse(json['log_date'] as String),
      mealSlot: MealSlotExtension.fromString(json['meal_slot'] as String),
      foodItemKey: json['food_item_key'] as String,
      foodName: json['food_name'] as String,
      servingSizeG: (json['serving_size_g'] as num).toDouble(),
      sodiumMg: (json['sodium_mg'] as num).toDouble(),
      potassiumMg: (json['potassium_mg'] as num? ?? 0).toDouble(),
      magnesiumMg: (json['magnesium_mg'] as num? ?? 0).toDouble(),
      caloriesKcal: (json['calories_kcal'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, foodItemKey, mealSlot, logDate];
}

// ── Daily Sodium Summary ────────────────────────────────────────────────
class DailySodiumSummary extends Equatable {
  static const double dailyCapMg = 1500.0;

  final String date;
  final double totalSodiumMg;
  final double totalPotassiumMg;
  final double totalCaloriesKcal;
  final int itemCount;
  final double progressFraction;   // 0.0 – 1.0
  final bool isOverLimit;
  final double remainingMg;

  const DailySodiumSummary({
    required this.date,
    required this.totalSodiumMg,
    required this.totalPotassiumMg,
    required this.totalCaloriesKcal,
    required this.itemCount,
    required this.progressFraction,
    required this.isOverLimit,
    required this.remainingMg,
  });

  factory DailySodiumSummary.empty(String date) => DailySodiumSummary(
    date: date,
    totalSodiumMg: 0,
    totalPotassiumMg: 0,
    totalCaloriesKcal: 0,
    itemCount: 0,
    progressFraction: 0,
    isOverLimit: false,
    remainingMg: dailyCapMg,
  );

  factory DailySodiumSummary.fromJson(Map<String, dynamic> json) {
    return DailySodiumSummary(
      date: json['date'] as String,
      totalSodiumMg: (json['total_sodium_mg'] as num).toDouble(),
      totalPotassiumMg: (json['total_potassium_mg'] as num).toDouble(),
      totalCaloriesKcal: (json['total_calories_kcal'] as num).toDouble(),
      itemCount: json['item_count'] as int? ?? 0,
      progressFraction: (json['progress_fraction'] as num).toDouble(),
      isOverLimit: json['is_over_limit'] as bool? ?? false,
      remainingMg: (json['remaining_mg'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [date, totalSodiumMg, progressFraction];
}

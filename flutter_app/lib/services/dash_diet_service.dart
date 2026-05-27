// Module 2 – DASH Diet Local Asset Service
// Loads the clinical South Indian food database from the bundled JSON asset
// and provides lookup helpers for the diet logging UI.

// packages: flutter (rootBundle)

import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/diet_model.dart';

class DashDietService {
  DashDietService._();
  static final DashDietService instance = DashDietService._();

  List<DashFoodItem>? _cachedItems;

  // ── Load All Items ────────────────────────────────────────────────────
  Future<List<DashFoodItem>> loadAllItems() async {
    if (_cachedItems != null) return _cachedItems!;

    final raw = await rootBundle.loadString('assets/data/dash_diet_db.json');
    final List<dynamic> json = jsonDecode(raw) as List;
    _cachedItems = json
        .map((e) => DashFoodItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cachedItems!;
  }

  // ── Filter by Meal Slot ───────────────────────────────────────────────
  Future<List<DashFoodItem>> getItemsForSlot(MealSlot slot) async {
    final items = await loadAllItems();
    return items.where((i) => i.suggestedSlot == slot).toList();
  }

  // ── Search by Name ────────────────────────────────────────────────────
  Future<List<DashFoodItem>> search(String query) async {
    final items = await loadAllItems();
    final q = query.toLowerCase();
    return items
        .where((i) =>
            i.name.toLowerCase().contains(q) ||
            i.nameTransliterated.toLowerCase().contains(q))
        .toList();
  }

  // ── Get by Key ────────────────────────────────────────────────────────
  Future<DashFoodItem?> getByKey(String key) async {
    final items = await loadAllItems();
    try {
      return items.firstWhere((i) => i.key == key);
    } catch (_) {
      return null;
    }
  }

  // ── Daily Meal Plan (pre-seeded DASH recommendations) ─────────────────
  // Returns the clinically pre-seeded meal plan for the UI suggestion strip.
  Future<Map<MealSlot, List<DashFoodItem>>> getDailyPlan() async {
    final items = await loadAllItems();

    // Filter only DASH-optimal items for each slot to build the daily plan.
    Map<MealSlot, List<DashFoodItem>> plan = {};
    for (final slot in MealSlot.values) {
      plan[slot] = items
          .where((i) => i.suggestedSlot == slot && i.isDashOptimal)
          .toList();
    }
    return plan;
  }
}

// Singleton service that loads dash_recipes.json once and exposes
// filter/search helpers consumed by RecipeBrowserView.

import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/recipe_model.dart';

class RecipeService {
  RecipeService._();
  static final RecipeService instance = RecipeService._();

  List<Recipe>? _cache;

  Future<List<Recipe>> _load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/dash_recipes.json');
    final list = jsonDecode(raw) as List;
    _cache = list.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
    return _cache!;
  }

  Future<List<Recipe>> getAll() => _load();

  Future<List<Recipe>> filter({
    int? day,            // 1-7; null = all days
    String? meal,        // breakfast|lunch|snack|dinner; null = all
    bool? vegOnly,       // true = veg, false = nveg, null = both
    String query = '',   // name/tag search
  }) async {
    var list = await _load();

    if (day != null) list = list.where((r) => r.day == day).toList();
    if (meal != null) list = list.where((r) => r.meal == meal).toList();
    if (vegOnly != null) {
      list = list
          .where((r) => vegOnly ? r.isVeg : !r.isVeg)
          .toList();
    }
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list
          .where((r) =>
              r.name.toLowerCase().contains(q) ||
              r.tags.any((t) => t.toLowerCase().contains(q)))
          .toList();
    }

    return list;
  }

  Future<Recipe?> getById(int id) async {
    final list = await _load();
    try {
      return list.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}

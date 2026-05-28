// Recipe model for the DASH South Indian recipe database.
// Loaded from assets/data/dash_recipes.json (42 recipes, Days 1-7).

class RecipeIngredient {
  final String name;
  final String qty;

  const RecipeIngredient({required this.name, required this.qty});

  factory RecipeIngredient.fromJson(Map<String, dynamic> j) =>
      RecipeIngredient(name: j['name'] as String, qty: j['qty'] as String);
}

class Recipe {
  final int id;
  final int day;
  final String meal; // breakfast | lunch | snack | dinner
  final String diet; // veg | nveg
  final String emoji;
  final String name;
  final String desc;
  final List<String> tags;
  final int kcal;
  final double protein;
  final double carbs;
  final double fat;
  final int sodium;
  final int potassium;
  final double fiber;
  final int dashScore;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final String dashNotes;

  const Recipe({
    required this.id,
    required this.day,
    required this.meal,
    required this.diet,
    required this.emoji,
    required this.name,
    required this.desc,
    required this.tags,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sodium,
    required this.potassium,
    required this.fiber,
    required this.dashScore,
    required this.ingredients,
    required this.steps,
    required this.dashNotes,
  });

  factory Recipe.fromJson(Map<String, dynamic> j) => Recipe(
        id: j['id'] as int,
        day: j['day'] as int,
        meal: j['meal'] as String,
        diet: j['diet'] as String,
        emoji: j['emoji'] as String,
        name: j['name'] as String,
        desc: j['desc'] as String,
        tags: List<String>.from(j['tags'] as List),
        kcal: j['kcal'] as int,
        protein: (j['protein'] as num).toDouble(),
        carbs: (j['carbs'] as num).toDouble(),
        fat: (j['fat'] as num).toDouble(),
        sodium: j['sodium'] as int,
        potassium: j['potassium'] as int,
        fiber: (j['fiber'] as num).toDouble(),
        dashScore: j['dash_score'] as int,
        ingredients: (j['ingredients'] as List)
            .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
        steps: List<String>.from(j['steps'] as List),
        dashNotes: j['dash_notes'] as String,
      );

  bool get isVeg => diet == 'veg';

  /// Sodium compliance level for UI colouring.
  /// DASH target: <500mg per meal (1500mg / 3 main meals).
  String get sodiumLevel {
    if (sodium < 300) return 'low';
    if (sodium < 500) return 'moderate';
    return 'high';
  }
}

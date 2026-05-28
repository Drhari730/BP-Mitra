// Recipe Detail – full view for one DASH recipe.
// Shows emoji hero, tags, nutrient grid, ingredient list,
// numbered preparation steps, and DASH compliance notes.

import 'package:flutter/material.dart';

import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';
import '../../theme/app_theme.dart';

class RecipeDetailView extends StatelessWidget {
  final int recipeId;

  const RecipeDetailView({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Recipe?>(
      future: RecipeService.instance.getById(recipeId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.white,
            body: Center(
                child: CircularProgressIndicator(color: AppTheme.darkBlue)),
          );
        }
        final recipe = snap.data;
        if (recipe == null) {
          return Scaffold(
            backgroundColor: AppTheme.white,
            appBar: AppBar(
              backgroundColor: AppTheme.darkBlue,
              foregroundColor: AppTheme.white,
              title: const Text('Recipe not found'),
            ),
            body: const Center(child: Text('Recipe not found')),
          );
        }
        return _RecipeDetailScaffold(recipe: recipe);
      },
    );
  }
}

class _RecipeDetailScaffold extends StatelessWidget {
  final Recipe recipe;

  const _RecipeDetailScaffold({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: CustomScrollView(
        slivers: [
          // ── Collapsible emoji hero header ──────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.darkBlue,
            foregroundColor: AppTheme.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.darkBlue,
                      AppTheme.darkBlue.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 56),
                    Text(recipe.emoji,
                        style: const TextStyle(fontSize: 72)),
                    const SizedBox(height: 8),
                    Text(
                      'Day ${recipe.day} · ${_capitalize(recipe.meal)}',
                      style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
            title: Text(
              recipe.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags row
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: recipe.tags
                        .map((t) => _Tag(label: t))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(recipe.desc,
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.midSlate,
                          height: 1.5)),
                  const SizedBox(height: 20),

                  // DASH score + diet badge
                  Row(
                    children: [
                      _DashScoreBadge(score: recipe.dashScore),
                      const SizedBox(width: 10),
                      _DietBadge(isVeg: recipe.isVeg),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Nutrient Grid ─────────────────────────
                  _SectionTitle(title: 'Nutrition per serving'),
                  const SizedBox(height: 12),
                  _NutrientGrid(recipe: recipe),
                  const SizedBox(height: 24),

                  // ── Ingredients ───────────────────────────
                  _SectionTitle(title: 'Ingredients'),
                  const SizedBox(height: 12),
                  ...recipe.ingredients.map((ing) => _IngredientRow(ing: ing)),
                  const SizedBox(height: 24),

                  // ── Preparation Steps ─────────────────────
                  _SectionTitle(title: 'Preparation'),
                  const SizedBox(height: 12),
                  ...recipe.steps.asMap().entries.map((e) =>
                      _StepRow(number: e.key + 1, text: e.value)),
                  const SizedBox(height: 24),

                  // ── DASH Compliance Notes ──────────────────
                  _DashNotesCard(notes: recipe.dashNotes),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Supporting widgets ──────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.darkSlate,
        ),
      );
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.softBluePill,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkBlue),
        ),
      );
}

class _DashScoreBadge extends StatelessWidget {
  final int score;
  const _DashScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 85
        ? const Color(0xFF16A34A)
        : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            'DASH Score $score',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color),
          ),
        ],
      ),
    );
  }
}

class _DietBadge extends StatelessWidget {
  final bool isVeg;
  const _DietBadge({required this.isVeg});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isVeg
              ? const Color(0xFFDCFCE7)
              : const Color(0xFFFEF9C3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          isVeg ? '🌿 Vegetarian' : '🍗 Non-Vegetarian',
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
}

// ── Nutrient grid (2 columns × 4 rows) ─────────────────────────────────
class _NutrientGrid extends StatelessWidget {
  final Recipe recipe;
  const _NutrientGrid({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NutrientItem('Calories', '${recipe.kcal} kcal', Icons.local_fire_department_outlined, const Color(0xFFEA580C), recipe.kcal / 600),
      _NutrientItem('Sodium', '${recipe.sodium} mg', Icons.water_drop_outlined, const Color(0xFF2563EB), recipe.sodium / 500),
      _NutrientItem('Potassium', '${recipe.potassium} mg', Icons.bolt_outlined, const Color(0xFF16A34A), recipe.potassium / 1500),
      _NutrientItem('Protein', '${recipe.protein.toStringAsFixed(1)} g', Icons.fitness_center_outlined, const Color(0xFF7C3AED), recipe.protein / 30),
      _NutrientItem('Carbs', '${recipe.carbs.toStringAsFixed(1)} g', Icons.grain_outlined, const Color(0xFFF59E0B), recipe.carbs / 80),
      _NutrientItem('Fat', '${recipe.fat.toStringAsFixed(1)} g', Icons.opacity_outlined, const Color(0xFF0891B2), recipe.fat / 20),
      _NutrientItem('Fiber', '${recipe.fiber.toStringAsFixed(1)} g', Icons.eco_outlined, const Color(0xFF059669), recipe.fiber / 10),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: items.map((item) => _NutrientTile(item: item)).toList(),
    );
  }
}

class _NutrientItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double fraction; // 0.0–1.0 for progress bar

  const _NutrientItem(
      this.label, this.value, this.icon, this.color, this.fraction);
}

class _NutrientTile extends StatelessWidget {
  final _NutrientItem item;
  const _NutrientTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: item.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(item.icon, size: 14, color: item.color),
              const SizedBox(width: 4),
              Text(item.label,
                  style: TextStyle(
                      fontSize: 10,
                      color: item.color,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(item.value,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkSlate)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: item.fraction.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: item.color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(item.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final RecipeIngredient ing;
  const _IngredientRow({required this.ing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  color: AppTheme.darkBlue, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(ing.name,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.darkSlate)),
            ),
            Text(ing.qty,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.midSlate)),
          ],
        ),
      );
}

class _StepRow extends StatelessWidget {
  final int number;
  final String text;
  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: AppTheme.darkBlue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.white,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.darkSlate,
                      height: 1.5)),
            ),
          ],
        ),
      );
}

class _DashNotesCard extends StatelessWidget {
  final String notes;
  const _DashNotesCard({required this.notes});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkBlue.withOpacity(0.06),
              AppTheme.darkBlue.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.darkBlue.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.science_outlined,
                    size: 16, color: AppTheme.darkBlue),
                SizedBox(width: 8),
                Text(
                  'DASH Clinical Notes',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(notes,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.midSlate,
                    height: 1.5)),
          ],
        ),
      );
}

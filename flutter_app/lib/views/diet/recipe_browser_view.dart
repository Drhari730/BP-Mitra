// Recipe Browser – filterable grid of all 42 DASH South Indian recipes.
// Filters: day chips (All / Day 1-7), meal tabs, veg toggle, search bar.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';

class RecipeBrowserView extends StatefulWidget {
  const RecipeBrowserView({super.key});

  @override
  State<RecipeBrowserView> createState() => _RecipeBrowserViewState();
}

class _RecipeBrowserViewState extends State<RecipeBrowserView>
    with SingleTickerProviderStateMixin {
  late TabController _mealTabCtrl;

  final _searchCtrl = TextEditingController();
  int? _selectedDay; // null = all
  bool? _vegOnly;    // null = both
  List<Recipe> _recipes = [];
  bool _loading = true;

  static const _meals = ['all', 'breakfast', 'lunch', 'snack', 'dinner'];
  static const _mealLabels = ['All', 'Breakfast', 'Lunch', 'Snack', 'Dinner'];

  @override
  void initState() {
    super.initState();
    _mealTabCtrl = TabController(length: _meals.length, vsync: this);
    _mealTabCtrl.addListener(_applyFilters);
    _searchCtrl.addListener(_applyFilters);
    _applyFilters();
  }

  Future<void> _applyFilters() async {
    final meal = _meals[_mealTabCtrl.index];
    final results = await RecipeService.instance.filter(
      day: _selectedDay,
      meal: meal == 'all' ? null : meal,
      vegOnly: _vegOnly,
      query: _searchCtrl.text,
    );
    if (mounted) setState(() { _recipes = results; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: Column(
        children: [
          AppHeader(
            title: 'DASH Recipes',
            subtitle: '42 South Indian clinical recipes',
            bottom: TabBar(
              controller: _mealTabCtrl,
              isScrollable: true,
              indicatorColor: AppTheme.white,
              indicatorWeight: 3,
              labelColor: AppTheme.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
              tabs: _mealLabels.map((l) => Tab(text: l)).toList(),
            ),
          ),
          _FilterBar(
            selectedDay: _selectedDay,
            vegOnly: _vegOnly,
            searchCtrl: _searchCtrl,
            onDayChanged: (d) { setState(() => _selectedDay = d); _applyFilters(); },
            onVegChanged: (v) { setState(() => _vegOnly = v); _applyFilters(); },
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.darkBlue))
                : _recipes.isEmpty
                    ? _EmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: _recipes.length,
                        itemBuilder: (_, i) => _RecipeCard(
                          recipe: _recipes[i],
                          onTap: () =>
                              context.push('/diet/recipes/${_recipes[i].id}'),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mealTabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }
}

// ── Filter bar: day chips + veg toggle + search ───────────────────────
class _FilterBar extends StatelessWidget {
  final int? selectedDay;
  final bool? vegOnly;
  final TextEditingController searchCtrl;
  final ValueChanged<int?> onDayChanged;
  final ValueChanged<bool?> onVegChanged;

  const _FilterBar({
    required this.selectedDay,
    required this.vegOnly,
    required this.searchCtrl,
    required this.onDayChanged,
    required this.onVegChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search recipes or tags…',
              prefixIcon:
                  const Icon(Icons.search, color: AppTheme.midSlate, size: 20),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.darkBlue),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Day chips (scrollable)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _DayChip(
                          label: 'All',
                          selected: selectedDay == null,
                          onTap: () => onDayChanged(null)),
                      ...List.generate(
                          7,
                          (i) => _DayChip(
                                label: 'Day ${i + 1}',
                                selected: selectedDay == i + 1,
                                onTap: () => onDayChanged(i + 1),
                              )),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Veg toggle
              _VegToggle(vegOnly: vegOnly, onChanged: onVegChanged),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DayChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.darkBlue : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppTheme.white : AppTheme.midSlate,
          ),
        ),
      ),
    );
  }
}

class _VegToggle extends StatelessWidget {
  final bool? vegOnly;
  final ValueChanged<bool?> onChanged;

  const _VegToggle({required this.vegOnly, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (vegOnly == null) onChanged(true);
        else if (vegOnly == true) onChanged(false);
        else onChanged(null);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: vegOnly == true
              ? const Color(0xFFDCFCE7)
              : vegOnly == false
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: vegOnly == true
                ? const Color(0xFF16A34A)
                : vegOnly == false
                    ? const Color(0xFFDC2626)
                    : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              vegOnly == null
                  ? '🌿 All'
                  : vegOnly!
                      ? '🌿 Veg'
                      : '🍗 Non-Veg',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recipe Card ─────────────────────────────────────────────────────────
class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const _RecipeCard({required this.recipe, required this.onTap});

  Color get _sodiumColor {
    switch (recipe.sodiumLevel) {
      case 'low':
        return const Color(0xFF16A34A);
      case 'moderate':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFDC2626);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cardShadow,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji hero
            Container(
              width: double.infinity,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.softBluePill,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Text(recipe.emoji,
                    style: const TextStyle(fontSize: 44)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // DASH score bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: recipe.dashScore / 100,
                              minHeight: 5,
                              backgroundColor: const Color(0xFFF1F5F9),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                recipe.dashScore >= 85
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${recipe.dashScore}',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.darkSlate),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Sodium + kcal row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _sodiumColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${recipe.sodium}mg Na',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _sodiumColor),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${recipe.kcal} kcal',
                          style: const TextStyle(
                              fontSize: 10, color: AppTheme.midSlate),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Tags
                    if (recipe.tags.isNotEmpty)
                      Text(
                        recipe.tags.take(2).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.midSlate),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_meals_outlined, size: 64, color: AppTheme.lightSlate),
          SizedBox(height: 16),
          Text('No recipes match your filters',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.midSlate)),
          SizedBox(height: 6),
          Text('Try adjusting the day or meal filter',
              style: TextStyle(fontSize: 13, color: AppTheme.lightSlate)),
        ],
      ),
    );
  }
}

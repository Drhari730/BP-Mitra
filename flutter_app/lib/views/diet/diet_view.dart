// Module 2 – My DASH Diet View
// Shows a daily food log, DASH meal plan suggestions, and a progressive
// sodium counter filling 0mg → 1500mg hard-stop red zone bar.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/diet/diet_bloc.dart';
import '../../models/diet_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/sodium_progress_bar.dart';

class DietView extends StatefulWidget {
  const DietView({super.key});

  @override
  State<DietView> createState() => _DietViewState();
}

class _DietViewState extends State<DietView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<DietBloc>().add(const LoadDayLog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: Column(
        children: [
          AppHeader(
            title: 'My DASH Diet',
            subtitle: 'South Indian DASH protocol',
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.white,
              indicatorWeight: 3,
              labelColor: AppTheme.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Today\'s Log'),
                Tab(text: 'Meal Plan'),
                Tab(text: 'Recipes'),
              ],
            ),
          ),
          BlocBuilder<DietBloc, DietState>(
            builder: (context, state) {
              if (state is DietLoaded) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: SodiumProgressBar(
                    totalSodiumMg: state.sodiumSummary.totalSodiumMg,
                    capMg: DailySodiumSummary.dailyCapMg,
                    progressFraction: state.sodiumSummary.progressFraction,
                    isOverLimit: state.sodiumSummary.isOverLimit,
                  ),
                );
              }
              return const SizedBox(height: 80);
            },
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DayLogTab(),
                _MealPlanTab(),
                _RecipesTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.darkBlue,
        foregroundColor: AppTheme.white,
        icon: const Icon(Icons.add),
        label: const Text('Log Food'),
        onPressed: _showFoodLogSheet,
      ),
    );
  }

  void _showFoodLogSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<DietBloc>(),
        child: const _FoodLogSheet(),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// ── Day Log Tab ────────────────────────────────────────────────────────
class _DayLogTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DietBloc, DietState>(
      builder: (context, state) {
        if (state is DietLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.darkBlue),
          );
        }
        if (state is DietLoaded) {
          if (state.entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.restaurant_outlined,
                      size: 64, color: AppTheme.lightSlate),
                  const SizedBox(height: 16),
                  Text('No meals logged today',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Tap "Log Food" to add a meal',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }

          // Group entries by meal slot.
          final grouped = <MealSlot, List<FoodLogEntry>>{};
          for (final slot in MealSlot.values) {
            grouped[slot] =
                state.entries.where((e) => e.mealSlot == slot).toList();
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: MealSlot.values
                .where((slot) => grouped[slot]!.isNotEmpty)
                .map((slot) => _MealSlotSection(
                      slot: slot,
                      entries: grouped[slot]!,
                    ))
                .toList(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ── Meal Slot Section ──────────────────────────────────────────────────
class _MealSlotSection extends StatelessWidget {
  final MealSlot slot;
  final List<FoodLogEntry> entries;

  const _MealSlotSection({required this.slot, required this.entries});

  @override
  Widget build(BuildContext context) {
    final totalSodium = entries.fold<double>(0, (sum, e) => sum + e.sodiumMg);
    final totalCal = entries.fold<double>(0, (sum, e) => sum + e.caloriesKcal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Text(slot.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkSlate,
                  )),
              const Spacer(),
              Text(
                '${totalSodium.toStringAsFixed(0)}mg Na · ${totalCal.toStringAsFixed(0)} kcal',
                style: const TextStyle(fontSize: 12, color: AppTheme.midSlate),
              ),
            ],
          ),
        ),
        ...entries.map((entry) => Dismissible(
              key: Key(entry.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_outline,
                    color: Colors.white, size: 24),
              ),
              onDismissed: (_) =>
                  context.read<DietBloc>().add(DeleteFoodEntry(entry.id)),
              child: _FoodEntryTile(entry: entry),
            )),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Food Entry Tile ────────────────────────────────────────────────────
class _FoodEntryTile extends StatelessWidget {
  final FoodLogEntry entry;

  const _FoodEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.softBluePill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.rice_bowl_outlined,
                size: 20, color: AppTheme.darkBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.foodName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkSlate,
                    )),
                Text(
                  '${entry.servingSizeG.toStringAsFixed(0)}g · ${entry.sodiumMg.toStringAsFixed(0)}mg Na · ${entry.caloriesKcal.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.midSlate),
                ),
              ],
            ),
          ),
          // K⁺ potassium indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${entry.potassiumMg.toStringAsFixed(0)}mg K⁺',
              style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Meal Plan Tab ──────────────────────────────────────────────────────
class _MealPlanTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DietBloc, DietState>(
      builder: (context, state) {
        if (state is! DietLoaded) return const SizedBox.shrink();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _MealPlanCard(
              slot: MealSlot.breakfast,
              items: state.dailyPlan[MealSlot.breakfast] ?? [],
              icon: Icons.wb_sunny_outlined,
              color: const Color(0xFFF59E0B),
            ),
            _MealPlanCard(
              slot: MealSlot.lunch,
              items: state.dailyPlan[MealSlot.lunch] ?? [],
              icon: Icons.lunch_dining_outlined,
              color: const Color(0xFF10B981),
            ),
            _MealPlanCard(
              slot: MealSlot.dinner,
              items: state.dailyPlan[MealSlot.dinner] ?? [],
              icon: Icons.nights_stay_outlined,
              color: const Color(0xFF8B5CF6),
            ),
          ],
        );
      },
    );
  }
}

class _MealPlanCard extends StatelessWidget {
  final MealSlot slot;
  final List<DashFoodItem> items;
  final IconData icon;
  final Color color;

  const _MealPlanCard({
    required this.slot,
    required this.items,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Text(slot.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkSlate,
                    )),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ...items.map((item) => ListTile(
                dense: true,
                leading: const Icon(Icons.fiber_manual_record,
                    size: 8, color: AppTheme.darkBlue),
                title: Text(item.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                subtitle: Text(
                  '${item.sodiumMg.toStringAsFixed(0)}mg Na · ${item.potassiumMg.toStringAsFixed(0)}mg K⁺',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: GestureDetector(
                  onTap: () {
                    context.read<DietBloc>().add(LogFood(
                          item: item,
                          slot: slot,
                          servingSizeG: item.servingSizeG,
                        ));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Logged ${item.name}'),
                      backgroundColor: AppTheme.successGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      duration: const Duration(seconds: 2),
                    ));
                  },
                  child: const Icon(Icons.add_circle_outline,
                      color: AppTheme.darkBlue, size: 22),
                ),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Recipes Tab ────────────────────────────────────────────────────────
class _RecipesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Quick-access card: Browse all 42 recipes
        _QuickLinkCard(
          icon: Icons.menu_book_outlined,
          color: AppTheme.darkBlue,
          title: 'Recipe Browser',
          subtitle: '42 South Indian DASH recipes · Filter by day, meal & diet',
          onTap: () => context.push('/diet/recipes'),
        ),
        const SizedBox(height: 12),
        // DASH nutrition targets reference
        _QuickLinkCard(
          icon: Icons.science_outlined,
          color: const Color(0xFF16A34A),
          title: 'DASH Nutrition Targets',
          subtitle: 'Sodium ≤1500mg · K⁺ 4700mg · Ca 1250mg · Mg 500mg',
          onTap: () => context.push('/diet/targets'),
        ),
        const SizedBox(height: 20),
        // DASH compliance guide
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkBlue.withOpacity(0.08),
                AppTheme.darkBlue.withOpacity(0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: AppTheme.darkBlue.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: AppTheme.darkBlue),
                  SizedBox(width: 8),
                  Text(
                    'South Indian DASH Protocol',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...[
                '🌾 Substitute white rice with ragi or millets 3×/week',
                '🥬 Add drumstick leaves (moringa) to sambar daily',
                '🥥 Limit coconut oil to 1 tsp/meal; avoid ghee tadka',
                '🥒 Replace pickle with fresh coriander-mint chutney',
                '🫙 Prioritise fermented foods: idli, dosa, curd',
                '🥤 Coconut water as mid-meal hydration (600mg K⁺)',
              ].map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(tip,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.midSlate,
                          height: 1.5)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickLinkCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickLinkCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkSlate,
                        )),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.midSlate)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppTheme.lightSlate, size: 20),
            ],
          ),
        ),
      );
}

// ── Food Log Bottom Sheet ───────────────────────────────────────────────
class _FoodLogSheet extends StatefulWidget {
  const _FoodLogSheet();

  @override
  State<_FoodLogSheet> createState() => _FoodLogSheetState();
}

class _FoodLogSheetState extends State<_FoodLogSheet> {
  final _searchCtrl = TextEditingController();
  MealSlot _selectedSlot = MealSlot.lunch;
  List<DashFoodItem> _results = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      context.read<DietBloc>().add(SearchFoodItems(_searchCtrl.text));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<MealSlot>(
            value: _selectedSlot,
            decoration: const InputDecoration(labelText: 'Meal Slot'),
            items: MealSlot.values.map((slot) => DropdownMenuItem(
              value: slot,
              child: Text(slot.label),
            )).toList(),
            onChanged: (v) => setState(() => _selectedSlot = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              labelText: 'Search food items',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          BlocBuilder<DietBloc, DietState>(
            builder: (context, state) {
              if (state is FoodSearchResults) {
                return SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: state.results.length,
                    itemBuilder: (_, index) {
                      final item = state.results[index];
                      return ListTile(
                        title: Text(item.name,
                            style: const TextStyle(fontSize: 13)),
                        subtitle: Text(
                            '${item.sodiumMg.toStringAsFixed(0)}mg Na per ${item.servingSizeG.toStringAsFixed(0)}g'),
                        trailing: TextButton(
                          onPressed: () {
                            context.read<DietBloc>().add(LogFood(
                                  item: item,
                                  slot: _selectedSlot,
                                  servingSizeG: item.servingSizeG,
                                ));
                            Navigator.of(context).pop();
                          },
                          child: const Text('Add'),
                        ),
                      );
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}

// BP Mitra – Main Dashboard View
// Layout: Dark Blue (#1543A4) header block + 2-column GridView of module cards.
// Each card: rounded square, subtle blue shadow, centered icon in soft blue pill,
// dark-slate label below.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../blocs/activity/activity_bloc.dart';
import '../../blocs/vitals/vitals_bloc.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bp_stat_chip.dart';
import '../../widgets/circular_progress_card.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    context.read<VitalsBloc>().add(LoadReadings());
    context.read<ActivityBloc>().add(const StartActivityTracking());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: Column(
        children: [
          _DashboardHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _QuickStatsRow(),
                  const SizedBox(height: 24),
                  Text(
                    'Your Health Modules',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  _ModuleGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header Block ────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _greeting(now.hour);
    final dateStr = DateFormat('EEEE, d MMM yyyy').format(now);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppTheme.headerGradient,
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: AppTheme.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting 👋',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'BP Mitra',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppTheme.white),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            dateStr,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

// ── Quick Stats Row: BP + Steps ─────────────────────────────────────────
class _QuickStatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BlocBuilder<VitalsBloc, VitalsState>(
            builder: (context, state) {
              if (state is VitalsLoaded && state.latestReading != null) {
                final r = state.latestReading!;
                return BpStatChip(
                  systolic: r.systolicMmhg,
                  diastolic: r.diastolicMmhg,
                  category: r.bpCategory,
                );
              }
              return const BpStatChip(
                systolic: 0,
                diastolic: 0,
                category: 'No Data',
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: BlocBuilder<ActivityBloc, ActivityState>(
            builder: (context, state) {
              double progress = 0;
              int steps = 0;
              double kcal = 0;

              if (state is ActivityTracking) {
                progress = state.pedometer.progressFraction;
                steps = state.pedometer.totalStepsToday;
                kcal = state.pedometer.activeKcal;
              }

              return CircularProgressCard(
                progress: progress,
                label: 'Steps Today',
                value: '$steps',
                subValue: '${kcal.toStringAsFixed(0)} kcal',
                color: AppTheme.darkBlue,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── 2-Column Module Grid ─────────────────────────────────────────────────
class _ModuleGrid extends StatelessWidget {
  final List<_ModuleCard> _cards = const [
    _ModuleCard(
      icon: Icons.medication_outlined,
      label: 'Treatment\nPlanner',
      route: '/medications',
      color: Color(0xFF3B82F6),
    ),
    _ModuleCard(
      icon: Icons.restaurant_menu_outlined,
      label: 'My DASH\nDiet',
      route: '/diet',
      color: Color(0xFF10B981),
    ),
    _ModuleCard(
      icon: Icons.favorite_border_outlined,
      label: 'Vitals &\nBP Trends',
      route: '/vitals',
      color: Color(0xFFEF4444),
    ),
    _ModuleCard(
      icon: Icons.directions_walk_outlined,
      label: 'Activity\nTracker',
      route: '/activity',
      color: Color(0xFFF59E0B),
    ),
    _ModuleCard(
      icon: Icons.psychology_outlined,
      label: 'AI Clinical\nAssistant',
      route: '/ai',
      color: Color(0xFF8B5CF6),
    ),
    _ModuleCard(
      icon: Icons.self_improvement_outlined,
      label: 'Yoga &\nBreathing',
      route: '/ai',
      color: Color(0xFF06B6D4),
    ),
  ];

  const _ModuleGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.0,
      ),
      itemCount: _cards.length,
      itemBuilder: (context, index) => _cards[index],
    );
  }
}

// ── Individual Module Card ───────────────────────────────────────────────
class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const _ModuleCard({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cardShadow,
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon wrapped in soft blue pill
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkSlate,
                  height: 1.3,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: AppTheme.lightSlate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

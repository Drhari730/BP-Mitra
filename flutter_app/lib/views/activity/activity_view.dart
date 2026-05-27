// Module 4 – Activity Tracker View
// Displays a circular daily progress indicator for step count and calories.
// Live-updates from the PedometerService via ActivityBloc stream.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/activity/activity_bloc.dart';
import '../../models/activity_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';

class ActivityView extends StatefulWidget {
  const ActivityView({super.key});

  @override
  State<ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends State<ActivityView> {
  @override
  void initState() {
    super.initState();
    // Start tracking if not already running.
    if (context.read<ActivityBloc>().state is! ActivityTracking) {
      context.read<ActivityBloc>().add(const StartActivityTracking());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: Column(
        children: [
          AppHeader(
            title: 'Activity Tracker',
            subtitle: 'Step count & calorie burn',
          ),
          Expanded(
            child: BlocBuilder<ActivityBloc, ActivityState>(
              builder: (context, state) {
                PedometerState pedometer = const PedometerState();
                bool isTracking = false;

                if (state is ActivityTracking) {
                  pedometer = state.pedometer;
                  isTracking = true;
                } else if (state is ActivityStopped) {
                  pedometer = state.finalState;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // ── Circular Progress Hero ──────────────────────
                      _StepCircle(
                        steps: pedometer.totalStepsToday,
                        progress: pedometer.progressFraction,
                        isTracking: isTracking,
                      ),

                      const SizedBox(height: 32),

                      // ── Metric Cards Row ────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              icon: Icons.local_fire_department_outlined,
                              label: 'Active Calories',
                              value:
                                  '${pedometer.activeKcal.toStringAsFixed(1)}',
                              unit: 'kcal',
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              icon: Icons.flag_outlined,
                              label: 'Daily Goal',
                              value: '8,000',
                              unit: 'steps',
                              color: AppTheme.darkBlue,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Cardiovascular Tip ──────────────────────────
                      _CardioTipCard(steps: pedometer.totalStepsToday),

                      const SizedBox(height: 24),

                      // ── Tracking Toggle ─────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (isTracking) {
                              context
                                  .read<ActivityBloc>()
                                  .add(StopActivityTracking());
                            } else {
                              context
                                  .read<ActivityBloc>()
                                  .add(const StartActivityTracking());
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isTracking
                                ? AppTheme.warningAmber
                                : AppTheme.darkBlue,
                          ),
                          icon: Icon(
                            isTracking ? Icons.pause : Icons.play_arrow,
                          ),
                          label: Text(
                            isTracking ? 'Pause Tracking' : 'Start Tracking',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Circular Step Progress Indicator ────────────────────────────────────
class _StepCircle extends StatelessWidget {
  final int steps;
  final double progress;
  final bool isTracking;

  const _StepCircle({
    required this.steps,
    required this.progress,
    required this.isTracking,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 16,
              color: const Color(0xFFF1F5F9),
            ),
          ),
          // Progress ring
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              builder: (_, value, __) => CircularProgressIndicator(
                value: value,
                strokeWidth: 16,
                color: progress >= 1.0
                    ? AppTheme.successGreen
                    : AppTheme.darkBlue,
                backgroundColor: Colors.transparent,
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          // Center content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isTracking)
                const Icon(Icons.directions_walk,
                    size: 28, color: AppTheme.darkBlue),
              Text(
                _formatSteps(steps),
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkSlate,
                  letterSpacing: -1,
                ),
              ),
              const Text(
                'steps today',
                style: TextStyle(fontSize: 13, color: AppTheme.midSlate),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% of goal',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.darkBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}k';
    }
    return steps.toString();
  }
}

// ── Metric Card ──────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkSlate,
            ),
          ),
          Text(unit,
              style: const TextStyle(fontSize: 12, color: AppTheme.lightSlate)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppTheme.midSlate)),
        ],
      ),
    );
  }
}

// ── Cardio Tip Card based on step count ─────────────────────────────────
class _CardioTipCard extends StatelessWidget {
  final int steps;
  const _CardioTipCard({required this.steps});

  @override
  Widget build(BuildContext context) {
    String tip;
    IconData icon;
    Color color;

    if (steps < 2000) {
      tip = 'Low movement detected. Even a 10-minute walk can reduce systolic BP by 4–9 mmHg. Try a gentle stroll after your next meal.';
      icon = Icons.directions_walk_outlined;
      color = AppTheme.warningAmber;
    } else if (steps < 5000) {
      tip = 'Good start! You\'re building cardiovascular momentum. Aim for 30 minutes of brisk walking to reach your blood pressure target zone.';
      icon = Icons.trending_up;
      color = AppTheme.darkBlue;
    } else if (steps < 8000) {
      tip = 'Excellent progress! Your activity level is contributing to vascular health. Keep maintaining this rhythm.';
      icon = Icons.thumb_up_outlined;
      color = const Color(0xFF10B981);
    } else {
      tip = 'Outstanding! You\'ve reached your daily goal. Today\'s activity contributes significantly to long-term blood pressure regulation.';
      icon = Icons.emoji_events_outlined;
      color = AppTheme.successGreen;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.darkSlate,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

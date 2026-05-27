// Module 2 – Daily Sodium Counter Progress Bar Widget
// Fills from 0mg to 1500mg with a gradient bar that transitions from
// green → amber → red as it approaches the hard-stop cap.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SodiumProgressBar extends StatelessWidget {
  final double totalSodiumMg;
  final double capMg;
  final double progressFraction; // 0.0 – 1.0
  final bool isOverLimit;

  const SodiumProgressBar({
    super.key,
    required this.totalSodiumMg,
    required this.capMg,
    required this.progressFraction,
    required this.isOverLimit,
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
          Row(
            children: [
              const Icon(Icons.water_drop_outlined,
                  size: 18, color: AppTheme.darkBlue),
              const SizedBox(width: 8),
              const Text(
                'Daily Sodium Intake',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkSlate,
                ),
              ),
              const Spacer(),
              Text(
                isOverLimit ? '⚠ Over Limit' : '${(capMg - totalSodiumMg).toStringAsFixed(0)}mg remaining',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isOverLimit ? AppTheme.errorRed : AppTheme.successGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progressFraction),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, _) {
                return Stack(
                  children: [
                    // Background track
                    Container(
                      height: 12,
                      width: double.infinity,
                      color: const Color(0xFFF1F5F9),
                    ),
                    // Filled portion
                    FractionallySizedBox(
                      widthFactor: value.clamp(0.0, 1.0),
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _gradientColors(value),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Numeric labels
          Row(
            children: [
              Text(
                '${totalSodiumMg.toStringAsFixed(0)}mg',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isOverLimit ? AppTheme.sodiumRed : AppTheme.darkSlate,
                ),
              ),
              const Text(
                ' / ',
                style: TextStyle(fontSize: 16, color: AppTheme.lightSlate),
              ),
              Text(
                '${capMg.toStringAsFixed(0)}mg',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.midSlate,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // Red zone indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOverLimit
                      ? AppTheme.errorRed.withOpacity(0.12)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOverLimit
                          ? Icons.warning_rounded
                          : Icons.check_circle_outline,
                      size: 12,
                      color: isOverLimit
                          ? AppTheme.errorRed
                          : const Color(0xFF059669),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOverLimit ? 'DASH cap exceeded' : 'Within DASH limit',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isOverLimit
                            ? AppTheme.errorRed
                            : const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Gradient transitions: green (0%) → amber (65%) → red (100%)
  List<Color> _gradientColors(double fraction) {
    if (fraction < 0.65) {
      return [
        const Color(0xFF38A169),
        Color.lerp(const Color(0xFF38A169), const Color(0xFFD69E2E),
            fraction / 0.65)!,
      ];
    } else {
      return [
        Color.lerp(const Color(0xFF38A169), const Color(0xFFD69E2E),
            0.65)!,
        Color.lerp(const Color(0xFFD69E2E), AppTheme.errorRed,
            (fraction - 0.65) / 0.35)!,
      ];
    }
  }
}

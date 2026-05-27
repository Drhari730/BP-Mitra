// Dashboard BP stat chip widget showing systolic/diastolic with category badge.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BpStatChip extends StatelessWidget {
  final int systolic;
  final int diastolic;
  final String category;

  const BpStatChip({
    super.key,
    required this.systolic,
    required this.diastolic,
    required this.category,
  });

  Color get _chipColor {
    switch (category) {
      case 'Normal':    return AppTheme.successGreen;
      case 'Elevated':  return AppTheme.warningAmber;
      case 'Stage 1':   return const Color(0xFFED8936);
      case 'No Data':   return AppTheme.lightSlate;
      default:          return AppTheme.errorRed;
    }
  }

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
              const Icon(Icons.favorite, size: 14, color: AppTheme.errorRed),
              const SizedBox(width: 6),
              const Text('Blood Pressure',
                  style: TextStyle(fontSize: 11, color: AppTheme.midSlate)),
            ],
          ),
          const SizedBox(height: 6),
          systolic == 0
              ? const Text('– / –',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.lightSlate,
                  ))
              : Text(
                  '$systolic/$diastolic',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkSlate,
                    letterSpacing: -0.5,
                  ),
                ),
          const Text('mmHg',
              style: TextStyle(fontSize: 11, color: AppTheme.lightSlate)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _chipColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              category,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _chipColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

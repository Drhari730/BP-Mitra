// Dashboard circular progress card for step count display.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CircularProgressCard extends StatelessWidget {
  final double progress;
  final String label;
  final String value;
  final String? subValue;
  final Color color;

  const CircularProgressCard({
    super.key,
    required this.progress,
    required this.label,
    required this.value,
    this.subValue,
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
          Row(
            children: [
              const Icon(Icons.directions_walk_outlined,
                  size: 14, color: AppTheme.midSlate),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.midSlate)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkSlate,
                        )),
                    if (subValue != null)
                      Text(subValue!,
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.lightSlate)),
                  ],
                ),
              ),
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  color: color,
                  backgroundColor: color.withOpacity(0.15),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

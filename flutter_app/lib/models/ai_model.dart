// Models for Module 5 – AI Clinical Assistant.

import 'package:equatable/equatable.dart';

// ── AI Evaluation Input Payload ──────────────────────────────────────────
class AiInputPayload extends Equatable {
  final int currentSystolic;
  final int currentDiastolic;
  final int adherenceRatePercentage;
  final double dailySodiumIntakeMg;
  final int activeSteps;
  // 1 = great energy, 5 = severe fatigue
  final int qolFatigueScore;

  const AiInputPayload({
    required this.currentSystolic,
    required this.currentDiastolic,
    required this.adherenceRatePercentage,
    required this.dailySodiumIntakeMg,
    required this.activeSteps,
    required this.qolFatigueScore,
  });

  Map<String, dynamic> toJson() => {
    'current_systolic': currentSystolic,
    'current_diastolic': currentDiastolic,
    'adherence_rate_percentage': adherenceRatePercentage,
    'daily_sodium_intake_mg': dailySodiumIntakeMg,
    'active_steps': activeSteps,
    'qol_fatigue_score': qolFatigueScore,
  };

  @override
  List<Object?> get props => [
    currentSystolic, currentDiastolic, adherenceRatePercentage,
    dailySodiumIntakeMg, activeSteps, qolFatigueScore,
  ];
}

// ── AI Evaluation Response ───────────────────────────────────────────────
class AiEvaluationResult extends Equatable {
  final String? profile;      // 'A', 'B', 'C', or null for healthy baseline
  final String responseText;
  final DateTime evaluatedAt;

  const AiEvaluationResult({
    this.profile,
    required this.responseText,
    required this.evaluatedAt,
  });

  factory AiEvaluationResult.fromJson(Map<String, dynamic> json) {
    return AiEvaluationResult(
      profile: json['profile'] as String?,
      responseText: json['response'] as String,
      evaluatedAt: DateTime.parse(json['evaluated_at'] as String),
    );
  }

  // Profile severity color mapping for UI badge
  String get profileLabel {
    switch (profile) {
      case 'A': return 'High Priority';
      case 'B': return 'Diet Alert';
      case 'C': return 'Rest & Recovery';
      default:  return 'All Clear';
    }
  }

  @override
  List<Object?> get props => [profile, responseText, evaluatedAt];
}

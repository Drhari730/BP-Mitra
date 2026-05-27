// Models for Module 4 – Accelerometer Lifestyle Tracker.

import 'package:equatable/equatable.dart';

// ── Daily Activity Log ───────────────────────────────────────────────────
class ActivityLog extends Equatable {
  final String id;
  final DateTime logDate;
  final int totalSteps;
  final double activeKcal;
  final int dailyGoal;        // configurable; default 8000
  final double progressFraction;

  const ActivityLog({
    required this.id,
    required this.logDate,
    required this.totalSteps,
    required this.activeKcal,
    this.dailyGoal = 8000,
    required this.progressFraction,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    final steps = json['total_steps'] as int? ?? 0;
    final goal = json['daily_goal'] as int? ?? 8000;
    return ActivityLog(
      id: json['id'] as String? ?? '',
      logDate: DateTime.parse(json['log_date'] as String? ??
          DateTime.now().toIso8601String().substring(0, 10)),
      totalSteps: steps,
      activeKcal: (json['active_kcal'] as num? ?? 0).toDouble(),
      dailyGoal: goal,
      progressFraction: (json['progress_fraction'] as num? ?? steps / goal).toDouble(),
    );
  }

  factory ActivityLog.empty() => ActivityLog(
    id: '',
    logDate: DateTime.now(),
    totalSteps: 0,
    activeKcal: 0,
    progressFraction: 0,
  );

  @override
  List<Object?> get props => [id, logDate, totalSteps];
}

// ── Live Accelerometer Epoch (in-memory, not serialized) ─────────────────
// Represents one hardware sample frame from userAccelerometerEvents.
class AccelerometerEpoch {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  AccelerometerEpoch({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  // Vector magnitude A = sqrt(x² + y² + z²) in g-force units.
  double get magnitude => (x * x + y * y + z * z);
}

// ── Pedometer State (in-memory session state) ────────────────────────────
class PedometerState extends Equatable {
  final int sessionSteps;       // Steps accumulated in this device session
  final int totalStepsToday;    // Persistent total including prior sessions
  final double activeKcal;
  final double progressFraction;
  final bool isTracking;

  const PedometerState({
    this.sessionSteps = 0,
    this.totalStepsToday = 0,
    this.activeKcal = 0,
    this.progressFraction = 0,
    this.isTracking = false,
  });

  PedometerState copyWith({
    int? sessionSteps,
    int? totalStepsToday,
    double? activeKcal,
    double? progressFraction,
    bool? isTracking,
  }) {
    return PedometerState(
      sessionSteps: sessionSteps ?? this.sessionSteps,
      totalStepsToday: totalStepsToday ?? this.totalStepsToday,
      activeKcal: activeKcal ?? this.activeKcal,
      progressFraction: progressFraction ?? this.progressFraction,
      isTracking: isTracking ?? this.isTracking,
    );
  }

  @override
  List<Object?> get props => [sessionSteps, totalStepsToday, activeKcal, isTracking];
}

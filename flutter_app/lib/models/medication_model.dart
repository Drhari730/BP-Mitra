// Models for Module 1 – Medication Tracker & Adherence.
// Uses json_annotation for serialization from REST API responses.

// packages: json_annotation

import 'package:equatable/equatable.dart';

// ── Medication Schedule ─────────────────────────────────────────────────
class MedicationSchedule extends Equatable {
  final String id;
  final String userId;
  final String medName;
  final double dosageMg;
  final int frequencyHours;
  final String scheduledTime; // "HH:MM" 24-hour wall-clock
  final String drugClass;
  final bool isCritical;
  final bool isActive;
  final DateTime createdAt;

  const MedicationSchedule({
    required this.id,
    required this.userId,
    required this.medName,
    required this.dosageMg,
    required this.frequencyHours,
    required this.scheduledTime,
    required this.drugClass,
    required this.isCritical,
    required this.isActive,
    required this.createdAt,
  });

  factory MedicationSchedule.fromJson(Map<String, dynamic> json) {
    return MedicationSchedule(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      medName: json['med_name'] as String,
      dosageMg: (json['dosage_mg'] as num).toDouble(),
      frequencyHours: json['frequency_hours'] as int,
      scheduledTime: json['scheduled_time'] as String,
      drugClass: json['drug_class'] as String? ?? 'antihypertensive',
      isCritical: json['is_critical'] as bool? ?? true,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'med_name': medName,
    'dosage_mg': dosageMg,
    'frequency_hours': frequencyHours,
    'scheduled_time': scheduledTime,
    'drug_class': drugClass,
    'is_critical': isCritical,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };

  // Human-readable dosage string for UI display
  String get displayDosage => '$medName ${dosageMg.toStringAsFixed(dosageMg.truncateToDouble() == dosageMg ? 0 : 1)}mg';

  @override
  List<Object?> get props => [id, medName, dosageMg, scheduledTime, isActive];
}

// ── Adherence Status Enum ───────────────────────────────────────────────
enum AdherenceStatus { taken, skipped, missed }

extension AdherenceStatusExtension on AdherenceStatus {
  String get apiValue {
    switch (this) {
      case AdherenceStatus.taken:   return 'Taken';
      case AdherenceStatus.skipped: return 'Skipped';
      case AdherenceStatus.missed:  return 'Missed';
    }
  }

  static AdherenceStatus fromString(String value) {
    switch (value) {
      case 'Taken':   return AdherenceStatus.taken;
      case 'Skipped': return AdherenceStatus.skipped;
      default:        return AdherenceStatus.missed;
    }
  }
}

// ── Adherence Log ───────────────────────────────────────────────────────
class AdherenceLog extends Equatable {
  final String id;
  final String scheduleId;
  final String userId;
  final DateTime scheduledAt;
  final DateTime? loggedAt;
  final AdherenceStatus status;
  final int? deltaMinutes;
  final bool escalationSent;

  // Denormalized fields from schedule join
  final String medName;
  final double dosageMg;

  const AdherenceLog({
    required this.id,
    required this.scheduleId,
    required this.userId,
    required this.scheduledAt,
    this.loggedAt,
    required this.status,
    this.deltaMinutes,
    required this.escalationSent,
    required this.medName,
    required this.dosageMg,
  });

  factory AdherenceLog.fromJson(Map<String, dynamic> json) {
    return AdherenceLog(
      id: json['id'] as String,
      scheduleId: json['schedule_id'] as String,
      userId: json['user_id'] as String? ?? '',
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      loggedAt: json['logged_at'] != null
          ? DateTime.parse(json['logged_at'] as String)
          : null,
      status: AdherenceStatusExtension.fromString(json['status'] as String),
      deltaMinutes: json['delta_minutes'] as int?,
      escalationSent: json['escalation_sent'] as bool? ?? false,
      medName: json['med_name'] as String? ?? '',
      dosageMg: (json['dosage_mg'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, scheduleId, scheduledAt, status];
}

// ── Adherence Summary (7-day window) ────────────────────────────────────
class AdherenceSummary extends Equatable {
  final int taken;
  final int skipped;
  final int missed;
  final int total;
  final int adherenceRatePercentage;
  final int streakDays;
  final bool sevenDayMilestoneReached;

  const AdherenceSummary({
    required this.taken,
    required this.skipped,
    required this.missed,
    required this.total,
    required this.adherenceRatePercentage,
    this.streakDays = 0,
    this.sevenDayMilestoneReached = false,
  });

  factory AdherenceSummary.empty() => const AdherenceSummary(
    taken: 0, skipped: 0, missed: 0, total: 0, adherenceRatePercentage: 0,
  );

  factory AdherenceSummary.fromJson(Map<String, dynamic> json) {
    return AdherenceSummary(
      taken: json['taken'] as int? ?? 0,
      skipped: json['skipped'] as int? ?? 0,
      missed: json['missed'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      adherenceRatePercentage: json['adherence_rate_percentage'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [taken, skipped, missed, total, adherenceRatePercentage];
}

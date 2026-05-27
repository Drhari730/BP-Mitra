// Models for Module 3 – Vitals Capture & Historical Trends.

import 'package:equatable/equatable.dart';

// ── BP Reading Source ────────────────────────────────────────────────────
enum ReadingSource { rppg, manual }

extension ReadingSourceExtension on ReadingSource {
  String get apiValue => name;
  static ReadingSource fromString(String v) =>
      v == 'rppg' ? ReadingSource.rppg : ReadingSource.manual;
}

// ── BP Reading ───────────────────────────────────────────────────────────
class BpReading extends Equatable {
  final String id;
  final int systolicMmhg;
  final int diastolicMmhg;
  final int? pulseBpm;
  final ReadingSource source;
  final double? rppgConfidence;  // 0.0 – 1.0 from signal pipeline
  final String? notes;
  final DateTime measuredAt;

  const BpReading({
    required this.id,
    required this.systolicMmhg,
    required this.diastolicMmhg,
    this.pulseBpm,
    required this.source,
    this.rppgConfidence,
    this.notes,
    required this.measuredAt,
  });

  factory BpReading.fromJson(Map<String, dynamic> json) {
    return BpReading(
      id: json['id'] as String,
      systolicMmhg: json['systolic_mmhg'] as int,
      diastolicMmhg: json['diastolic_mmhg'] as int,
      pulseBpm: json['pulse_bpm'] as int?,
      source: ReadingSourceExtension.fromString(json['source'] as String),
      rppgConfidence: (json['rppg_confidence'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      measuredAt: DateTime.parse(json['measured_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'systolic_mmhg': systolicMmhg,
    'diastolic_mmhg': diastolicMmhg,
    'pulse_bpm': pulseBpm,
    'source': source.apiValue,
    'rppg_confidence': rppgConfidence,
    'notes': notes,
    'measured_at': measuredAt.toIso8601String(),
  };

  // JNC 8 hypertension classification
  String get bpCategory {
    if (systolicMmhg >= 180 || diastolicMmhg >= 120) return 'Hypertensive Crisis';
    if (systolicMmhg >= 160 || diastolicMmhg >= 100) return 'Stage 2';
    if (systolicMmhg >= 140 || diastolicMmhg >= 90)  return 'Stage 1';
    if (systolicMmhg >= 130 || diastolicMmhg >= 80)  return 'Elevated';
    return 'Normal';
  }

  String get displayValue => '$systolicMmhg/$diastolicMmhg';

  @override
  List<Object?> get props => [id, systolicMmhg, diastolicMmhg, measuredAt];
}

// ── Daily BP Trend (aggregated for chart) ──────────────────────────────
class BpTrendPoint extends Equatable {
  final DateTime date;
  final int avgSystolic;
  final int avgDiastolic;
  final int? avgPulse;
  final int readingCount;

  const BpTrendPoint({
    required this.date,
    required this.avgSystolic,
    required this.avgDiastolic,
    this.avgPulse,
    required this.readingCount,
  });

  factory BpTrendPoint.fromJson(Map<String, dynamic> json) {
    return BpTrendPoint(
      date: DateTime.parse(json['date'] as String),
      avgSystolic: json['avg_systolic'] as int,
      avgDiastolic: json['avg_diastolic'] as int,
      avgPulse: json['avg_pulse'] as int?,
      readingCount: json['reading_count'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [date, avgSystolic, avgDiastolic];
}

// ── rPPG Signal State (local, not persisted to API until finalized) ─────
class RppgSignalState extends Equatable {
  final bool isCapturing;
  final int secondsRemaining;  // 30-second countdown
  final double instantBpm;
  final List<double> waveformBuffer;  // raw green-channel intensity values
  final int? estimatedSystolic;
  final int? estimatedDiastolic;
  final double confidenceScore;  // 0.0 – 1.0

  const RppgSignalState({
    this.isCapturing = false,
    this.secondsRemaining = 30,
    this.instantBpm = 0,
    this.waveformBuffer = const [],
    this.estimatedSystolic,
    this.estimatedDiastolic,
    this.confidenceScore = 0,
  });

  RppgSignalState copyWith({
    bool? isCapturing,
    int? secondsRemaining,
    double? instantBpm,
    List<double>? waveformBuffer,
    int? estimatedSystolic,
    int? estimatedDiastolic,
    double? confidenceScore,
  }) {
    return RppgSignalState(
      isCapturing: isCapturing ?? this.isCapturing,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      instantBpm: instantBpm ?? this.instantBpm,
      waveformBuffer: waveformBuffer ?? this.waveformBuffer,
      estimatedSystolic: estimatedSystolic ?? this.estimatedSystolic,
      estimatedDiastolic: estimatedDiastolic ?? this.estimatedDiastolic,
      confidenceScore: confidenceScore ?? this.confidenceScore,
    );
  }

  @override
  List<Object?> get props => [
    isCapturing, secondsRemaining, instantBpm,
    estimatedSystolic, estimatedDiastolic, confidenceScore,
  ];
}

// Module 3 – Vitals BLoC: manages BP readings and rPPG capture state.

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/vitals_model.dart';
import '../../services/api_service.dart';
import '../../services/rppg_service.dart';

// ── Events ───────────────────────────────────────────────────────────────
abstract class VitalsEvent extends Equatable {
  const VitalsEvent();
  @override
  List<Object?> get props => [];
}

class LoadReadings extends VitalsEvent {}
class LoadTrend extends VitalsEvent {
  final int days;
  const LoadTrend({this.days = 30});
  @override List<Object?> get props => [days];
}
class StartRppgCapture extends VitalsEvent {}
class RppgTickDown extends VitalsEvent {
  final int secondsRemaining;
  final double currentBpm;
  const RppgTickDown({required this.secondsRemaining, required this.currentBpm});
  @override List<Object?> get props => [secondsRemaining, currentBpm];
}
class CompleteRppgCapture extends VitalsEvent {}
class SubmitManualReading extends VitalsEvent {
  final int systolic;
  final int diastolic;
  final int? pulse;
  final String? notes;
  const SubmitManualReading({
    required this.systolic,
    required this.diastolic,
    this.pulse,
    this.notes,
  });
  @override List<Object?> get props => [systolic, diastolic, pulse];
}

// ── States ───────────────────────────────────────────────────────────────
abstract class VitalsState extends Equatable {
  const VitalsState();
  @override List<Object?> get props => [];
}

class VitalsInitial extends VitalsState {}
class VitalsLoading extends VitalsState {}

class VitalsLoaded extends VitalsState {
  final List<BpReading> readings;
  final List<BpTrendPoint> trend;
  final BpReading? latestReading;

  const VitalsLoaded({
    required this.readings,
    required this.trend,
    this.latestReading,
  });

  VitalsLoaded copyWith({
    List<BpReading>? readings,
    List<BpTrendPoint>? trend,
    BpReading? latestReading,
  }) {
    return VitalsLoaded(
      readings: readings ?? this.readings,
      trend: trend ?? this.trend,
      latestReading: latestReading ?? this.latestReading,
    );
  }

  @override List<Object?> get props => [readings, trend, latestReading];
}

class RppgCapturing extends VitalsState {
  final int secondsRemaining;
  final double currentBpm;
  const RppgCapturing({required this.secondsRemaining, required this.currentBpm});
  @override List<Object?> get props => [secondsRemaining, currentBpm];
}

class RppgComplete extends VitalsState {
  final RppgSignalState signalResult;
  const RppgComplete(this.signalResult);
  @override List<Object?> get props => [signalResult];
}

class ReadingSaved extends VitalsState {
  final BpReading reading;
  const ReadingSaved(this.reading);
  @override List<Object?> get props => [reading];
}

class VitalsError extends VitalsState {
  final String message;
  const VitalsError(this.message);
  @override List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────
class VitalsBloc extends Bloc<VitalsEvent, VitalsState> {
  final ApiService apiService;

  VitalsBloc({required this.apiService}) : super(VitalsInitial()) {
    on<LoadReadings>(_onLoadReadings);
    on<LoadTrend>(_onLoadTrend);
    on<StartRppgCapture>(_onStartRppgCapture);
    on<RppgTickDown>(_onRppgTickDown);
    on<CompleteRppgCapture>(_onCompleteRppgCapture);
    on<SubmitManualReading>(_onSubmitManualReading);
  }

  Future<void> _onLoadReadings(
    LoadReadings event,
    Emitter<VitalsState> emit,
  ) async {
    emit(VitalsLoading());
    try {
      final readings = await apiService.fetchReadings();
      final latest = await apiService.fetchLatestReading();
      final trend = await apiService.fetchTrend();
      emit(VitalsLoaded(readings: readings, trend: trend, latestReading: latest));
    } catch (e) {
      emit(VitalsError(e.toString()));
    }
  }

  Future<void> _onLoadTrend(
    LoadTrend event,
    Emitter<VitalsState> emit,
  ) async {
    try {
      final trend = await apiService.fetchTrend(days: event.days);
      if (state is VitalsLoaded) {
        emit((state as VitalsLoaded).copyWith(trend: trend));
      }
    } catch (e) {
      emit(VitalsError(e.toString()));
    }
  }

  Future<void> _onStartRppgCapture(
    StartRppgCapture event,
    Emitter<VitalsState> emit,
  ) async {
    RppgService.instance.startPipeline();
    emit(const RppgCapturing(secondsRemaining: 30, currentBpm: 0));
  }

  void _onRppgTickDown(RppgTickDown event, Emitter<VitalsState> emit) {
    if (event.secondsRemaining <= 0) {
      add(CompleteRppgCapture());
    } else {
      emit(RppgCapturing(
        secondsRemaining: event.secondsRemaining,
        currentBpm: event.currentBpm,
      ));
    }
  }

  Future<void> _onCompleteRppgCapture(
    CompleteRppgCapture event,
    Emitter<VitalsState> emit,
  ) async {
    final signalResult = RppgService.instance.finalizeSession();
    emit(RppgComplete(signalResult));

    // Auto-save reading to API if confidence is acceptable (>0.5).
    if (signalResult.confidenceScore > 0.5 &&
        signalResult.estimatedSystolic != null) {
      try {
        final reading = await apiService.createReading({
          'systolic_mmhg': signalResult.estimatedSystolic,
          'diastolic_mmhg': signalResult.estimatedDiastolic,
          'pulse_bpm': signalResult.instantBpm.round(),
          'source': 'rppg',
          'rppg_confidence': signalResult.confidenceScore,
        });
        emit(ReadingSaved(reading));
      } catch (_) {
        // Silently continue; user can retry via manual entry.
      }
    }
  }

  Future<void> _onSubmitManualReading(
    SubmitManualReading event,
    Emitter<VitalsState> emit,
  ) async {
    try {
      final reading = await apiService.createReading({
        'systolic_mmhg': event.systolic,
        'diastolic_mmhg': event.diastolic,
        'pulse_bpm': event.pulse,
        'source': 'manual',
        'notes': event.notes,
      });
      emit(ReadingSaved(reading));
      add(LoadReadings());
    } catch (e) {
      emit(VitalsError(e.toString()));
    }
  }
}

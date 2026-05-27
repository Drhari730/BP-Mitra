// Module 4 – Activity Tracker BLoC
// Bridges PedometerService sensor stream to UI state.

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/activity_model.dart';
import '../../services/pedometer_service.dart';

// ── Events ────────────────────────────────────────────────────────────────
abstract class ActivityEvent extends Equatable {
  const ActivityEvent();
  @override List<Object?> get props => [];
}

class StartActivityTracking extends ActivityEvent {
  final int persistedStepsOffset;
  const StartActivityTracking({this.persistedStepsOffset = 0});
  @override List<Object?> get props => [persistedStepsOffset];
}

class StopActivityTracking extends ActivityEvent {}

class StepCountUpdated extends ActivityEvent {
  final int totalSteps;
  const StepCountUpdated(this.totalSteps);
  @override List<Object?> get props => [totalSteps];
}

// ── States ────────────────────────────────────────────────────────────────
abstract class ActivityState extends Equatable {
  const ActivityState();
  @override List<Object?> get props => [];
}

class ActivityInitial extends ActivityState {}

class ActivityTracking extends ActivityState {
  final PedometerState pedometer;
  const ActivityTracking(this.pedometer);
  @override List<Object?> get props => [pedometer];
}

class ActivityStopped extends ActivityState {
  final PedometerState finalState;
  const ActivityStopped(this.finalState);
  @override List<Object?> get props => [finalState];
}

// ── BLoC ──────────────────────────────────────────────────────────────────
class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  StreamSubscription<int>? _stepSubscription;
  static const int _dailyStepGoal = 8000;

  ActivityBloc() : super(ActivityInitial()) {
    on<StartActivityTracking>(_onStartTracking);
    on<StopActivityTracking>(_onStopTracking);
    on<StepCountUpdated>(_onStepCountUpdated);
  }

  Future<void> _onStartTracking(
    StartActivityTracking event,
    Emitter<ActivityState> emit,
  ) async {
    PedometerService.instance.startTracking(
      persistedStepsOffset: event.persistedStepsOffset,
    );

    _stepSubscription?.cancel();
    _stepSubscription = PedometerService.instance.stepStream.listen((steps) {
      add(StepCountUpdated(steps));
    });

    emit(ActivityTracking(PedometerState(
      isTracking: true,
      totalStepsToday: event.persistedStepsOffset,
      progressFraction: (event.persistedStepsOffset / _dailyStepGoal).clamp(0.0, 1.0),
    )));
  }

  void _onStepCountUpdated(
    StepCountUpdated event,
    Emitter<ActivityState> emit,
  ) {
    final service = PedometerService.instance;
    emit(ActivityTracking(PedometerState(
      isTracking: true,
      sessionSteps: service.totalStepsToday - (state is ActivityTracking
          ? (state as ActivityTracking).pedometer.totalStepsToday - service.totalStepsToday
          : 0),
      totalStepsToday: event.totalSteps,
      activeKcal: service.activeKcal,
      progressFraction: service.progressFraction,
    )));
  }

  Future<void> _onStopTracking(
    StopActivityTracking event,
    Emitter<ActivityState> emit,
  ) async {
    _stepSubscription?.cancel();
    _stepSubscription = null;
    PedometerService.instance.stopTracking();

    final service = PedometerService.instance;
    emit(ActivityStopped(PedometerState(
      isTracking: false,
      totalStepsToday: service.totalStepsToday,
      activeKcal: service.activeKcal,
      progressFraction: service.progressFraction,
    )));
  }

  @override
  Future<void> close() {
    _stepSubscription?.cancel();
    PedometerService.instance.dispose();
    return super.close();
  }
}

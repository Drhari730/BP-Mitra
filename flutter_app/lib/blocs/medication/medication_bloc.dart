// Module 1 – Medication Tracker BLoC
// Manages schedule list, adherence logging, streak computation,
// and triggers notification scheduling via NotificationService.

// packages: flutter_bloc, equatable

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/medication_model.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';

// ── Events ───────────────────────────────────────────────────────────────
abstract class MedicationEvent extends Equatable {
  const MedicationEvent();
  @override
  List<Object?> get props => [];
}

class LoadSchedules extends MedicationEvent {}

class CreateSchedule extends MedicationEvent {
  final Map<String, dynamic> payload;
  const CreateSchedule(this.payload);
  @override
  List<Object?> get props => [payload];
}

class LogDose extends MedicationEvent {
  final String scheduleId;
  final AdherenceStatus status;
  final DateTime scheduledAt;
  const LogDose({
    required this.scheduleId,
    required this.status,
    required this.scheduledAt,
  });
  @override
  List<Object?> get props => [scheduleId, status, scheduledAt];
}

class LoadAdherenceLogs extends MedicationEvent {}

class CheckStreakMilestone extends MedicationEvent {}

// ── States ───────────────────────────────────────────────────────────────
abstract class MedicationState extends Equatable {
  const MedicationState();
  @override
  List<Object?> get props => [];
}

class MedicationInitial extends MedicationState {}

class MedicationLoading extends MedicationState {}

class MedicationLoaded extends MedicationState {
  final List<MedicationSchedule> schedules;
  final List<AdherenceLog> recentLogs;
  final AdherenceSummary summary;
  final int streakDays;
  final bool sevenDayMilestoneJustReached;

  const MedicationLoaded({
    required this.schedules,
    required this.recentLogs,
    required this.summary,
    required this.streakDays,
    this.sevenDayMilestoneJustReached = false,
  });

  @override
  List<Object?> get props => [
    schedules, recentLogs, summary, streakDays, sevenDayMilestoneJustReached,
  ];

  MedicationLoaded copyWith({
    List<MedicationSchedule>? schedules,
    List<AdherenceLog>? recentLogs,
    AdherenceSummary? summary,
    int? streakDays,
    bool? sevenDayMilestoneJustReached,
  }) {
    return MedicationLoaded(
      schedules: schedules ?? this.schedules,
      recentLogs: recentLogs ?? this.recentLogs,
      summary: summary ?? this.summary,
      streakDays: streakDays ?? this.streakDays,
      sevenDayMilestoneJustReached:
          sevenDayMilestoneJustReached ?? this.sevenDayMilestoneJustReached,
    );
  }
}

class MedicationError extends MedicationState {
  final String message;
  const MedicationError(this.message);
  @override
  List<Object?> get props => [message];
}

class DoseLogged extends MedicationState {
  final AdherenceStatus status;
  const DoseLogged(this.status);
  @override
  List<Object?> get props => [status];
}

// ── BLoC ─────────────────────────────────────────────────────────────────
class MedicationBloc extends Bloc<MedicationEvent, MedicationState> {
  final ApiService apiService;

  MedicationBloc({required this.apiService}) : super(MedicationInitial()) {
    on<LoadSchedules>(_onLoadSchedules);
    on<CreateSchedule>(_onCreateSchedule);
    on<LogDose>(_onLogDose);
    on<LoadAdherenceLogs>(_onLoadAdherenceLogs);
    on<CheckStreakMilestone>(_onCheckStreakMilestone);
  }

  Future<void> _onLoadSchedules(
    LoadSchedules event,
    Emitter<MedicationState> emit,
  ) async {
    emit(MedicationLoading());
    try {
      final schedules = await apiService.fetchSchedules();
      final logs = await apiService.fetchAdherenceLogs();
      final summary = await apiService.fetchAdherenceSummary();
      final streakData = await apiService.fetchAdherenceStreak();
      final streakDays = streakData['streak_days'] as int? ?? 0;

      emit(MedicationLoaded(
        schedules: schedules,
        recentLogs: logs,
        summary: summary,
        streakDays: streakDays,
      ));

      // Schedule notifications for all active medication reminders.
      for (final schedule in schedules) {
        await _scheduleNotificationsForSchedule(schedule);
      }
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> _onCreateSchedule(
    CreateSchedule event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      final schedule = await apiService.createSchedule(event.payload);
      await _scheduleNotificationsForSchedule(schedule);

      if (state is MedicationLoaded) {
        final current = state as MedicationLoaded;
        emit(current.copyWith(schedules: [...current.schedules, schedule]));
      }
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> _onLogDose(
    LogDose event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await apiService.logAdherence(
        event.scheduleId,
        event.status.apiValue,
        event.scheduledAt.toIso8601String(),
      );

      // Cancel escalation notification if dose is confirmed as Taken.
      if (event.status == AdherenceStatus.taken) {
        await NotificationService.instance
            .cancelEscalationAlert(event.scheduleId);
      }

      emit(DoseLogged(event.status));

      // Check if this log triggers the 7-day streak milestone.
      add(CheckStreakMilestone());
      add(LoadSchedules());
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> _onLoadAdherenceLogs(
    LoadAdherenceLogs event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      final logs = await apiService.fetchAdherenceLogs();
      if (state is MedicationLoaded) {
        emit((state as MedicationLoaded).copyWith(recentLogs: logs));
      }
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> _onCheckStreakMilestone(
    CheckStreakMilestone event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      final streakData = await apiService.fetchAdherenceStreak();
      final streakDays = streakData['streak_days'] as int? ?? 0;
      final milestoneReached = streakData['seven_day_milestone_reached'] as bool? ?? false;

      if (milestoneReached) {
        // Rule C: Fire behavioral nudge notification for 7-day streak.
        await NotificationService.instance.fireStreakMilestoneNotification();
      }

      if (state is MedicationLoaded) {
        emit((state as MedicationLoaded).copyWith(
          streakDays: streakDays,
          sevenDayMilestoneJustReached: milestoneReached,
        ));
      }
    } catch (_) {
      // Streak check failure is non-fatal; swallow silently.
    }
  }

  // ── Schedule both Rule A and Rule B notifications ────────────────────
  Future<void> _scheduleNotificationsForSchedule(
      MedicationSchedule schedule) async {
    final parts = schedule.scheduledTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Rule A: Standard reminder at exact scheduled time.
    await NotificationService.instance.scheduleStandardReminder(
      schedule: schedule,
      scheduledDateTime: scheduledDate,
    );

    // Rule B: Escalation alert 45 minutes later for critical medications.
    await NotificationService.instance.scheduleEscalationAlert(
      schedule: schedule,
      scheduledDateTime: scheduledDate,
    );
  }
}

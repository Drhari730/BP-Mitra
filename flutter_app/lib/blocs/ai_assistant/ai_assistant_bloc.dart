// Module 5 – AI Clinical Assistant BLoC

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/ai_model.dart';
import '../../services/api_service.dart';

// ── Events ────────────────────────────────────────────────────────────────
abstract class AiAssistantEvent extends Equatable {
  const AiAssistantEvent();
  @override List<Object?> get props => [];
}

class EvaluateHealthProfile extends AiAssistantEvent {
  final AiInputPayload payload;
  const EvaluateHealthProfile(this.payload);
  @override List<Object?> get props => [payload];
}

class LoadAiHistory extends AiAssistantEvent {}

// ── States ────────────────────────────────────────────────────────────────
abstract class AiAssistantState extends Equatable {
  const AiAssistantState();
  @override List<Object?> get props => [];
}

class AiAssistantInitial extends AiAssistantState {}
class AiAssistantLoading extends AiAssistantState {}

class AiAssistantResult extends AiAssistantState {
  final AiEvaluationResult result;
  const AiAssistantResult(this.result);
  @override List<Object?> get props => [result];
}

class AiAssistantError extends AiAssistantState {
  final String message;
  const AiAssistantError(this.message);
  @override List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────
class AiAssistantBloc extends Bloc<AiAssistantEvent, AiAssistantState> {
  final ApiService apiService;

  AiAssistantBloc({required this.apiService}) : super(AiAssistantInitial()) {
    on<EvaluateHealthProfile>(_onEvaluate);
    on<LoadAiHistory>(_onLoadHistory);
  }

  Future<void> _onEvaluate(
    EvaluateHealthProfile event,
    Emitter<AiAssistantState> emit,
  ) async {
    emit(AiAssistantLoading());
    try {
      final result = await apiService.evaluateAi(event.payload);
      emit(AiAssistantResult(result));
    } catch (e) {
      emit(AiAssistantError(e.toString()));
    }
  }

  Future<void> _onLoadHistory(
    LoadAiHistory event,
    Emitter<AiAssistantState> emit,
  ) async {
    // History load is a no-op in the BLoC; the view fetches via API directly
    // to avoid coupling the BLoC to history-display pagination state.
  }
}

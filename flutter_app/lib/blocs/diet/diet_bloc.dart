// Module 2 – DASH Diet BLoC

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

import '../../models/diet_model.dart';
import '../../services/api_service.dart';
import '../../services/dash_diet_service.dart';

// ── Events ────────────────────────────────────────────────────────────────
abstract class DietEvent extends Equatable {
  const DietEvent();
  @override List<Object?> get props => [];
}

class LoadDayLog extends DietEvent {
  final String? date;
  const LoadDayLog({this.date});
  @override List<Object?> get props => [date];
}

class LogFood extends DietEvent {
  final DashFoodItem item;
  final MealSlot slot;
  final double servingSizeG;
  const LogFood({required this.item, required this.slot, required this.servingSizeG});
  @override List<Object?> get props => [item.key, slot, servingSizeG];
}

class DeleteFoodEntry extends DietEvent {
  final String entryId;
  const DeleteFoodEntry(this.entryId);
  @override List<Object?> get props => [entryId];
}

class SearchFoodItems extends DietEvent {
  final String query;
  const SearchFoodItems(this.query);
  @override List<Object?> get props => [query];
}

// ── States ────────────────────────────────────────────────────────────────
abstract class DietState extends Equatable {
  const DietState();
  @override List<Object?> get props => [];
}

class DietInitial extends DietState {}
class DietLoading extends DietState {}

class DietLoaded extends DietState {
  final String date;
  final List<FoodLogEntry> entries;
  final DailySodiumSummary sodiumSummary;
  final Map<MealSlot, List<DashFoodItem>> dailyPlan;

  const DietLoaded({
    required this.date,
    required this.entries,
    required this.sodiumSummary,
    required this.dailyPlan,
  });

  DietLoaded copyWith({
    List<FoodLogEntry>? entries,
    DailySodiumSummary? sodiumSummary,
  }) {
    return DietLoaded(
      date: date,
      entries: entries ?? this.entries,
      sodiumSummary: sodiumSummary ?? this.sodiumSummary,
      dailyPlan: dailyPlan,
    );
  }

  @override List<Object?> get props => [date, entries, sodiumSummary];
}

class FoodSearchResults extends DietState {
  final List<DashFoodItem> results;
  final String query;
  const FoodSearchResults({required this.results, required this.query});
  @override List<Object?> get props => [results, query];
}

class DietError extends DietState {
  final String message;
  const DietError(this.message);
  @override List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────
class DietBloc extends Bloc<DietEvent, DietState> {
  final ApiService apiService;

  DietBloc({required this.apiService}) : super(DietInitial()) {
    on<LoadDayLog>(_onLoadDayLog);
    on<LogFood>(_onLogFood);
    on<DeleteFoodEntry>(_onDeleteFoodEntry);
    on<SearchFoodItems>(_onSearchFoodItems);
  }

  Future<void> _onLoadDayLog(LoadDayLog event, Emitter<DietState> emit) async {
    emit(DietLoading());
    try {
      final date = event.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
      final entries = await apiService.fetchDayLog(date);
      final sodium = await apiService.fetchSodiumSummary(date);
      final plan = await DashDietService.instance.getDailyPlan();

      emit(DietLoaded(
        date: date,
        entries: entries,
        sodiumSummary: sodium,
        dailyPlan: plan,
      ));
    } catch (e) {
      emit(DietError(e.toString()));
    }
  }

  Future<void> _onLogFood(LogFood event, Emitter<DietState> emit) async {
    try {
      final scale = event.servingSizeG / event.item.servingSizeG;
      await apiService.logMeal({
        'meal_slot': event.slot.apiValue,
        'food_item_key': event.item.key,
        'food_name': event.item.name,
        'serving_size_g': event.servingSizeG,
        'sodium_mg': (event.item.sodiumMg * scale),
        'potassium_mg': (event.item.potassiumMg * scale),
        'magnesium_mg': (event.item.magnesiumMg * scale),
        'calories_kcal': (event.item.caloriesKcal * scale),
      });

      // Reload the day log to update sodium counter.
      add(const LoadDayLog());
    } catch (e) {
      emit(DietError(e.toString()));
    }
  }

  Future<void> _onDeleteFoodEntry(
    DeleteFoodEntry event,
    Emitter<DietState> emit,
  ) async {
    try {
      await apiService.deleteFoodEntry(event.entryId);
      add(const LoadDayLog());
    } catch (e) {
      emit(DietError(e.toString()));
    }
  }

  Future<void> _onSearchFoodItems(
    SearchFoodItems event,
    Emitter<DietState> emit,
  ) async {
    try {
      final results = await DashDietService.instance.search(event.query);
      emit(FoodSearchResults(results: results, query: event.query));
    } catch (e) {
      emit(DietError(e.toString()));
    }
  }
}

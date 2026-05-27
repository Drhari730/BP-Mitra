// Centralized HTTP client for all BP Mitra API calls.
// Uses the dio package with JWT Bearer token injection and error normalization.

// packages: dio, shared_preferences

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/medication_model.dart';
import '../models/diet_model.dart';
import '../models/vitals_model.dart';
import '../models/activity_model.dart';
import '../models/ai_model.dart';

class ApiService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000/api/v1',
  );
  static const String _tokenKey = 'auth_token';

  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    // Inject JWT token on every request.
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(_tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (err, handler) {
        // Normalize Dio errors into a consistent ApiException.
        throw ApiException(
          message: err.response?.data?['error'] ?? err.message ?? 'Network error',
          statusCode: err.response?.statusCode,
        );
      },
    ));
  }

  // ── Auth ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    await _saveToken(response.data['token'] as String);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    final response = await _dio.post('/auth/register', data: payload);
    await _saveToken(response.data['token'] as String);
    return response.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // ── Module 1: Medications ───────────────────────────────────────────────
  Future<List<MedicationSchedule>> fetchSchedules() async {
    final response = await _dio.get('/medications/schedules');
    final list = response.data['schedules'] as List;
    return list.map((e) => MedicationSchedule.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MedicationSchedule> createSchedule(Map<String, dynamic> payload) async {
    final response = await _dio.post('/medications/schedules', data: payload);
    return MedicationSchedule.fromJson(response.data['schedule'] as Map<String, dynamic>);
  }

  Future<void> logAdherence(String scheduleId, String status, String scheduledAt) async {
    await _dio.post('/medications/log', data: {
      'schedule_id': scheduleId,
      'status': status,
      'scheduled_at': scheduledAt,
    });
  }

  Future<List<AdherenceLog>> fetchAdherenceLogs({String? scheduleId}) async {
    final params = scheduleId != null ? {'schedule_id': scheduleId} : null;
    final response = await _dio.get('/medications/logs', queryParameters: params);
    final list = response.data['logs'] as List;
    return list.map((e) => AdherenceLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AdherenceSummary> fetchAdherenceSummary() async {
    final response = await _dio.get('/medications/summary');
    return AdherenceSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> fetchAdherenceStreak() async {
    final response = await _dio.get('/medications/streak');
    return response.data as Map<String, dynamic>;
  }

  // ── Module 2: Diet ──────────────────────────────────────────────────────
  Future<List<FoodLogEntry>> fetchDayLog(String date) async {
    final response = await _dio.get('/diet/log', queryParameters: {'date': date});
    final list = response.data['entries'] as List;
    return list.map((e) => FoodLogEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FoodLogEntry> logMeal(Map<String, dynamic> payload) async {
    final response = await _dio.post('/diet/log', data: payload);
    return FoodLogEntry.fromJson(response.data['entry'] as Map<String, dynamic>);
  }

  Future<DailySodiumSummary> fetchSodiumSummary(String date) async {
    final response = await _dio.get('/diet/sodium-summary', queryParameters: {'date': date});
    return DailySodiumSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteFoodEntry(String id) async {
    await _dio.delete('/diet/log/$id');
  }

  // ── Module 3: Vitals ────────────────────────────────────────────────────
  Future<BpReading> createReading(Map<String, dynamic> payload) async {
    final response = await _dio.post('/vitals', data: payload);
    return BpReading.fromJson(response.data['reading'] as Map<String, dynamic>);
  }

  Future<List<BpReading>> fetchReadings({int limit = 50}) async {
    final response = await _dio.get('/vitals', queryParameters: {'limit': limit});
    final list = response.data['readings'] as List;
    return list.map((e) => BpReading.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BpReading?> fetchLatestReading() async {
    try {
      final response = await _dio.get('/vitals/latest');
      return BpReading.fromJson(response.data['reading'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<BpTrendPoint>> fetchTrend({int days = 30}) async {
    final response = await _dio.get('/vitals/trend', queryParameters: {'days': days});
    final list = response.data['trend'] as List;
    return list.map((e) => BpTrendPoint.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Module 4: Activity ──────────────────────────────────────────────────
  Future<ActivityLog> syncActivity(int totalSteps, {String? date}) async {
    final response = await _dio.post('/activity/sync', data: {
      'total_steps': totalSteps,
      if (date != null) 'log_date': date,
    });
    return ActivityLog.fromJson(response.data['activity'] as Map<String, dynamic>);
  }

  Future<ActivityLog> fetchTodayActivity() async {
    final response = await _dio.get('/activity/today');
    return ActivityLog.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Module 5: AI Assistant ──────────────────────────────────────────────
  Future<AiEvaluationResult> evaluateAi(AiInputPayload payload) async {
    final response = await _dio.post('/ai/evaluate', data: payload.toJson());
    return AiEvaluationResult.fromJson(response.data as Map<String, dynamic>);
  }
}

// ── Typed API Exception ──────────────────────────────────────────────────
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

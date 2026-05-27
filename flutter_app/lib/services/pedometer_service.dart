// Module 4 – On-Device Pedometer Service
// Listens to userAccelerometerEvents from sensors_plus, applies vector-
// magnitude spike detection to count steps locally, and converts to kcal.

// packages: sensors_plus, rxdart

import 'dart:async';
import 'dart:math';

import 'package:rxdart/rxdart.dart';
import 'package:sensors_plus/sensors_plus.dart';

class PedometerService {
  PedometerService._();
  static final PedometerService instance = PedometerService._();

  // ── Configuration ────────────────────────────────────────────────────
  // 1.2g threshold: spikes above this register as a step event.
  static const double _stepThresholdG = 1.2;
  // Standard metabolic equivalent: 1 step ≈ 0.04 kcal
  static const double _kcalPerStep = 0.04;
  // Minimum milliseconds between valid step events (debounce guard).
  static const int _minStepIntervalMs = 300;

  StreamSubscription<UserAccelerometerEvent>? _subscription;
  final BehaviorSubject<int> _stepCountStream = BehaviorSubject.seeded(0);
  Stream<int> get stepStream => _stepCountStream.stream;

  int _sessionSteps = 0;
  int _persistedSteps = 0;  // From earlier sessions today (loaded from storage)
  DateTime? _lastStepTime;

  // Rolling 5-sample buffer for peak smoothing.
  final List<double> _magnitudeBuffer = [];
  static const int _bufferSize = 5;

  bool get isTracking => _subscription != null;

  // ── Start Listening ──────────────────────────────────────────────────
  void startTracking({int persistedStepsOffset = 0}) {
    if (_subscription != null) return; // Already tracking

    _persistedSteps = persistedStepsOffset;
    _sessionSteps = 0;
    _lastStepTime = null;

    _subscription = userAccelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval, // ~20ms sample rate
    ).listen(_processAccelerometerEvent);
  }

  // ── Process Accelerometer Event ─────────────────────────────────────
  // Computes vector magnitude, applies smoothing, and triggers step detection.
  void _processAccelerometerEvent(UserAccelerometerEvent event) {
    // A = sqrt(x² + y² + z²) in m/s²; convert to g-force (÷ 9.81).
    final magnitudeMps2 = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    final magnitudeG = magnitudeMps2 / 9.81;

    // Maintain rolling buffer for peak smoothing.
    _magnitudeBuffer.add(magnitudeG);
    if (_magnitudeBuffer.length > _bufferSize) _magnitudeBuffer.removeAt(0);
    final smoothedMagnitude = _magnitudeBuffer.reduce((a, b) => a + b) / _magnitudeBuffer.length;

    // Spike detection: smoothed magnitude exceeds dynamic threshold.
    if (smoothedMagnitude > _stepThresholdG) {
      final now = DateTime.now();

      // Debounce: enforce minimum interval between registered steps.
      if (_lastStepTime == null ||
          now.difference(_lastStepTime!).inMilliseconds > _minStepIntervalMs) {
        _lastStepTime = now;
        _sessionSteps++;
        _stepCountStream.add(totalStepsToday);
      }
    }
  }

  // ── Step Totals ──────────────────────────────────────────────────────
  int get totalStepsToday => _persistedSteps + _sessionSteps;

  // MET-based caloric conversion: steps × 0.04 kcal
  double get activeKcal =>
      double.parse((totalStepsToday * _kcalPerStep).toStringAsFixed(2));

  double get progressFraction => (totalStepsToday / 8000).clamp(0.0, 1.0);

  // ── Stop Listening ───────────────────────────────────────────────────
  void stopTracking() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    stopTracking();
    _stepCountStream.close();
  }
}

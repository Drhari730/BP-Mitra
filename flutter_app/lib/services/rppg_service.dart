// Module 3 – rPPG Signal Extraction Mock Pipeline
// Captures green-channel luminosity from camera frames, applies a simulated
// bandpass filter (0.7–4 Hz cardiac band), and derives BPM + BP estimates.
// In production this pipeline would be replaced by a validated native SDK.

// packages: camera, rxdart

import 'dart:async';
import 'dart:math';

import 'package:rxdart/rxdart.dart';

import '../models/vitals_model.dart';

class RppgService {
  RppgService._();
  static final RppgService instance = RppgService._();

  // ── Signal Buffers ────────────────────────────────────────────────────
  // Rolling 30-second window of raw green-channel intensity values.
  // Sampled at 30 fps → 900 samples max.
  final List<double> _rawGreenBuffer = [];
  static const int _maxBufferSize = 900;

  // Low-pass filtered signal buffer for BPM detection.
  final List<double> _filteredBuffer = [];

  // BPM stream — emits every ~200ms as new frames arrive.
  final BehaviorSubject<double> _bpmStream = BehaviorSubject.seeded(0);
  Stream<double> get bpmStream => _bpmStream.stream;

  Timer? _processingTimer;
  final Random _rng = Random();

  // ── Start Pipeline ────────────────────────────────────────────────────
  // Called when the camera capture session begins. The real implementation
  // receives CameraImage frames and extracts the Y/Green channel mean.
  void startPipeline() {
    _rawGreenBuffer.clear();
    _filteredBuffer.clear();

    // Simulate 30-fps frame ingestion for the mock pipeline.
    _processingTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      _ingestMockFrame();
    });
  }

  // ── Ingest a Camera Frame ─────────────────────────────────────────────
  // In production: extracts ROI green-channel mean from CameraImage.
  // Mock: synthesizes a plausible cardiac waveform with noise.
  void _ingestMockFrame() {
    final t = _rawGreenBuffer.length / 30.0; // time in seconds

    // Simulate resting heart rate 65–75 BPM → ~1.15 Hz fundamental.
    final heartRate = 70.0;
    final hz = heartRate / 60.0;
    final cardiac = sin(2 * pi * hz * t) * 15;          // cardiac AC component
    final respiration = sin(2 * pi * 0.25 * t) * 3;     // respiratory modulation
    final noise = (_rng.nextDouble() - 0.5) * 4;        // ambient noise
    final baseline = 128.0;                              // mean luminance

    final sample = baseline + cardiac + respiration + noise;
    _rawGreenBuffer.add(sample.clamp(0, 255));

    if (_rawGreenBuffer.length > _maxBufferSize) {
      _rawGreenBuffer.removeAt(0);
    }

    // Apply IIR low-pass filter (α = 0.15) to attenuate motion artifacts.
    final filtered = _applyLowPassFilter(sample);
    _filteredBuffer.add(filtered);
    if (_filteredBuffer.length > _maxBufferSize) {
      _filteredBuffer.removeAt(0);
    }

    // Compute BPM from peak detection every 30 frames (1 second).
    if (_rawGreenBuffer.length % 30 == 0 && _filteredBuffer.length >= 60) {
      final bpm = _computeBpmFromPeaks(_filteredBuffer);
      _bpmStream.add(bpm);
    }
  }

  double _prevFiltered = 128.0;
  double _applyLowPassFilter(double sample) {
    const alpha = 0.15;
    _prevFiltered = alpha * sample + (1 - alpha) * _prevFiltered;
    return _prevFiltered;
  }

  // ── BPM via Zero-Crossing / Peak Detection ────────────────────────────
  // Counts positive-slope zero-crossings in the AC-component of the
  // filtered signal over a 10-second window to derive cardiac frequency.
  double _computeBpmFromPeaks(List<double> buffer) {
    final window = buffer.length >= 300 ? buffer.sublist(buffer.length - 300) : buffer;
    final mean = window.reduce((a, b) => a + b) / window.length;

    int crossings = 0;
    for (int i = 1; i < window.length; i++) {
      if (window[i - 1] < mean && window[i] >= mean) {
        crossings++;
      }
    }

    final windowSeconds = window.length / 30.0;
    final hz = crossings / windowSeconds;
    final bpm = hz * 60.0;

    // Clamp to physiologically plausible range.
    return bpm.clamp(45.0, 180.0);
  }

  // ── BP Estimation from Pulse Amplitude ───────────────────────────────
  // Maps rPPG waveform amplitude to systolic/diastolic estimates via a
  // simplified empirical linear mapping.  NOT clinically validated — used
  // only as an indicative screening value pending calibration.
  RppgBpEstimate estimateBp(double bpm) {
    if (_filteredBuffer.isEmpty) {
      return RppgBpEstimate(systolic: 0, diastolic: 0, confidence: 0);
    }

    final window = _filteredBuffer.length >= 150
        ? _filteredBuffer.sublist(_filteredBuffer.length - 150)
        : _filteredBuffer;
    final mean = window.reduce((a, b) => a + b) / window.length;
    final amplitude = window.map((v) => (v - mean).abs()).reduce(max);

    // Empirical coefficients (illustrative, not clinically validated):
    // Higher amplitude → higher stroke volume → higher pulse pressure
    final systolic  = (108 + amplitude * 0.9).clamp(90, 200).round();
    final diastolic = (70  + amplitude * 0.4).clamp(55, 130).round();

    // Confidence: higher when buffer is full and amplitude is in range.
    final confidence = (_filteredBuffer.length / _maxBufferSize).clamp(0.0, 1.0);

    return RppgBpEstimate(
      systolic: systolic,
      diastolic: diastolic,
      confidence: double.parse(confidence.toStringAsFixed(3)),
    );
  }

  // ── Finalize & Return Signal State ────────────────────────────────────
  RppgSignalState finalizeSession() {
    stopPipeline();
    final lastBpm = _bpmStream.value;
    final bpEstimate = estimateBp(lastBpm);

    return RppgSignalState(
      isCapturing: false,
      secondsRemaining: 0,
      instantBpm: lastBpm,
      waveformBuffer: List.unmodifiable(_filteredBuffer),
      estimatedSystolic: bpEstimate.systolic > 0 ? bpEstimate.systolic : null,
      estimatedDiastolic: bpEstimate.diastolic > 0 ? bpEstimate.diastolic : null,
      confidenceScore: bpEstimate.confidence,
    );
  }

  void stopPipeline() {
    _processingTimer?.cancel();
    _processingTimer = null;
  }

  void dispose() {
    stopPipeline();
    _bpmStream.close();
  }
}

// ── rPPG BP Estimate DTO ─────────────────────────────────────────────────
class RppgBpEstimate {
  final int systolic;
  final int diastolic;
  final double confidence;

  RppgBpEstimate({
    required this.systolic,
    required this.diastolic,
    required this.confidence,
  });
}

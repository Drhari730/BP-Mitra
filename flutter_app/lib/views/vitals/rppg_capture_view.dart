// Module 3 – rPPG Vitals Capture View
// Camera wrapper with oval face alignment wireframe, 30-second countdown,
// real-time BPM display, and rPPG signal pipeline integration.

// packages: camera, flutter_bloc

import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../blocs/vitals/vitals_bloc.dart';
import '../../services/rppg_service.dart';
import '../../theme/app_theme.dart';

class RppgCaptureView extends StatefulWidget {
  const RppgCaptureView({super.key});

  @override
  State<RppgCaptureView> createState() => _RppgCaptureViewState();
}

class _RppgCaptureViewState extends State<RppgCaptureView>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _hasPermission = false;
  bool _isInitialized = false;

  Timer? _countdownTimer;
  int _secondsRemaining = 30;
  double _currentBpm = 0;
  StreamSubscription<double>? _bpmSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _hasPermission = false);
      return;
    }
    setState(() => _hasPermission = true);

    try {
      _cameras = await availableCameras();
      // Prefer front camera for face-based rPPG.
      final frontCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  void _startCapture() {
    context.read<VitalsBloc>().add(StartRppgCapture());
    RppgService.instance.startPipeline();

    _bpmSubscription = RppgService.instance.bpmStream.listen((bpm) {
      if (mounted) setState(() => _currentBpm = bpm);
    });

    _secondsRemaining = 30;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _secondsRemaining--);
      context.read<VitalsBloc>().add(RppgTickDown(
            secondsRemaining: _secondsRemaining,
            currentBpm: _currentBpm,
          ));
      if (_secondsRemaining <= 0) {
        timer.cancel();
        context.read<VitalsBloc>().add(CompleteRppgCapture());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _bpmSubscription?.cancel();
    _cameraController?.dispose();
    RppgService.instance.stopPipeline();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VitalsBloc, VitalsState>(
      listener: (context, state) {
        if (state is ReadingSaved) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Reading saved successfully'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ));
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Face Scan',
              style: TextStyle(color: AppTheme.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (!_hasPermission) {
      return _PermissionDeniedWidget(onRetry: _initCamera);
    }
    if (!_isInitialized || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.darkBlue),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Camera Preview ─────────────────────────────────────
        CameraPreview(_cameraController!),

        // ── Oval Face Alignment Wireframe ──────────────────────
        CustomPaint(painter: _FaceOvalPainter()),

        // ── Countdown + BPM Overlay ────────────────────────────
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              // Countdown ring
              _CountdownRing(
                secondsRemaining: _secondsRemaining,
                totalSeconds: 30,
              ),
              const SizedBox(height: 16),
              // Live BPM readout
              if (_currentBpm > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '${_currentBpm.toStringAsFixed(0)} BPM',
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Instruction Strip ──────────────────────────────────
        Positioned(
          bottom: 80,
          left: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black70,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Position your face within the oval frame. '
              'Hold still and breathe naturally for accurate results.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.white,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ),

        // ── Start Button ───────────────────────────────────────
        Positioned(
          bottom: 20,
          left: 40,
          right: 40,
          child: BlocBuilder<VitalsBloc, VitalsState>(
            builder: (context, state) {
              final isCapturing = state is RppgCapturing;
              return ElevatedButton(
                onPressed: isCapturing ? null : _startCapture,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCapturing
                      ? Colors.white24
                      : AppTheme.darkBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  isCapturing
                      ? 'Scanning... ${_secondsRemaining}s'
                      : 'Start 30-Second Scan',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Oval Face Alignment Painter ─────────────────────────────────────────
class _FaceOvalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.42;
    final rx = size.width * 0.35;
    final ry = size.height * 0.30;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Oval wireframe
    canvas.drawOval(Rect.fromCenter(
      center: Offset(cx, cy),
      width: rx * 2,
      height: ry * 2,
    ), paint);

    // Corner alignment guides
    final cornerPaint = Paint()
      ..color = const Color(0xFF60A5FA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 24.0;
    final corners = [
      // Top-left
      [Offset(cx - rx, cy - ry + cornerLength), Offset(cx - rx, cy - ry),
       Offset(cx - rx + cornerLength, cy - ry)],
      // Top-right
      [Offset(cx + rx - cornerLength, cy - ry), Offset(cx + rx, cy - ry),
       Offset(cx + rx, cy - ry + cornerLength)],
      // Bottom-left
      [Offset(cx - rx, cy + ry - cornerLength), Offset(cx - rx, cy + ry),
       Offset(cx - rx + cornerLength, cy + ry)],
      // Bottom-right
      [Offset(cx + rx - cornerLength, cy + ry), Offset(cx + rx, cy + ry),
       Offset(cx + rx, cy + ry - cornerLength)],
    ];

    for (final corner in corners) {
      final path = Path()
        ..moveTo(corner[0].dx, corner[0].dy)
        ..lineTo(corner[1].dx, corner[1].dy)
        ..lineTo(corner[2].dx, corner[2].dy);
      canvas.drawPath(path, cornerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Circular Countdown Ring ──────────────────────────────────────────────
class _CountdownRing extends StatelessWidget {
  final int secondsRemaining;
  final int totalSeconds;

  const _CountdownRing({
    required this.secondsRemaining,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final progress = secondsRemaining / totalSeconds;

    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 5,
            color: AppTheme.darkBlue,
            backgroundColor: Colors.white24,
          ),
          Text(
            '$secondsRemaining',
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionDeniedWidget extends StatelessWidget {
  final VoidCallback onRetry;
  const _PermissionDeniedWidget({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined,
                size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            const Text(
              'Camera permission required for rPPG face scan',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }
}

// Module 5 – AI Clinical Assistant View
// Collects current health stats from sliders/inputs, submits to the
// deterministic rule engine, and displays the profile-matched diagnosis.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/ai_assistant/ai_assistant_bloc.dart';
import '../../blocs/activity/activity_bloc.dart';
import '../../blocs/diet/diet_bloc.dart';
import '../../blocs/medication/medication_bloc.dart';
import '../../blocs/vitals/vitals_bloc.dart';
import '../../models/ai_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';

class AiAssistantView extends StatefulWidget {
  const AiAssistantView({super.key});

  @override
  State<AiAssistantView> createState() => _AiAssistantViewState();
}

class _AiAssistantViewState extends State<AiAssistantView> {
  final _systolicCtrl = TextEditingController(text: '130');
  final _diastolicCtrl = TextEditingController(text: '85');
  int _qolScore = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: Column(
        children: [
          AppHeader(
            title: 'AI Clinical Assistant',
            subtitle: 'Parametric health analysis',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header Description ────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.headerGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.psychology, color: AppTheme.white, size: 32),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Parametric Analysis Engine',
                                style: TextStyle(
                                  color: AppTheme.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Evaluates your real-time health profile and '
                                'generates personalised clinical recommendations.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Current BP Input ──────────────────────────────
                  Text('Current BP Reading',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _systolicCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Systolic (mmHg)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _diastolicCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Diastolic (mmHg)',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Quality of Life / Fatigue Score ───────────────
                  Text('Today\'s Energy & Fatigue Level',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Great', style: TextStyle(fontSize: 12, color: AppTheme.successGreen)),
                      Expanded(
                        child: Slider(
                          value: _qolScore.toDouble(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                          activeColor: _qolColor(_qolScore),
                          label: _qolLabel(_qolScore),
                          onChanged: (v) => setState(() => _qolScore = v.round()),
                        ),
                      ),
                      const Text('Exhausted', style: TextStyle(fontSize: 12, color: AppTheme.errorRed)),
                    ],
                  ),
                  Center(
                    child: Text(
                      _qolLabel(_qolScore),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _qolColor(_qolScore),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Pre-populated Data Summary ────────────────────
                  _DataSummaryCard(
                    systolic: int.tryParse(_systolicCtrl.text) ?? 130,
                    diastolic: int.tryParse(_diastolicCtrl.text) ?? 85,
                    qolScore: _qolScore,
                  ),

                  const SizedBox(height: 24),

                  // ── Evaluate Button ───────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: BlocBuilder<AiAssistantBloc, AiAssistantState>(
                      builder: (context, state) {
                        return ElevatedButton.icon(
                          onPressed: state is AiAssistantLoading
                              ? null
                              : _evaluate,
                          icon: state is AiAssistantLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: AppTheme.white,
                                    strokeWidth: 2,
                                  ))
                              : const Icon(Icons.auto_awesome),
                          label: Text(state is AiAssistantLoading
                              ? 'Analysing...'
                              : 'Run AI Analysis'),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Result Card ───────────────────────────────────
                  BlocBuilder<AiAssistantBloc, AiAssistantState>(
                    builder: (context, state) {
                      if (state is AiAssistantResult) {
                        return _ResultCard(result: state.result);
                      }
                      if (state is AiAssistantError) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(state.message,
                              style: const TextStyle(color: AppTheme.errorRed)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _evaluate() {
    // Pull live data from sibling BLoCs.
    int steps = 0;
    double sodiumMg = 0;
    int adherenceRate = 100;

    final activityState = context.read<ActivityBloc>().state;
    if (activityState is ActivityTracking) {
      steps = activityState.pedometer.totalStepsToday;
    }

    final dietState = context.read<DietBloc>().state;
    if (dietState is DietLoaded) {
      sodiumMg = dietState.sodiumSummary.totalSodiumMg;
    }

    final medState = context.read<MedicationBloc>().state;
    if (medState is MedicationLoaded) {
      adherenceRate = medState.summary.adherenceRatePercentage;
    }

    context.read<AiAssistantBloc>().add(EvaluateHealthProfile(AiInputPayload(
      currentSystolic: int.tryParse(_systolicCtrl.text) ?? 130,
      currentDiastolic: int.tryParse(_diastolicCtrl.text) ?? 85,
      adherenceRatePercentage: adherenceRate,
      dailySodiumIntakeMg: sodiumMg,
      activeSteps: steps,
      qolFatigueScore: _qolScore,
    )));
  }

  Color _qolColor(int score) {
    if (score <= 2) return AppTheme.successGreen;
    if (score == 3) return AppTheme.warningAmber;
    return AppTheme.errorRed;
  }

  String _qolLabel(int score) {
    switch (score) {
      case 1: return 'Excellent energy';
      case 2: return 'Feeling good';
      case 3: return 'Moderate fatigue';
      case 4: return 'High fatigue';
      case 5: return 'Severely exhausted';
      default: return '';
    }
  }
}

// ── Data Summary Pre-populate Card ──────────────────────────────────────
class _DataSummaryCard extends StatelessWidget {
  final int systolic;
  final int diastolic;
  final int qolScore;

  const _DataSummaryCard({
    required this.systolic,
    required this.diastolic,
    required this.qolScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.softBluePill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data being evaluated:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.midSlate,
            ),
          ),
          const SizedBox(height: 10),
          BlocBuilder<ActivityBloc, ActivityState>(
            builder: (context, state) {
              final steps = state is ActivityTracking
                  ? state.pedometer.totalStepsToday
                  : 0;
              return _DataRow(label: 'Active Steps', value: '$steps steps');
            },
          ),
          BlocBuilder<DietBloc, DietState>(
            builder: (context, state) {
              final sodium = state is DietLoaded
                  ? '${state.sodiumSummary.totalSodiumMg.toStringAsFixed(0)}mg'
                  : '0mg';
              return _DataRow(label: 'Sodium Intake', value: sodium);
            },
          ),
          BlocBuilder<MedicationBloc, MedicationState>(
            builder: (context, state) {
              final rate = state is MedicationLoaded
                  ? '${state.summary.adherenceRatePercentage}%'
                  : '–';
              return _DataRow(label: 'Adherence Rate', value: rate);
            },
          ),
          _DataRow(label: 'BP Reading', value: '$systolic/$diastolic mmHg'),
          _DataRow(label: 'Fatigue Score', value: '$qolScore / 5'),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  const _DataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 5, color: AppTheme.darkBlue),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppTheme.midSlate)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkSlate,
              )),
        ],
      ),
    );
  }
}

// ── AI Result Display Card ───────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final AiEvaluationResult result;
  const _ResultCard({required this.result});

  Color get _profileColor {
    switch (result.profile) {
      case 'A': return AppTheme.errorRed;
      case 'B': return AppTheme.warningAmber;
      case 'C': return const Color(0xFF8B5CF6);
      default:  return AppTheme.successGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _profileColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _profileColor.withOpacity(0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _profileColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  result.profileLabel,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.psychology, color: _profileColor, size: 20),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            result.responseText,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.darkSlate,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

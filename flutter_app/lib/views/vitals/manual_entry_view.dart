// Module 3 – Manual BP Entry View
// Clean form for logging standard cuff readings with validation.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/vitals/vitals_bloc.dart';
import '../../theme/app_theme.dart';

class ManualEntryView extends StatefulWidget {
  const ManualEntryView({super.key});

  @override
  State<ManualEntryView> createState() => _ManualEntryViewState();
}

class _ManualEntryViewState extends State<ManualEntryView> {
  final _formKey = GlobalKey<FormState>();
  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _pulseCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: const Text('Manual BP Entry'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: BlocListener<VitalsBloc, VitalsState>(
        listener: (context, state) {
          if (state is ReadingSaved) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Reading saved!'),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
            ));
            context.pop();
          }
          if (state is VitalsError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Illustration header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.softBluePill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monitor_heart_outlined,
                          size: 40, color: AppTheme.darkBlue),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cuff Measurement',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.darkSlate,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Sit quietly for 5 minutes before measuring. '
                              'Rest your arm at heart level.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.midSlate,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── BP Inputs ────────────────────────────────────────
                const Text(
                  'Blood Pressure',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.midSlate,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _systolicCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Systolic',
                          suffixText: 'mmHg',
                          hintText: '120',
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 70 || n > 250) {
                            return 'Enter 70–250';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _diastolicCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Diastolic',
                          suffixText: 'mmHg',
                          hintText: '80',
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 40 || n > 160) {
                            return 'Enter 40–160';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Pulse ─────────────────────────────────────────────
                TextFormField(
                  controller: _pulseCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Pulse (optional)',
                    suffixText: 'BPM',
                    hintText: '72',
                    prefixIcon: Icon(Icons.favorite_border),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final n = int.tryParse(v);
                    if (n == null || n < 30 || n > 250) return 'Enter 30–250';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ── Notes ─────────────────────────────────────────────
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'e.g., after exercise, felt stressed...',
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 32),

                // ── BP Classification Helper ──────────────────────────
                _BpReferenceCard(),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: BlocBuilder<VitalsBloc, VitalsState>(
                    builder: (context, state) {
                      return ElevatedButton.icon(
                        onPressed: state is VitalsLoading ? null : _submit,
                        icon: state is VitalsLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: AppTheme.white,
                                  strokeWidth: 2,
                                ))
                            : const Icon(Icons.save_outlined),
                        label: Text(state is VitalsLoading
                            ? 'Saving...'
                            : 'Save Reading'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<VitalsBloc>().add(SubmitManualReading(
          systolic: int.parse(_systolicCtrl.text.trim()),
          diastolic: int.parse(_diastolicCtrl.text.trim()),
          pulse: _pulseCtrl.text.trim().isEmpty
              ? null
              : int.parse(_pulseCtrl.text.trim()),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        ));
  }

  @override
  void dispose() {
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
    _pulseCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}

class _BpReferenceCard extends StatelessWidget {
  final List<Map<String, dynamic>> _categories = const [
    {'label': 'Normal', 'range': '<120/80', 'color': Color(0xFF38A169)},
    {'label': 'Elevated', 'range': '120–129/<80', 'color': Color(0xFFD69E2E)},
    {'label': 'Stage 1', 'range': '130–139/80–89', 'color': Color(0xFFED8936)},
    {'label': 'Stage 2', 'range': '≥140/≥90', 'color': Color(0xFFE53E3E)},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'JNC 8 Classification',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 10),
          ..._categories.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: c['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c['label'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                    ),
                    Text(
                      c['range'] as String,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.midSlate),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

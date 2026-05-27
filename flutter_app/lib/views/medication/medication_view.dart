// Module 1 – Treatment Planner View
// Vertical timeline of today's scheduled doses with swipe-to-log actions.
// Swipe right → mark Taken; swipe left → mark Skipped.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../blocs/medication/medication_bloc.dart';
import '../../models/medication_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';

class MedicationView extends StatefulWidget {
  const MedicationView({super.key});

  @override
  State<MedicationView> createState() => _MedicationViewState();
}

class _MedicationViewState extends State<MedicationView> {
  @override
  void initState() {
    super.initState();
    context.read<MedicationBloc>().add(LoadSchedules());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: Column(
        children: [
          AppHeader(
            title: 'Treatment Planner',
            subtitle: 'Your medication schedule',
            action: IconButton(
              icon: const Icon(Icons.add, color: AppTheme.white),
              onPressed: _showAddScheduleSheet,
            ),
          ),
          Expanded(
            child: BlocConsumer<MedicationBloc, MedicationState>(
              listener: (context, state) {
                if (state is DoseLogged) {
                  final msg = state.status == AdherenceStatus.taken
                      ? '✓ Dose marked as Taken'
                      : '✗ Dose marked as Skipped';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: state.status == AdherenceStatus.taken
                          ? AppTheme.successGreen
                          : AppTheme.warningAmber,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
                if (state is MedicationLoaded &&
                    state.sevenDayMilestoneJustReached) {
                  _showStreakDialog(state.streakDays);
                }
              },
              builder: (context, state) {
                if (state is MedicationLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.darkBlue),
                  );
                }
                if (state is MedicationError) {
                  return Center(child: Text(state.message));
                }
                if (state is MedicationLoaded) {
                  return _buildTimeline(state);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(MedicationLoaded state) {
    if (state.schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medication_outlined,
                size: 64, color: AppTheme.lightSlate),
            const SizedBox(height: 16),
            Text('No medications scheduled',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Tap + to add your first medication',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ── Adherence Summary Banner ─────────────────────────────────
        _AdherenceBanner(summary: state.summary, streakDays: state.streakDays),

        // ── Timeline List ────────────────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: state.schedules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final schedule = state.schedules[index];

              // Determine today's log status for this schedule.
              final todayLogs = state.recentLogs.where((l) =>
                  l.scheduleId == schedule.id &&
                  l.scheduledAt.day == DateTime.now().day);
              final latestStatus =
                  todayLogs.isNotEmpty ? todayLogs.last.status : null;

              return _DoseTimelineTile(
                schedule: schedule,
                loggedStatus: latestStatus,
                onTaken: () => context.read<MedicationBloc>().add(LogDose(
                      scheduleId: schedule.id,
                      status: AdherenceStatus.taken,
                      scheduledAt: _scheduledDateTimeForToday(
                          schedule.scheduledTime),
                    )),
                onSkipped: () => context.read<MedicationBloc>().add(LogDose(
                      scheduleId: schedule.id,
                      status: AdherenceStatus.skipped,
                      scheduledAt: _scheduledDateTimeForToday(
                          schedule.scheduledTime),
                    )),
              );
            },
          ),
        ),
      ],
    );
  }

  DateTime _scheduledDateTimeForToday(String scheduledTime) {
    final parts = scheduledTime.split(':');
    final now = DateTime.now();
    return DateTime(
        now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  void _showStreakDialog(int days) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 Streak Milestone!'),
        content: Text(
          'Excellent focus! You\'ve maintained a $days-day streak. '
          'Your vascular compliance metrics look highly stable!',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep it up!'),
          ),
        ],
      ),
    );
  }

  void _showAddScheduleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddScheduleSheet(),
    );
  }
}

// ── Adherence Summary Banner ─────────────────────────────────────────────
class _AdherenceBanner extends StatelessWidget {
  final AdherenceSummary summary;
  final int streakDays;

  const _AdherenceBanner({required this.summary, required this.streakDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.softBluePill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${summary.adherenceRatePercentage}% adherence',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '7-day summary: ${summary.taken} taken · ${summary.missed} missed',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.midSlate,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 28)),
              Text(
                '$streakDays days',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkSlate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Dose Timeline Tile with Swipe Actions ────────────────────────────────
class _DoseTimelineTile extends StatelessWidget {
  final MedicationSchedule schedule;
  final AdherenceStatus? loggedStatus;
  final VoidCallback onTaken;
  final VoidCallback onSkipped;

  const _DoseTimelineTile({
    required this.schedule,
    required this.loggedStatus,
    required this.onTaken,
    required this.onSkipped,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('dose_${schedule.id}_${DateTime.now().day}'),
      // Swipe right → Taken
      background: _swipeBackground(
        alignment: Alignment.centerLeft,
        color: AppTheme.successGreen,
        icon: Icons.check_rounded,
        label: 'Taken',
      ),
      // Swipe left → Skipped
      secondaryBackground: _swipeBackground(
        alignment: Alignment.centerRight,
        color: AppTheme.warningAmber,
        icon: Icons.close_rounded,
        label: 'Skip',
      ),
      confirmDismiss: (direction) async {
        if (loggedStatus != null) return false; // Already logged
        if (direction == DismissDirection.startToEnd) {
          onTaken();
        } else {
          onSkipped();
        }
        return false; // Don't actually remove from list
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cardShadow,
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: _TimeIndicator(time: schedule.scheduledTime),
          title: Text(
            schedule.displayDosage,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkSlate,
            ),
          ),
          subtitle: Text(
            '${schedule.drugClass} · every ${schedule.frequencyHours}h',
            style: const TextStyle(fontSize: 12, color: AppTheme.midSlate),
          ),
          trailing: _StatusBadge(status: loggedStatus, isCritical: schedule.isCritical),
        ),
      ),
    );
  }

  Widget _swipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TimeIndicator extends StatelessWidget {
  final String time; // "HH:MM"

  const _TimeIndicator({required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppTheme.softBluePill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          _formatTime(time),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkBlue,
          ),
        ),
      ),
    );
  }

  String _formatTime(String hhmm) {
    final parts = hhmm.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute\n$period';
  }
}

class _StatusBadge extends StatelessWidget {
  final AdherenceStatus? status;
  final bool isCritical;

  const _StatusBadge({required this.status, required this.isCritical});

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isCritical)
            const Icon(Icons.priority_high, size: 14, color: AppTheme.errorRed),
          const SizedBox(height: 2),
          const Text(
            'Swipe to log',
            style: TextStyle(fontSize: 10, color: AppTheme.lightSlate),
          ),
        ],
      );
    }

    Color badgeColor;
    String label;
    switch (status!) {
      case AdherenceStatus.taken:
        badgeColor = AppTheme.successGreen;
        label = 'Taken';
        break;
      case AdherenceStatus.skipped:
        badgeColor = AppTheme.warningAmber;
        label = 'Skipped';
        break;
      case AdherenceStatus.missed:
        badgeColor = AppTheme.errorRed;
        label = 'Missed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }
}

// ── Add Schedule Bottom Sheet ────────────────────────────────────────────
class _AddScheduleSheet extends StatefulWidget {
  const _AddScheduleSheet();

  @override
  State<_AddScheduleSheet> createState() => _AddScheduleSheetState();
}

class _AddScheduleSheetState extends State<_AddScheduleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _medNameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  int _frequencyHours = 24;
  TimeOfDay _scheduledTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isCritical = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Medication',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkSlate,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _medNameCtrl,
              decoration: const InputDecoration(labelText: 'Medication Name'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dosageCtrl,
              decoration: const InputDecoration(labelText: 'Dosage (mg)'),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  (v == null || double.tryParse(v) == null) ? 'Enter valid dosage' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _frequencyHours,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: const [
                DropdownMenuItem(value: 24, child: Text('Once daily')),
                DropdownMenuItem(value: 12, child: Text('Twice daily')),
                DropdownMenuItem(value: 8, child: Text('Three times daily')),
              ],
              onChanged: (v) => setState(() => _frequencyHours = v!),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Scheduled Time'),
              trailing: TextButton(
                onPressed: _pickTime,
                child: Text(
                  _scheduledTime.format(context),
                  style: const TextStyle(
                    color: AppTheme.darkBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Critical Medication'),
              subtitle: const Text('Enables 45-min escalation alerts'),
              value: _isCritical,
              onChanged: (v) => setState(() => _isCritical = v),
              activeColor: AppTheme.darkBlue,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Save Medication'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );
    if (picked != null) {
      setState(() => _scheduledTime = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final timeStr =
        '${_scheduledTime.hour.toString().padLeft(2, '0')}:${_scheduledTime.minute.toString().padLeft(2, '0')}';

    context.read<MedicationBloc>().add(CreateSchedule({
      'med_name': _medNameCtrl.text.trim(),
      'dosage_mg': double.parse(_dosageCtrl.text.trim()),
      'frequency_hours': _frequencyHours,
      'scheduled_time': timeStr,
      'is_critical': _isCritical,
    }));

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _medNameCtrl.dispose();
    _dosageCtrl.dispose();
    super.dispose();
  }
}

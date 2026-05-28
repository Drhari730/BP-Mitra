// Module 3 – Vitals Overview View
// Shows latest reading, trend chart (fl_chart dual-line systolic/diastolic),
// and navigation to rPPG capture and manual entry.

// packages: fl_chart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../blocs/vitals/vitals_bloc.dart';
import '../../models/vitals_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';

class VitalsView extends StatefulWidget {
  const VitalsView({super.key});

  @override
  State<VitalsView> createState() => _VitalsViewState();
}

class _VitalsViewState extends State<VitalsView> {
  int _trendDays = 30;

  @override
  void initState() {
    super.initState();
    context.read<VitalsBloc>().add(LoadReadings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: Column(
        children: [
          AppHeader(
            title: 'Vitals & BP Trends',
            subtitle: 'Blood pressure history',
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppTheme.white),
                  onPressed: () => context.push('/vitals/manual'),
                  tooltip: 'Manual Entry',
                ),
                IconButton(
                  icon: const Icon(Icons.face_retouching_natural,
                      color: AppTheme.white),
                  onPressed: () => context.push('/vitals/rppg'),
                  tooltip: 'rPPG Scan',
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<VitalsBloc, VitalsState>(
              builder: (context, state) {
                if (state is VitalsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.darkBlue),
                  );
                }
                if (state is VitalsLoaded) {
                  return _buildContent(state);
                }
                if (state is VitalsError) {
                  return Center(child: Text(state.message));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(VitalsLoaded state) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Latest Reading Card ─────────────────────────────────
          if (state.latestReading != null)
            _LatestReadingCard(reading: state.latestReading!),

          const SizedBox(height: 16),

          // ── Trend Period Selector ───────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'BP Trend Chart',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 7, label: Text('7d')),
                    ButtonSegment(value: 30, label: Text('30d')),
                    ButtonSegment(value: 90, label: Text('90d')),
                  ],
                  selected: {_trendDays},
                  onSelectionChanged: (selection) {
                    setState(() => _trendDays = selection.first);
                    context.read<VitalsBloc>().add(LoadTrend(days: _trendDays));
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Dual-Line BP Trend Chart ────────────────────────────
          _BpTrendChart(trend: state.trend),

          // ── Legend ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: AppTheme.errorRed, label: 'Systolic'),
                const SizedBox(width: 24),
                _LegendItem(color: AppTheme.darkBlue, label: 'Diastolic'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Reading History List ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Recent Readings',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          ...state.readings.take(10).map(
                (r) => _ReadingListTile(reading: r),
              ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Latest Reading Hero Card ─────────────────────────────────────────────
class _LatestReadingCard extends StatelessWidget {
  final BpReading reading;
  const _LatestReadingCard({required this.reading});

  Color get _categoryColor {
    switch (reading.bpCategory) {
      case 'Normal':         return AppTheme.successGreen;
      case 'Elevated':       return AppTheme.warningAmber;
      case 'Stage 1':        return const Color(0xFFED8936);
      default:               return AppTheme.errorRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                reading.displayValue,
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('mmHg',
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _categoryColor.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _categoryColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      reading.bpCategory,
                      style: TextStyle(
                        color: _categoryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (reading.pulseBpm != null) ...[
                const Icon(Icons.favorite, color: Colors.white60, size: 14),
                const SizedBox(width: 4),
                Text('${reading.pulseBpm} BPM',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(width: 16),
              ],
              Icon(
                reading.source == ReadingSource.rppg
                    ? Icons.face_retouching_natural
                    : Icons.edit_outlined,
                color: Colors.white60,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                reading.source == ReadingSource.rppg ? 'rPPG Scan' : 'Manual',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Spacer(),
              Text(
                DateFormat('d MMM, h:mm a').format(reading.measuredAt.toLocal()),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Dual-Line Trend Chart ────────────────────────────────────────────────
class _BpTrendChart extends StatelessWidget {
  final List<BpTrendPoint> trend;
  const _BpTrendChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text('No trend data yet',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }

    final systolicSpots = trend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.avgSystolic.toDouble());
    }).toList();

    final diastolicSpots = trend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.avgDiastolic.toDouble());
    }).toList();

    final maxY = (trend.map((t) => t.avgSystolic).reduce((a, b) => a > b ? a : b) + 20).toDouble();
    final minY = (trend.map((t) => t.avgDiastolic).reduce((a, b) => a < b ? a : b) - 20).toDouble().clamp(40.0, 60.0);

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 8, 24, 8),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (trend.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            horizontalInterval: 20,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: const Color(0xFFF1F5F9),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                reservedSize: 36,
                getTitlesWidget: (value, _) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.lightSlate,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (trend.length / 5).clamp(1, 30).toDouble(),
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= trend.length) return const SizedBox();
                  return Text(
                    DateFormat('d/M').format(trend[index].date),
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.lightSlate),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            // Systolic – upper line, red
            LineChartBarData(
              spots: systolicSpots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppTheme.errorRed,
              barWidth: 2.5,
              dotData: FlDotData(
                show: trend.length <= 14,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3,
                  color: AppTheme.errorRed,
                  strokeColor: AppTheme.white,
                  strokeWidth: 1.5,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.errorRed.withOpacity(0.12),
                    AppTheme.errorRed.withOpacity(0.01),
                  ],
                ),
              ),
            ),
            // Diastolic – lower line, dark blue
            LineChartBarData(
              spots: diastolicSpots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppTheme.darkBlue,
              barWidth: 2.5,
              dotData: FlDotData(
                show: trend.length <= 14,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3,
                  color: AppTheme.darkBlue,
                  strokeColor: AppTheme.white,
                  strokeWidth: 1.5,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.darkBlue.withOpacity(0.08),
                    AppTheme.darkBlue.withOpacity(0.01),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final label = spot.barIndex == 0 ? 'SYS' : 'DIA';
                  return LineTooltipItem(
                    '$label ${spot.y.toInt()}',
                    TextStyle(
                      color: spot.barIndex == 0
                          ? AppTheme.errorRed
                          : AppTheme.darkBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppTheme.midSlate)),
      ],
    );
  }
}

class _ReadingListTile extends StatelessWidget {
  final BpReading reading;
  const _ReadingListTile({required this.reading});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            reading.displayValue,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(width: 8),
          const Text('mmHg',
              style: TextStyle(fontSize: 12, color: AppTheme.lightSlate)),
          const Spacer(),
          Icon(
            reading.source == ReadingSource.rppg
                ? Icons.face_retouching_natural
                : Icons.edit_outlined,
            size: 14,
            color: AppTheme.lightSlate,
          ),
          const SizedBox(width: 6),
          Text(
            DateFormat('d MMM, h:mm a').format(reading.measuredAt.toLocal()),
            style: const TextStyle(fontSize: 12, color: AppTheme.lightSlate),
          ),
        ],
      ),
    );
  }
}

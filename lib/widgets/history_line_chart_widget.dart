import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HistoryLineChart extends StatelessWidget {
  final List<DateTime> dates;
  final List<double> scores; // 0..100
  const HistoryLineChart({super.key, required this.dates, required this.scores});

  @override
  Widget build(BuildContext context) {
    if (dates.isEmpty || scores.isEmpty) {
      return const Center(child: Text('Chưa có lịch sử'));
    }
    final spots = <FlSpot>[];
    for (var i = 0; i < scores.length; i++) {
      spots.add(FlSpot(i.toDouble(), scores[i].clamp(0, 100)));
    }
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: (scores.length / 4).clamp(1, 5).toDouble(),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= dates.length) return const SizedBox();
                final d = dates[idx];
                final label = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
                return SideTitleWidget(axisSide: meta.axisSide, child: Text(label, style: const TextStyle(fontSize: 10)));
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            spots: spots,
            barWidth: 3,
            color: Theme.of(context).colorScheme.primary,
            belowBarData: BarAreaData(show: true, color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
            dotData: const FlDotData(show: true),
          )
        ],
      ),
    );
  }
}

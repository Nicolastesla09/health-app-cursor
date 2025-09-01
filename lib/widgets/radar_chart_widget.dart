import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/analysis.dart';
import '../l10n.dart';

class HealthRadarChart extends StatelessWidget {
  final List<HealthCategory> categories;
  final bool compact;
  const HealthRadarChart({super.key, required this.categories, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(child: Text('Không có dữ liệu biểu đồ'));
    }
    final lang = AppStringsScope.of(context);
    final titles = categories.map((e) => _localizedCategory(e.categoryName, lang)).toList();
    final values = categories
        .map((e) => math.min(10.0, math.max(0.0, e.score.toDouble())))
        .toList();

    // Background zones (good/moderate/poor)
    const good = 10.0;
    const moderate = 7.0;
    const poor = 4.0;

    final cs = Theme.of(context).colorScheme;
    final zoneGood = cs.primary.withOpacity(0.10);
    final zoneModerate = const Color(0xFFFDCB6E).withOpacity(0.18); // yellow-ish
    final zonePoor = const Color(0xFFEF5350).withOpacity(0.15); // red-ish

    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      // Responsive label placement: closer for smaller charts, slightly farther for wider charts.
      final titleOffset = compact
          ? 0.68
          : (w < 300
              ? 0.70
              : (w < 360 ? 0.72 : 0.74));
      final fs = compact
          ? (w < 300 ? 7.0 : 7.5)
          : (w < 320 ? 8.0 : 9.0);

      return RadarChart(
        RadarChartData(
          radarBackgroundColor: Colors.transparent,
          radarBorderData: const BorderSide(color: Colors.transparent),
          tickBorderData: const BorderSide(color: Colors.transparent),
          gridBorderData: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.25)),
          titleTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: fs),
          titlePositionPercentageOffset: titleOffset,
          tickCount: 5,
          radarShape: RadarShape.polygon,
          dataSets: [
            RadarDataSet(
              dataEntries: [for (var _ in titles) const RadarEntry(value: good)],
              borderColor: Colors.transparent,
              fillColor: zoneGood,
            ),
            RadarDataSet(
              dataEntries: [for (var _ in titles) const RadarEntry(value: moderate)],
              borderColor: Colors.transparent,
              fillColor: zoneModerate,
            ),
            RadarDataSet(
              dataEntries: [for (var _ in titles) const RadarEntry(value: poor)],
              borderColor: Colors.transparent,
              fillColor: zonePoor,
            ),
            RadarDataSet(
              fillColor: cs.primary.withOpacity(0.20),
              borderColor: cs.primary,
              entryRadius: compact ? 2 : 3,
              dataEntries: [for (final v in values) RadarEntry(value: v.toDouble())],
            ),
          ],
          getTitle: (index, angle) {
            final t = titles[index];
            final words = t.split(' ');
            String short;
            if (t.length <= 12) {
              short = t;
            } else if (words.length > 1) {
              final mid = (words.length / 2).floor();
              short = words.sublist(0, mid).join(' ') + '\n' + words.sublist(mid).join(' ');
            } else {
              short = t.substring(0, 12) + '\n' + t.substring(12);
            }
            return RadarChartTitle(text: short);
          },
          radarTouchData: RadarTouchData(enabled: false),
        ),
      );
    });
  }

  String _localizedCategory(String name, AppLang lang) {
    if (lang == AppLang.vi) return name;
    final n = name.toLowerCase();
    if (n.contains('thận') || n.contains('tiet nieu') || n.contains('tiết niệu')) return 'Kidney';
    if (n.contains('gan')) return 'Liver';
    if (n.contains('tim') || n.contains('mạch') || n.contains('tim mạch')) return 'Cardio';
    if (n.contains('huyết') || n.contains('huyet')) return 'Hematology';
    if (n.contains('chuyển hoá') || n.contains('chuyển hóa') || n.contains('chuyen hoa')) return 'Metabolism';
    if (n.contains('tiết niệu')) return 'Urinary';
    if (n.contains('tổng quan') || n.contains('tong quan')) return 'Overall';
    if (n.contains('bmi') || n.contains('cân nặng')) return 'BMI & Weight';
    return name; // fallback
  }
}

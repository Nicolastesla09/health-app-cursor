import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/analysis.dart';
import '../l10n.dart';

class HealthRadarChart extends StatefulWidget {
  final List<HealthCategory> categories;
  final bool compact;
  final String? title;
  const HealthRadarChart({super.key, required this.categories, this.compact = false, this.title});

  @override
  State<HealthRadarChart> createState() => _HealthRadarChartState();
}

class _HealthRadarChartState extends State<HealthRadarChart> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    // Start animation after a small delay to allow widget to build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return const Center(child: Text('Không có dữ liệu biểu đồ'));
    }
    final lang = AppStringsScope.of(context);
    final titles = widget.categories.map((e) => _localizedCategory(e.categoryName, lang)).toList();
    final values = widget.categories
        .map((e) => math.min(10.0, math.max(0.0, e.score.toDouble())))
        .toList();

    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      
      // Điều chỉnh khoảng cách chữ gần với đỉnh của biểu đồ
      final titleOffset = widget.compact
          ? (w < 200 ? 1.08 : (w < 280 ? 1.1 : 1.12))
          : (w < 300 ? 1.12 : (w < 400 ? 1.14 : 1.16));
      
      final fs = widget.compact
          ? (w < 200 ? 6.5 : (w < 280 ? 7.0 : 7.5))
          : (w < 300 ? 7.5 : (w < 400 ? 8.0 : 8.5));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
              child: Text(
                widget.title!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3436),
                ),
              ),
            ),
          ],
          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  width: w,
                  height: h,
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFFF8F9FA), // Light beige center
                        Color(0xFFE8F5E8), // Light yellowish-green
                        Color(0xFFD4F1D4), // Light green
                        Color(0xFFC8E6C8), // Outer light green
                      ],
                      stops: [0.0, 0.3, 0.7, 1.0],
                      center: Alignment.center,
                      radius: 0.8,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: RadarChart(
                      RadarChartData(
                        radarBackgroundColor: Colors.transparent,
                        radarBorderData: const BorderSide(color: Colors.transparent),
                        tickBorderData: const BorderSide(color: Colors.transparent),
                        gridBorderData: const BorderSide(
                          color: Color(0xFFE0E0E0),
                          width: 0.5,
                        ),
                        titleTextStyle: TextStyle(
                          fontSize: fs,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2D3436),
                          height: 1.1,
                        ),
                        titlePositionPercentageOffset: titleOffset,
                        tickCount: 6, // 0, 2, 4, 6, 8, 10
                        ticksTextStyle: TextStyle(
                          fontSize: widget.compact ? 6.0 : 7.0,
                          color: const Color(0xFF2D3436).withOpacity(0.6),
                        ),
                        radarShape: RadarShape.polygon,
                        dataSets: [
                          // Actual data with animation - green line like in the image
                          RadarDataSet(
                            fillColor: const Color(0xFF4CAF50).withOpacity(0.2 * _animation.value),
                            borderColor: const Color(0xFF4CAF50), // Green color from image
                            borderWidth: (widget.compact ? 2.0 : 2.5) * _animation.value,
                            entryRadius: (widget.compact ? 2.5 : 3.0) * _animation.value,
                            dataEntries: [for (final v in values) RadarEntry(value: v.toDouble() * _animation.value)],
                          ),
                        ],
                        getTitle: (index, angle) {
                          final t = titles[index];
                          final short = _shortenTitle(t, widget.compact);
                          return RadarChartTitle(
                            text: short,
                            positionPercentageOffset: titleOffset,
                          );
                        },
                        radarTouchData: RadarTouchData(enabled: false),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  // Thu ngắn và tối ưu title cho mobile
  String _shortenTitle(String title, bool compact) {
    if (title.length <= (compact ? 10 : 12)) {
      return title;
    }
    
    final words = title.split(' ');
    if (words.length == 1) {
      // Single word - break by characters
      final maxLen = compact ? 8 : 10;
      if (title.length <= maxLen) return title;
      return title.substring(0, maxLen - 1) + '\n' + title.substring(maxLen - 1);
    }
    
    // Multiple words - smart break
    if (words.length == 2) {
      return '${words[0]}\n${words[1]}';
    }
    
    // More than 2 words - group intelligently
    final mid = (words.length / 2).ceil();
    final firstPart = words.sublist(0, mid).join(' ');
    final secondPart = words.sublist(mid).join(' ');
    
    final maxLineLen = compact ? 8 : 10;
    if (firstPart.length > maxLineLen || secondPart.length > maxLineLen) {
      // If either part is too long, use first word only
      return '${words[0]}\n${words.sublist(1).join(' ')}';
    }
    
    return '$firstPart\n$secondPart';
  }

  String _localizedCategory(String name, AppLang lang) {
    if (lang == AppLang.vi) return name;
    final n = name.toLowerCase();
    if (n.contains('thận') || n.contains('tiet nieu') || n.contains('tiết niệu')) return 'Kidney';
    if (n.contains('gan')) return 'Liver';
    if (n.contains('tim') || n.contains('mạch') || n.contains('tim mạch')) return 'Heart';
    if (n.contains('huyết') || n.contains('huyet')) return 'Blood';
    if (n.contains('chuyển hoá') || n.contains('chuyển hóa') || n.contains('chuyen hoa')) return 'Metabolism';
    if (n.contains('tiết niệu')) return 'Urinary';
    if (n.contains('tổng quan') || n.contains('tong quan')) return 'Overall';
    if (n.contains('bmi') || n.contains('cân nặng')) return 'BMI';
    return name; // fallback
  }
}

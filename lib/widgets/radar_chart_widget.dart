import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/analysis.dart';

class HealthRadarChart extends StatefulWidget {
  final List<HealthCategory> categories;
  final bool compact;
  final String? title;

  /// 5 nhãn theo thứ tự, bắt đầu từ đỉnh trên, quay thuận chiều kim đồng hồ
  final List<String>? customLabels;

  /// 5 giá trị mục tiêu 0..10
  final List<double>? target;

  /// 3 màu bands (inner→middle→outer). Nếu null dùng mặc định: đỏ, vàng, xanh.
  final List<Color>? bandColors;

  /// nhãn đặt ngoài polygon
  final bool labelsOutside;

  /// padding quanh chart để nhãn không bị cắt
  final EdgeInsets? chartPadding;

  /// bật/tắt nền bands
  final bool showBands;

  /// 0..1 — thu nhỏ radar trong khung
  final double radarScale;

  const HealthRadarChart({
    super.key,
    required this.categories,
    this.compact = false,
    this.title,
    this.customLabels,
    this.target,
    this.bandColors,
    this.labelsOutside = true,
    this.chartPadding,
    this.showBands = true,
    this.radarScale = 0.68,
  });

  @override
  State<HealthRadarChart> createState() => _HealthRadarChartState();
}

class _HealthRadarChartState extends State<HealthRadarChart>
    with TickerProviderStateMixin {
  late final AnimationController _polyCtl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  late final AnimationController _dotsCtl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final Animation<double> _poly =
      CurvedAnimation(parent: _polyCtl, curve: Curves.easeOutCubic);
  late final Animation<double> _dots =
      CurvedAnimation(parent: _dotsCtl, curve: Curves.easeOutCubic);

  static const List<String> _defaultLabels = [
    'Sức khỏe\nTim mạch &\nMỡ máu',      // 0 (đỉnh trên)
    'Chức năng\nGan & Thận',             // 1 (phải-trên)
    'Chỉ số\nĐường huyết &\nChuyển hóa', // 2 (phải-dưới)
    'Huyết học\ntổng quát',               // 3 (dưới)
    'Phân tích\nNước tiểu',              // 4 (trái)
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _polyCtl.forward();
      Future.delayed(const Duration(milliseconds: 120), () => _dotsCtl.forward());
    });
  }

  @override
  void dispose() {
    _polyCtl.dispose();
    _dotsCtl.dispose();
    super.dispose();
  }

  // Đo size text sau layout (tôn trọng maxWidth, maxLines)
  Size _measureLabel(BuildContext context, String text, double maxW, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1.15,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 3,
    )..layout(maxWidth: maxW);
    return tp.size;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return const Center(child: Text('Không có dữ liệu biểu đồ'));
    }

    final labels = widget.customLabels ?? _defaultLabels;
    final values = _mapCategoriesToValues();
    final targetValues = (widget.target ?? const [8, 8, 8, 8, 8])
        .map((e) => e.clamp(0.0, 10.0).toDouble())
        .toList(growable: false);

    // 3 vùng màu: inner đỏ (xấu), middle vàng (trung bình), outer xanh (tốt)
    final bands = widget.bandColors ??
        <Color>[
          const Color(0xFFF44336).withOpacity(0.18), // inner
          const Color(0xFFFFC107).withOpacity(0.16), // middle
          const Color(0xFF4CAF50).withOpacity(0.20), // outer
        ];

    return LayoutBuilder(builder: (ctx, cons) {
      final fallback = widget.compact ? 380.0 : 520.0;
      final width = cons.hasBoundedWidth ? cons.maxWidth : fallback;
      final height = cons.hasBoundedHeight ? cons.maxHeight : fallback;
      final chartSize = math.min(math.min(width, height), fallback);

      final isDark = Theme.of(context).brightness == Brightness.dark;
      final gridColor = isDark ? const Color(0x80555555) : const Color(0xFFBDBDBD);
      final tickTextColor = isDark ? const Color(0xDDFFFFFF) : const Color(0xFF616161);
      final labelTextColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF37474F);

      // Padding đủ lớn để nhãn ở ngoài không bị cắt
      final EdgeInsets padding = widget.chartPadding ??
          (widget.labelsOutside
              ? const EdgeInsets.fromLTRB(60, 85, 120, 80)
              : const EdgeInsets.all(12));

      final innerW = chartSize - padding.left - padding.right;
      final innerH = chartSize - padding.top - padding.bottom;
      final r = math.min(innerW, innerH) / 2;

      final radarScale = widget.radarScale.clamp(0.5, 0.85);

      final labelBoxW = widget.compact ? 110.0 : 130.0;
      final cardRadius = 16.0;

      // —— tham số an toàn để nhãn KHÔNG chồng lên polygon ——
      final double outerR = r * radarScale; // bán kính outer thật của radar
      const double baseGap = 10;            // khoảng cách tối thiểu từ text → polygon
      // 3 nhãn kéo gần đỉnh hơn nhưng vẫn an toàn
      const tightSet = {0, 2, 3};

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12),
              child: Text(widget.title!,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          Center(
            child: SizedBox(
              width: chartSize,
              height: chartSize,
              child: AnimatedBuilder(
                animation: Listenable.merge([_poly, _dots]),
                builder: (context, _) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(cardRadius),
                    child: Container(
                      padding: padding,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(cardRadius),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Vẽ 3 bands
                          if (widget.showBands)
                            Positioned.fill(
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  isComplex: true,
                                  painter: _RadarBandsPainter(
                                    sides: 5,
                                    bandCount: 3,
                                    bandColors: bands,
                                    gridColor: gridColor,
                                    scale: radarScale,
                                  ),
                                ),
                              ),
                            ),

                          // Radar chính
                          Center(
                            child: FractionallySizedBox(
                              widthFactor: radarScale,
                              heightFactor: radarScale,
                              child: RadarChart(
                                RadarChartData(
                                  radarShape: RadarShape.polygon,
                                  radarBackgroundColor: Colors.transparent,
                                  radarBorderData: BorderSide(width: 1, color: gridColor),
                                  tickBorderData: BorderSide(width: 1, color: gridColor),
                                  gridBorderData: BorderSide(width: 1, color: gridColor),
                                  titleTextStyle: const TextStyle(fontSize: 0),
                                  getTitle: (i, _) => const RadarChartTitle(text: ''),
                                  tickCount: 5,
                                  ticksTextStyle: TextStyle(
                                    fontSize: widget.compact ? 10 : 11,
                                    color: tickTextColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  dataSets: [
                                    // ép thang 0..10
                                    RadarDataSet(
                                      dataEntries:
                                          List.generate(5, (_) => const RadarEntry(value: 10)),
                                      fillColor: Colors.transparent,
                                      borderColor: Colors.transparent,
                                      borderWidth: 0,
                                      entryRadius: 0,
                                    ),
                                    // Target
                                    RadarDataSet(
                                      dataEntries:
                                          targetValues.map((v) => RadarEntry(value: v)).toList(),
                                      fillColor: const Color(0xFF4CAF50).withOpacity(0.18),
                                      borderColor: const Color(0xFF4CAF50).withOpacity(0.28),
                                      borderWidth: 0.8,
                                      entryRadius: 0,
                                    ),
                                    // Current
                                    RadarDataSet(
                                      dataEntries:
                                          values.map((v) => RadarEntry(value: v)).toList(),
                                      fillColor:
                                          const Color(0xFF2E7D32).withOpacity(0.18 * _poly.value),
                                      borderColor: const Color(0xFF2E7D32),
                                      borderWidth: 2.2 * _poly.value.clamp(0.3, 1.0),
                                      entryRadius: 3.8 * _dots.value.clamp(0.0, 1.0),
                                    ),
                                  ],
                                  radarTouchData: RadarTouchData(enabled: false),
                                ),
                              ),
                            ),
                          ),

                          // NHÃN — đặt ngoài, tự bảo đảm không chồng polygon
                          ...List.generate(5, (i) {
                            final angle = -math.pi / 2 + i * 2 * math.pi / 5;
                            final labelText = labels[i];

                            // đo kích thước nhãn
                            final sz = _measureLabel(
                              context, labelText, labelBoxW, widget.compact ? 10 : 11);
                            final halfW = sz.width / 2.0;
                            final halfH = sz.height / 2.0;

                            // vector hướng bán kính
                            final ux = math.cos(angle);
                            final uy = math.sin(angle);

                            // chiếu “nửa hộp” theo hướng bán kính
                            final projHalf = halfW * ux.abs() + halfH * uy.abs();

                            // bán kính cơ sở (để 3 nhãn gần đỉnh hơn)
                            final baseRadius = outerR + (tightSet.contains(i) ? 12.0 : 18.0);

                            // bán kính an toàn tuyệt đối: không chạm polygon xanh
                            final safeRadius = outerR + baseGap + projHalf;

                            final labelR = math.max(baseRadius, safeRadius);

                            // vị trí tâm nhãn
                            final dx = labelR * ux;
                            final dy = labelR * uy;

                            final bool isTop = (i == 0);
                            final bool isBottom = (i == 3);
                            final bool isRight = (i == 1 || i == 2);
                            final bool isLeft = (i == 4);

                            final TextAlign align = isRight
                                ? TextAlign.left
                                : isLeft
                                    ? TextAlign.right
                                    : TextAlign.center;

                            // KHÔNG còn nudge ngang (nguyên nhân gây tụt vào polygon).
                            final double nudgeX = 0;
                            final double nudgeY = isTop ? -6 : (isBottom ? 6 : 0);

                            return Center(
                              child: Transform.translate(
                                offset: Offset(dx + nudgeX, dy + nudgeY),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: labelBoxW),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      labelText,
                                      textAlign: align,
                                      style: TextStyle(
                                        fontSize: widget.compact ? 10 : 11,
                                        fontWeight: FontWeight.w700,
                                        color: labelTextColor,
                                        height: 1.15,
                                      ),
                                      maxLines: 3,
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  List<double> _mapCategoriesToValues() {
    final Map<String, double> m = {};
    for (final c in widget.categories) {
      final name = c.categoryName.toLowerCase();
      final score = c.score.toDouble().clamp(0.0, 10.0);

      if (name.contains('tim') || name.contains('mạch') || name.contains('mỡ') || name.contains('lipid')) {
        m['cardio'] = math.max(m['cardio'] ?? 0, score);
      } else if (name.contains('gan') || name.contains('thận') || name.contains('liver') || name.contains('kidney')) {
        m['liver_kidney'] = math.max(m['liver_kidney'] ?? 0, score);
      } else if (name.contains('đường') || name.contains('glucose') || name.contains('chuyển') || name.contains('metabolism')) {
        m['glucose'] = math.max(m['glucose'] ?? 0, score);
      } else if (name.contains('huyết') || name.contains('hematology') || name.contains('blood')) {
        m['hematology'] = math.max(m['hematology'] ?? 0, score);
      } else if (name.contains('nước tiểu') || name.contains('urine') || name.contains('urinalysis')) {
        m['urine'] = math.max(m['urine'] ?? 0, score);
      }
    }
    return [
      m['cardio'] ?? 0.0,
      m['liver_kidney'] ?? 0.0,
      m['glucose'] ?? 0.0,
      m['hematology'] ?? 0.0,
      m['urine'] ?? 0.0,
    ];
  }
}

/// Painter vẽ **3** bands đồng tâm (outer→inner) cho radar ngũ giác
class _RadarBandsPainter extends CustomPainter {
  _RadarBandsPainter({
    required this.sides,
    required this.bandCount,
    required this.bandColors,
    required this.gridColor,
    required this.scale,
  });

  final int sides;              // số cạnh (5)
  final int bandCount;          // 3
  final List<Color> bandColors; // độ dài = 3
  final Color gridColor;
  final double scale;           // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy);

    Path poly(double k) {
      final p = Path();
      for (int i = 0; i < sides; i++) {
        final angle = -math.pi / 2 + i * 2 * math.pi / sides;
        final x = cx + r * (k * scale) * math.cos(angle);
        final y = cy + r * (k * scale) * math.sin(angle);
        if (i == 0) p.moveTo(x, y); else p.lineTo(x, y);
      }
      p.close();
      return p;
    }

    // Chia bán kính thành 3 lớp bằng nhau: [2/3→1] (outer xanh), [1/3→2/3] (vàng), [0→1/3] (đỏ)
    final stops = <double>[0.0, 1.0 / bandCount, 2.0 / bandCount, 1.0];

    for (int i = bandCount; i >= 1; i--) {
      final ro = stops[i];     // outer
      final ri = stops[i - 1]; // inner
      final bandPath = Path.combine(PathOperation.difference, poly(ro), poly(ri));
      final c = bandColors[(i - 1).clamp(0, bandColors.length - 1)];
      final paint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.srcOver
        ..color = c;
      canvas.drawPath(bandPath, paint);
    }

    // Soft center
    final centerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = gridColor.withOpacity(0.06);
    canvas.drawCircle(Offset(cx, cy), r * 0.16 * scale, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarBandsPainter old) =>
      old.sides != sides ||
      old.bandCount != bandCount ||
      old.bandColors != bandColors ||
      old.gridColor != gridColor ||
      old.scale != scale;
}

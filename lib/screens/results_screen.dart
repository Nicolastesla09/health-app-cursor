import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/analysis.dart';
import '../widgets/radar_chart_widget.dart';

class ResultsScreen extends StatefulWidget {
  final AnalysisResult? result;
  const ResultsScreen({super.key, required this.result});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool compact = false;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    if (result == null) {
      return const Center(child: Text('Chưa có kết quả. Hãy phân tích trước.'));
    }
    final r = result;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerActions(context, r),
          const SizedBox(height: 8),
          _topSummary(context, r),
          const SizedBox(height: 12),
          _healthOverview(context, r),
          const SizedBox(height: 12),
          _metricsTable(context, r),
          const SizedBox(height: 12),
          _foods(context, r),
        ],
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, AnalysisResult r) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (ctx) => [
          pw.Header(level: 0, child: pw.Text('Báo cáo sức khỏe', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold))),
          pw.Text('Điểm tổng thể: ${r.overallHealthScore.score} - ${r.overallHealthScore.label}'),
          pw.SizedBox(height: 6),
          pw.Text(r.overallHealthScore.explanation),
          pw.SizedBox(height: 12),
          pw.Text('BMI', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text(r.bmiSummary),
          pw.SizedBox(height: 12),
          pw.Text('Danh mục sức khỏe', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Column(children: [
            for (final c in r.categories)
              pw.Bullet(text: '${c.categoryName} — ${c.score}/10: ${c.summary}'),
          ]),
          pw.SizedBox(height: 12),
          pw.Text('Chỉ số xét nghiệm', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Column(children: [
            for (final m in r.metrics)
              pw.Container(
                margin: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Text('${m.name}: ${m.value} ${m.unit} | Tham chiếu: ${m.referenceRange} | ${m.classification}\n${m.explanation}'),
              ),
          ]),
          pw.SizedBox(height: 12),
          pw.Text('Thực phẩm khuyến nghị', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Column(children: [
            for (final f in r.recommendedFoods)
              pw.Bullet(text: '${f.foodName} — ${f.benefit}. Khẩu phần: ${f.servingSuggestion}. Nơi mua: ${f.suggestedStore}'),
          ]),
        ],
      ),
    );
    await Printing.sharePdf(bytes: await doc.save(), filename: 'bao_cao_suc_khoe.pdf');
  }

  // UI sections
  Widget _headerActions(BuildContext context, AnalysisResult r) {
    return Row(children: [
      Expanded(
        child: Text('Kết quả Phân tích', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      ),
      Row(children: [
        const Text('Gọn'),
        Switch(value: compact, onChanged: (v) => setState(() => compact = v)),
        const SizedBox(width: 8),
      ]),
      FilledButton.icon(
        onPressed: () => _exportPdf(context, r),
        icon: const Icon(Icons.picture_as_pdf_outlined),
        label: const Text('Xuất PDF'),
      )
    ]);
  }

  Widget _scoreBadge(BuildContext context, num score, String label, {String? infoText}) {
    final cs = Theme.of(context).colorScheme;
    Color tone;
    if (score >= 80) {
      tone = cs.primary;
    } else if (score >= 60) {
      tone = const Color(0xFFF39C12); // amber
    } else {
      tone = const Color(0xFFE74C3C); // red
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${score.toStringAsFixed(0)}', style: TextStyle(fontSize: compact ? 36 : 48, fontWeight: FontWeight.w800)),
          const SizedBox(width: 4),
          Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('/100', style: Theme.of(context).textTheme.titleSmall)),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 6),
          decoration: BoxDecoration(color: tone.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: tone.withOpacity(0.5))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            InkWell(
              onTap: infoText == null
                  ? null
                  : () => _showInfoPopup(context, title: 'Cách tính điểm', text: infoText),
              child: Icon(Icons.info_outline, size: 16, color: tone),
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: tone, fontWeight: FontWeight.w600)),
          ]),
        )
      ],
    );
  }

  Widget _topSummary(BuildContext context, AnalysisResult r) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kết quả Phân tích', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (ctx, c) {
              final isNarrow = c.maxWidth < 600;
              final scoreCard = Container(
                width: isNarrow ? double.infinity : 180,
                padding: EdgeInsets.all(compact ? 10 : 12),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                child: _scoreBadge(
                  context,
                  r.overallHealthScore.score,
                  r.overallHealthScore.label,
                  infoText: r.overallHealthScore.explanation,
                ),
              );
              final info = Expanded(
                child: Container(
                  padding: EdgeInsets.all(compact ? 10 : 12),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _kv('BMI', r.bmiSummary),
                    const SizedBox(height: 8),
                    Text(r.overallHealthScore.explanation),
                  ]),
                ),
              );
              if (isNarrow) {
                return Column(children: [scoreCard, const SizedBox(height: 12), info]);
              } else {
                return Row(children: [scoreCard, const SizedBox(width: 16), info]);
              }
            })
          ],
        ),
      ),
    );
  }

  Widget _healthOverview(BuildContext context, AnalysisResult r) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LayoutBuilder(builder: (ctx, c) {
            final isNarrow = c.maxWidth < 700;
            final chart = Container(
              decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(12)),
              padding: EdgeInsets.all(compact ? 8 : 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 320),
                child: HealthRadarChart(
                  categories: r.categories,
                  compact: compact,
                  title: 'Danh mục chính',
                ),
              ),
            );
            final cats = Column(children: [
              for (final c0 in r.categories)
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: compact ? 8 : 10),
                  padding: EdgeInsets.all(compact ? 10 : 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _scoreColor(context, c0.score).withOpacity(0.4)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c0.categoryName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: compact ? 13 : 14)),
                      SizedBox(height: compact ? 4 : 6),
                      Text(c0.summary),
                    ])),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 6),
                      decoration: BoxDecoration(color: _scoreColor(context, c0.score).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                      child: Text(c0.score.toStringAsFixed(1), style: TextStyle(color: _scoreColor(context, c0.score), fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ),
            ]);
            if (isNarrow) {
              return Column(children: [chart, const SizedBox(height: 12), cats]);
            } else {
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: chart),
                const SizedBox(width: 12),
                Expanded(child: cats),
              ]);
            }
          }),
        ]),
      ),
    );
  }

  Widget _metricsTable(BuildContext context, AnalysisResult r) {
    return _MetricsTable(metrics: r.metrics, compact: compact);
  }

  Widget _foods(BuildContext context, AnalysisResult r) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Thực phẩm khuyến nghị', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final f in r.recommendedFoods)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.restaurant_outlined),
              title: Text(f.foodName),
              subtitle: Text('${f.benefit}\nGợi ý khẩu phần: ${f.servingSuggestion}\nNơi mua: ${f.suggestedStore}'),
            ),
        ]),
      ),
    );
  }

  Color _scoreColor(BuildContext context, num s) {
    if (s >= 8) return Theme.of(context).colorScheme.primary;
    if (s >= 6) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  Widget _kv(String k, String v) {
    return Row(children: [
      Text('$k: ', style: const TextStyle(fontWeight: FontWeight.w700)),
      Expanded(child: Text(v)),
    ]);
  }

  void _showInfoPopup(BuildContext context, {required String title, required String text}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              Text(text, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Đóng', style: TextStyle(color: Colors.white))),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricsTable extends StatefulWidget {
  final List<MetricItem> metrics;
  final bool compact;
  const _MetricsTable({required this.metrics, this.compact = false});

  @override
  State<_MetricsTable> createState() => _MetricsTableState();
}

class _MetricsTableState extends State<_MetricsTable> {
  bool onlyAbnormal = false;
  bool abnormalFirst = true;

  @override
  Widget build(BuildContext context) {
    final list = [...widget.metrics];
    int rank(String c) => c.toLowerCase().contains('cao')
        ? 0
        : c.toLowerCase().contains('thấp')
            ? 1
            : 2;
    if (abnormalFirst) list.sort((a, b) => rank(a.classification).compareTo(rank(b.classification)));
    final filtered = onlyAbnormal ? list.where((m) => rank(m.classification) != 2).toList() : list;

    Color rowColor(String c) {
      if (c.toLowerCase().contains('cao')) return const Color(0xFFFFE5E3);
      if (c.toLowerCase().contains('thấp')) return const Color(0xFFFFF0D6);
      return Theme.of(context).colorScheme.surface;
    }

    Color badgeColor(String c) {
      if (c.toLowerCase().contains('cao')) return const Color(0xFFE74C3C);
      if (c.toLowerCase().contains('thấp')) return const Color(0xFFF39C12);
      return const Color(0xFF2ECC71);
    }

    final compact = widget.compact;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LayoutBuilder(builder: (ctx, c) {
            final narrow = c.maxWidth < 520;
            final toggles = [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.swap_vert), const SizedBox(width: 4), const Text('Bất thường lên đầu'),
                Switch(value: abnormalFirst, onChanged: (v) => setState(() => abnormalFirst = v)),
              ]),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.filter_alt_outlined), const SizedBox(width: 4), const Text('Chỉ hiện bất thường'),
                Switch(value: onlyAbnormal, onChanged: (v) => setState(() => onlyAbnormal = v)),
              ]),
            ];
            if (narrow) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Chỉ số Xét nghiệm Chi tiết', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                toggles[0],
                const SizedBox(height: 4),
                toggles[1],
              ]);
            }
            return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Chỉ số Xét nghiệm Chi tiết', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Wrap(spacing: 12, children: toggles),
            ]);
          }),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _headerRow(context),
              for (final m in filtered)
                Container(
                  color: rowColor(m.classification),
                  padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 8 : 10),
                  child: Row(children: [
                    _cell(context, m.name, flex: 3, bold: true),
                    _cell(context, '${m.value} ${m.unit}', flex: 2),
                    _cell(context, m.referenceRange, flex: 2),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 6),
                          decoration: BoxDecoration(color: badgeColor(m.classification).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                          child: Text(m.classification, style: TextStyle(color: badgeColor(m.classification), fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ]),
                ),
            ]),
          )
        ]),
      ),
    );
  }

  Widget _headerRow(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: widget.compact ? 10 : 12, vertical: widget.compact ? 8 : 10),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
      child: Row(children: [
        Expanded(flex: 3, child: Text('Chỉ số', style: style)),
        Expanded(flex: 2, child: Text('Kết quả', style: style)),
        Expanded(flex: 2, child: Text('Ngưỡng tham chiếu', style: style)),
        Expanded(flex: 2, child: Text('Trạng thái', style: style)),
      ]),
    );
  }

  Widget _cell(BuildContext context, String text, {int flex = 1, bool bold = false}) {
    return Expanded(
      flex: flex,
      child: Text(text, style: bold ? const TextStyle(fontWeight: FontWeight.w700) : null),
    );
  }
}

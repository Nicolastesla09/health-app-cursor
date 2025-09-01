import 'package:flutter/material.dart';
import '../l10n.dart';
import '../models/analysis.dart';
import '../widgets/radar_chart_widget.dart';

class DashboardScreen extends StatelessWidget {
  final AnalysisResult? lastResult;
  final VoidCallback onNewAnalysis;
  final VoidCallback onLogMeal;
  final VoidCallback onUpdateBody;
  const DashboardScreen({super.key, required this.lastResult, required this.onNewAnalysis, required this.onLogMeal, required this.onUpdateBody});

  @override
  Widget build(BuildContext context) {
    final lang = AppStringsScope.of(context);
    final s = AppStrings(lang);
    final r = lastResult;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.t('overall_health_score'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: r == null
                  ? Text(s.t('no_data'))
                  : Row(
                      children: [
                        _scoreBadge(context, r.overallHealthScore.score.toDouble(), r.overallHealthScore.label),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(height: 180, child: HealthRadarChart(categories: r.categories, compact: true)),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(s.t('quick_actions'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _qaButton(context, Icons.analytics_outlined, s.t('qa_new_analysis'), onNewAnalysis),
            _qaButton(context, Icons.restaurant, s.t('qa_log_meal'), onLogMeal),
            _qaButton(context, Icons.monitor_weight_outlined, s.t('qa_update_body'), onUpdateBody),
          ]),
          if (r != null) ...[
            const SizedBox(height: 12),
            Text(s.t('highlights'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ..._suggestions(context, r),
          ],
        ],
      ),
    );
  }

  Widget _qaButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [Icon(icon), const SizedBox(width: 12), Expanded(child: Text(label))]),
      ),
    );
  }

  Widget _scoreBadge(BuildContext context, double score, String label) {
    final cs = Theme.of(context).colorScheme;
    Color tone;
    if (score >= 80) {
      tone = cs.primary;
    } else if (score >= 60) {
      tone = const Color(0xFFF39C12);
    } else {
      tone = const Color(0xFFE74C3C);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(score.toStringAsFixed(0), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800)),
        const SizedBox(width: 4),
        Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('/100', style: Theme.of(context).textTheme.titleSmall)),
      ]),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: tone.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: tone.withOpacity(0.5))),
        child: Text(label, style: TextStyle(color: tone, fontWeight: FontWeight.w700)),
      ),
    ]);
  }

  List<Widget> _suggestions(BuildContext context, AnalysisResult r) {
    final items = <String>[];
    final s = AppStrings.of(context);
    // Simple heuristics based on categories/metrics text.
    final text = (r.categories.map((e) => '${e.categoryName} ${e.summary}').join('\n') + '\n' + r.metrics.map((m) => '${m.name} ${m.classification}').join('\n')).toLowerCase();
    final isEn = AppStringsScope.of(context) == AppLang.en;
    if (text.contains('egfr') || text.contains('thận') || text.contains('than')) {
      items.add(isEn ? 'Low eGFR: Stay hydrated, reduce salt, see a doctor if persistent.' : 'eGFR thấp: Uống đủ nước, hạn chế muối, tái khám nếu kéo dài.');
    }
    if (text.contains('gan') || text.contains('alt') || text.contains('ast') || text.contains('liver')) {
      items.add(isEn ? 'High liver enzymes: Avoid alcohol and fried foods; rest well.' : 'Men gan cao: Tránh rượu, thực phẩm chiên rán; nghỉ ngơi hợp lý.');
    }
    if (text.contains('glucose') || text.contains('đường') || text.contains('duong') || text.contains('sugar')) {
      items.add(isEn ? 'High glucose: Add more greens, reduce refined sweets.' : 'Đường huyết cao: Ăn thêm rau xanh, giảm đồ ngọt tinh luyện.');
    }
    if (items.isEmpty) {
      items.add(isEn ? 'Drink 6–8 cups of water daily.' : 'Duy trì uống 6–8 ly nước mỗi ngày.');
      items.add(isEn ? 'Add greens and move 30 minutes daily.' : 'Tăng cường rau xanh và vận động nhẹ 30 phút.');
    }
    return items.take(3).map((t) => Card(child: ListTile(leading: const Icon(Icons.tips_and_updates_outlined), title: Text(t)))).toList();
  }
}

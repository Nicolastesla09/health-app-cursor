import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n.dart';
import '../models/analysis.dart';
import '../services/ai_service.dart';
import '../widgets/history_line_chart_widget.dart';
import '../widgets/radar_chart_widget.dart';

class HealthScreen extends StatefulWidget {
  final String email;
  final AnalysisResult? lastResult;
  const HealthScreen({super.key, required this.email, required this.lastResult});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  String _tab = 'results';
  List<({DateTime date, AnalysisResult analysis})> _history = [];

  final _question = TextEditingController();
  final _messages = <({String role, String text})>[];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'health_history_${widget.email}';
    final list = prefs.getStringList(key) ?? <String>[];
    final items = <({DateTime date, AnalysisResult analysis})>[];
    for (final s in list) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        items.add((
          date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
          analysis: AnalysisResult.fromJson(m['analysis'] as Map<String, dynamic>),
        ));
      } catch (_) {}
    }
    setState(() => _history = items);
  }

  Future<void> _sendQuestion() async {
    final q = _question.text.trim();
    if (q.isEmpty) return;
    setState(() { _messages.add((role: 'user', text: q)); _question.clear(); _loading = true; });
    try {
      final ai = AiService();
      final ctx = widget.lastResult;
      final answer = await ai.askDoctor(question: q, context: ctx);
      setState(() { _messages.add((role: 'ai', text: answer)); });
    } catch (e) {
      setState(() { _messages.add((role: 'ai', text: 'Xin lỗi, có lỗi khi trả lời: $e')); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppStringsScope.of(context);
    final s = AppStrings(lang);
    return SafeArea(
      child: Column(children: [
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'results', label: Text(s.t('lab_results'))),
            ButtonSegment(value: 'trends', label: Text(s.t('history_trends'))),
            ButtonSegment(value: 'chat', label: Text(s.t('ai_doctor'))),
          ],
          selected: {_tab},
          onSelectionChanged: (s) => setState(() => _tab = s.first),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: switch (_tab) {
              'trends' => _buildTrends(context),
              'chat' => _buildChat(context),
              _ => _buildResults(context),
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildResults(BuildContext context) {
    final s = AppStrings.of(context);
    final r = widget.lastResult;
    if (r == null) return Center(child: Text(s.t('no_data')));
    return ListView(
      key: const ValueKey('results'),
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.radar,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      s.t('categories_main'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 220,
                  child: HealthRadarChart(
                    categories: r.categories, 
                    compact: false,
                    title: s.t('health_overview'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.table_chart,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      s.t('metrics_table'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                for (final m in r.metrics)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: _rowColor(m.classification).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _rowColor(m.classification).withOpacity(0.3),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${m.name}: ${m.value} ${m.unit}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          _badge(m.classification),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${s.t('reference_range')}: ${m.referenceRange}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            m.explanation,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrends(BuildContext context) {
    final s = AppStrings.of(context);
    final dates = _history.map((e) => e.date).toList();
    final scores = _history.map((e) => e.analysis.overallHealthScore.score.toDouble()).toList();
    return ListView(
      key: const ValueKey('trends'),
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          height: 260,
          child: Card(child: Padding(padding: const EdgeInsets.all(16.0), child: HistoryLineChart(dates: dates, scores: scores))),
        ),
        const SizedBox(height: 12),
        for (final it in _history)
          Card(child: ListTile(title: Text('${s.t('day')}: ${it.date.toLocal()}'), subtitle: Text('${s.t('score')}: ${it.analysis.overallHealthScore.score} - ${it.analysis.overallHealthScore.label}'))),
      ],
    );
  }

  Widget _buildChat(BuildContext context) {
    final lang = AppStringsScope.of(context);
    final s = AppStrings(lang);
    return Column(children: [
      Expanded(
        child: ListView(
          key: const ValueKey('chat'),
          padding: const EdgeInsets.all(12),
          children: [
            for (final m in _messages)
              Align(
                alignment: m.role == 'user' ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(10),
                  constraints: const BoxConstraints(maxWidth: 520),
                  decoration: BoxDecoration(
                    color: m.role == 'user' ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(m.text),
                ),
              ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(children: [
          Expanded(child: TextField(controller: _question, decoration: InputDecoration(hintText: s.t('ask_here')))),
          const SizedBox(width: 8),
          FilledButton.icon(onPressed: _loading ? null : _sendQuestion, icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send), label: Text(s.t('send'))),
        ]),
      )
    ]);
  }

  Color _rowColor(String c) {
    final lc = c.toLowerCase();
    if (lc.contains('cao')) return const Color(0xFFFFE5E3);
    if (lc.contains('thấp') || lc.contains('thp')) return const Color(0xFFFFF0D6);
    return Colors.transparent;
  }

  Widget _badge(String c) {
    Color color;
    final lc = c.toLowerCase();
    if (lc.contains('cao')) color = const Color(0xFFE74C3C);
    else if (lc.contains('thấp') || lc.contains('thp')) color = const Color(0xFFF39C12);
    else color = const Color(0xFF2ECC71);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(c, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

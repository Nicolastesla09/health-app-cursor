import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/analysis.dart';
import '../widgets/history_line_chart_widget.dart';

class HistoryScreen extends StatefulWidget {
  final String email;
  const HistoryScreen({super.key, required this.email});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<({DateTime date, AnalysisResult analysis, Map<String, dynamic> inputs})> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'health_history_${widget.email}';
    final list = prefs.getStringList(key) ?? <String>[];
    final items = <({DateTime date, AnalysisResult analysis, Map<String, dynamic> inputs})>[];
    for (final s in list) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        items.add((
          date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
          analysis: AnalysisResult.fromJson(m['analysis'] as Map<String, dynamic>),
          inputs: (m['inputs'] as Map<String, dynamic>?) ?? {},
        ));
      } catch (_) {}
    }
    setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    final dates = _items.map((e) => e.date).toList();
    final scores = _items.map((e) => (e.analysis.overallHealthScore.score.toDouble())).toList();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 260,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: HistoryLineChart(dates: dates, scores: scores),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final it in _items)
            Card(
              child: ListTile(
                title: Text('Ngày: ${it.date.toLocal()}'),
                subtitle: Text('Điểm: ${it.analysis.overallHealthScore.score.toString()} - ${it.analysis.overallHealthScore.label}'),
              ),
            ),
        ],
      ),
    );
  }
}

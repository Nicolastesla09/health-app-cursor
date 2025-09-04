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

class _HealthScreenState extends State<HealthScreen> with TickerProviderStateMixin {
  int _tabIndex = 0;
  List<({DateTime date, AnalysisResult analysis})> _history = [];

  final _question = TextEditingController();
  final _messages = <({String role, String text})>[];
  final _scrollController = ScrollController();
  bool _loading = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _question.dispose();
    _scrollController.dispose();
    super.dispose();
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

    setState(() {
      _messages.add((role: 'user', text: q));
      _question.clear();
      _loading = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      final ai = AiService();
      final ctx = widget.lastResult;
      final answer = await ai.askDoctor(question: q, context: ctx);
      setState(() => _messages.add((role: 'ai', text: answer)));
    } catch (e) {
      setState(() => _messages.add((role: 'ai', text: 'Xin lỗi, có lỗi khi trả lời: $e')));
    } finally {
      setState(() => _loading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppStringsScope.of(context);
    final s = AppStrings(lang);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Tabs
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                onTap: (index) => setState(() => _tabIndex = index),
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).colorScheme.primary,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Theme.of(context).colorScheme.onPrimary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.analytics_outlined, size: 16),
                        const SizedBox(width: 6),
                        Text(s.t('lab_results')),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.trending_up, size: 16),
                        const SizedBox(width: 6),
                        Text(s.t('history_trends')),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.psychology, size: 16),
                        const SizedBox(width: 6),
                        Text(s.t('ai_doctor')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildResults(context),
                  _buildTrends(context),
                  _buildChat(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final s = AppStrings.of(context);
    final r = widget.lastResult;

    if (r == null) {
      return _buildEmptyState(
        context,
        icon: Icons.analytics_outlined,
        title: s.t('no_data'),
        subtitle: 'Hãy tải lên kết quả xét nghiệm để xem phân tích chi tiết',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ===== Health Categories Card =====
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.radar, color: Theme.of(context).colorScheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      s.t('categories_main'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Chart area — vuông, chừa mép cho nhãn (đặc biệt bên phải)
                AspectRatio(
                  aspectRatio: 1.08,
                  child: HealthRadarChart(
                    categories: r.categories,
                    compact: false,
                    labelsOutside: true,
                    chartPadding: const EdgeInsets.fromLTRB(32, 48, 76, 40),
                    showBands: true, // nếu web bị trắng, tạm set false để test
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ===== Metrics Table Card =====
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.table_chart, color: Theme.of(context).colorScheme.secondary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      s.t('metrics_table'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...r.metrics.map((m) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: _getMetricBackgroundColor(m.classification),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getMetricBorderColor(m.classification), width: 1),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getMetricBorderColor(m.classification).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(_getMetricIcon(m.classification),
                              color: _getMetricBorderColor(m.classification), size: 20),
                        ),
                        title: Text('${m.name}: ${m.value} ${m.unit}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('${s.t('reference_range')}: ${m.referenceRange}'),
                            const SizedBox(height: 4),
                            Text(
                              m.explanation,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                            ),
                          ],
                        ),
                        trailing: _buildMetricBadge(m.classification),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrends(BuildContext context) {
    final s = AppStrings.of(context);

    if (_history.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.trending_up,
        title: 'Chưa có lịch sử',
        subtitle: 'Thực hiện nhiều lần xét nghiệm để xem xu hướng thay đổi',
      );
    }

    final dates = _history.map((e) => e.date).toList();
    final scores = _history.map((e) => e.analysis.overallHealthScore.score.toDouble()).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.show_chart, color: Theme.of(context).colorScheme.tertiary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Xu hướng điểm sức khỏe',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(height: 250, child: HistoryLineChart(dates: dates, scores: scores)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        ..._history.map((it) => Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getScoreColor(it.analysis.overallHealthScore.score.toDouble()).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.assessment,
                      color: _getScoreColor(it.analysis.overallHealthScore.score.toDouble()), size: 20),
                ),
                title: Text('${s.t('day')}: ${_formatDate(it.date)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                    '${s.t('score')}: ${it.analysis.overallHealthScore.score} - ${it.analysis.overallHealthScore.label}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getScoreColor(it.analysis.overallHealthScore.score.toDouble()).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    it.analysis.overallHealthScore.score.toString(),
                    style: TextStyle(
                      color: _getScoreColor(it.analysis.overallHealthScore.score.toDouble()),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildChat(BuildContext context) {
    final lang = AppStringsScope.of(context);
    final s = AppStrings(lang);

    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? _buildChatEmptyState(context, s)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _buildChatMessage(context, _messages[index]),
                ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _question,
                    decoration: InputDecoration(
                      hintText: s.t('ask_here'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendQuestion(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _loading ? null : _sendQuestion,
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                    minimumSize: const Size(48, 48),
                  ),
                  child: _loading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : Icon(Icons.send_rounded, size: 20, color: Theme.of(context).colorScheme.onPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatEmptyState(BuildContext context, AppStrings s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.psychology_rounded, size: 48, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text('Chào bạn! 👋',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              'Tôi là AI Doctor, sẵn sàng tư vấn về sức khỏe của bạn. Hãy hỏi về kết quả xét nghiệm, chế độ ăn uống, hay bất kỳ thắc mắc nào!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSuggestedQuestion(context, '💊 Giải thích chỉ số xét nghiệm'),
                _buildSuggestedQuestion(context, '🥗 Tư vấn chế độ ăn'),
                _buildSuggestedQuestion(context, '🏃 Lời khuyên vận động'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedQuestion(BuildContext context, String question) {
    return ActionChip(
      label: Text(question, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        _question.text = question.replaceFirst(RegExp(r'^[^\s]+\s'), '');
        _sendQuestion();
      },
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      side: BorderSide.none,
    );
  }

  Widget _buildChatMessage(BuildContext context, ({String role, String text}) message) {
    final isUser = message.role == 'user';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.psychology, size: 18, color: Theme.of(context).colorScheme.onPrimary),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, size: 18, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
          ],
        ],
      ),
    );
  }

  Color _getMetricBackgroundColor(String classification) {
    final lc = classification.toLowerCase();
    if (lc.contains('cao')) return const Color(0xFFFFEBEE);
    if (lc.contains('thấp') || lc.contains('thp')) return const Color(0xFFFFF3E0);
    return Colors.transparent;
  }

  Color _getMetricBorderColor(String classification) {
    final lc = classification.toLowerCase();
    if (lc.contains('cao')) return const Color(0xFFE57373);
    if (lc.contains('thấp') || lc.contains('thp')) return const Color(0xFFFFB74D);
    return const Color(0xFF81C784);
  }

  IconData _getMetricIcon(String classification) {
    final lc = classification.toLowerCase();
    if (lc.contains('cao')) return Icons.trending_up;
    if (lc.contains('thấp') || lc.contains('thp')) return Icons.trending_down;
    return Icons.check_circle;
  }

  Widget _buildMetricBadge(String classification) {
    final color = _getMetricBorderColor(classification);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        classification,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
    }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

import 'package:flutter/material.dart';
import '../l10n.dart';
import '../models/analysis.dart';
import '../widgets/radar_chart_widget.dart';

class DashboardScreen extends StatelessWidget {
  final AnalysisResult? lastResult;
  final VoidCallback onNewAnalysis;
  final VoidCallback onLogMeal;
  final VoidCallback onUpdateBody;
  const DashboardScreen({
    super.key, 
    required this.lastResult, 
    required this.onNewAnalysis, 
    required this.onLogMeal, 
    required this.onUpdateBody
  });

  @override
  Widget build(BuildContext context) {
    final lang = AppStringsScope.of(context);
    final s = AppStrings(lang);
    final r = lastResult;
    
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with greeting
            _buildHeader(context, s),
            const SizedBox(height: 20),
            
            // Health Score Card
            _buildHealthScoreCard(context, s, r),
            const SizedBox(height: 16),
            
            // Quick Actions
            _buildQuickActions(context, s),
            const SizedBox(height: 16),
            
            // Highlights/Tips
            if (r != null) ...[
              _buildHighlights(context, s, r),
              const SizedBox(height: 16),
            ],
            
            // Recent Activity (placeholder)
            _buildRecentActivity(context, s),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppStrings s) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Chào buổi sáng!' : 
                    hour < 18 ? 'Chào buổi chiều!' : 'Chào buổi tối!';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Hôm nay cảm thấy thế nào?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthScoreCard(BuildContext context, AppStrings s, AnalysisResult? r) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.t('overall_health_score'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (r == null)
                _buildNoDataState(context, s)
              else
                _buildHealthScoreContent(context, r),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataState(BuildContext context, AppStrings s) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            s.t('no_data'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy tải lên kết quả xét nghiệm để bắt đầu',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreContent(BuildContext context, AnalysisResult r) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 400;
        
        if (isCompact) {
          return Column(
            children: [
              _buildScoreBadge(context, r.overallHealthScore.score.toDouble(), r.overallHealthScore.label),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                child: HealthRadarChart(categories: r.categories),
              ),
            ],
          );
        } else {
          return Row(
            children: [
              _buildScoreBadge(context, r.overallHealthScore.score.toDouble(), r.overallHealthScore.label),
              const SizedBox(width: 20),
              Expanded(
                child: SizedBox(
                  height: 180,
                  child: HealthRadarChart(categories: r.categories),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildScoreBadge(BuildContext context, double score, String label) {
    final cs = Theme.of(context).colorScheme;
    Color scoreColor;
    IconData scoreIcon;
    
    if (score >= 80) {
      scoreColor = const Color(0xFF2ECC71);
      scoreIcon = Icons.sentiment_very_satisfied;
    } else if (score >= 60) {
      scoreColor = const Color(0xFFF39C12);
      scoreIcon = Icons.sentiment_satisfied;
    } else {
      scoreColor = const Color(0xFFE74C3C);
      scoreIcon = Icons.sentiment_dissatisfied;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scoreColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(scoreIcon, color: scoreColor, size: 32),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: scoreColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '/100',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: scoreColor.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: scoreColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.t('quick_actions'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              context,
              icon: Icons.analytics_outlined,
              title: s.t('qa_new_analysis'),
              subtitle: 'Tải lên xét nghiệm mới',
              color: const Color(0xFF3498DB),
              onTap: onNewAnalysis,
            ),
            _buildActionCard(
              context,
              icon: Icons.restaurant_menu,
              title: s.t('qa_log_meal'),
              subtitle: 'Lập kế hoạch ăn uống',
              color: const Color(0xFF2ECC71),
              onTap: onLogMeal,
            ),
            _buildActionCard(
              context,
              icon: Icons.monitor_weight_outlined,
              title: s.t('qa_update_body'),
              subtitle: 'Cập nhật chỉ số cơ thể',
              color: const Color(0xFF9B59B6),
              onTap: onUpdateBody,
            ),
            _buildActionCard(
              context,
              icon: Icons.insights,
              title: 'Báo cáo',
              subtitle: 'Xem chi tiết sức khỏe',
              color: const Color(0xFFF39C12),
              onTap: () {}, // Navigate to detailed report
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlights(BuildContext context, AppStrings s, AnalysisResult r) {
    final highlights = _getHighlights(context, r);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.t('highlights'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...highlights.map((highlight) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: highlight.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(highlight.icon, color: highlight.color, size: 20),
              ),
              title: Text(
                highlight.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(highlight.subtitle),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hoạt động gần đây',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.timeline,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chưa có hoạt động nào',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<_Highlight> _getHighlights(BuildContext context, AnalysisResult r) {
    final highlights = <_Highlight>[];
    final text = (r.categories.map((e) => '${e.categoryName} ${e.summary}').join('\n') + 
                 '\n' + r.metrics.map((m) => '${m.name} ${m.classification}').join('\n')).toLowerCase();
    final isEn = AppStringsScope.of(context) == AppLang.en;

    if (text.contains('egfr') || text.contains('thận') || text.contains('than')) {
      highlights.add(_Highlight(
        icon: Icons.water_drop,
        color: const Color(0xFF3498DB),
        title: isEn ? 'Kidney Health' : 'Sức khỏe thận',
        subtitle: isEn ? 'Stay hydrated, reduce salt intake' : 'Uống đủ nước, hạn chế muối',
      ));
    }
    
    if (text.contains('gan') || text.contains('alt') || text.contains('ast') || text.contains('liver')) {
      highlights.add(_Highlight(
        icon: Icons.health_and_safety,
        color: const Color(0xFFE67E22),
        title: isEn ? 'Liver Health' : 'Sức khỏe gan',
        subtitle: isEn ? 'Avoid alcohol and fried foods' : 'Tránh rượu và thức ăn chiên rán',
      ));
    }
    
    if (text.contains('glucose') || text.contains('đường') || text.contains('duong') || text.contains('sugar')) {
      highlights.add(_Highlight(
        icon: Icons.restaurant,
        color: const Color(0xFF2ECC71),
        title: isEn ? 'Blood Sugar' : 'Đường huyết',
        subtitle: isEn ? 'Add more greens, reduce sweets' : 'Tăng rau xanh, giảm đồ ngọt',
      ));
    }

    if (highlights.isEmpty) {
      highlights.addAll([
        _Highlight(
          icon: Icons.local_drink,
          color: const Color(0xFF3498DB),
          title: isEn ? 'Stay Hydrated' : 'Uống đủ nước',
          subtitle: isEn ? 'Drink 6-8 glasses daily' : 'Duy trì 6-8 ly nước mỗi ngày',
        ),
        _Highlight(
          icon: Icons.directions_walk,
          color: const Color(0xFF2ECC71),
          title: isEn ? 'Stay Active' : 'Vận động đều đặn',
          subtitle: isEn ? 'Light exercise 30 minutes daily' : 'Vận động nhẹ 30 phút mỗi ngày',
        ),
      ]);
    }

    return highlights.take(3).toList();
  }
}

class _Highlight {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  _Highlight({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}


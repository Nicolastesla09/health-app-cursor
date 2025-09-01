class OverallHealthScore {
  final num score; // 0..100
  final String label;
  final String explanation;

  OverallHealthScore({required this.score, required this.label, required this.explanation});

  factory OverallHealthScore.fromJson(Map<String, dynamic> j) => OverallHealthScore(
        score: j['score'] ?? 0,
        label: j['label'] ?? '',
        explanation: j['explanation'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'score': score,
        'label': label,
        'explanation': explanation,
      };
}

class HealthCategory {
  final String categoryName;
  final num score; // 0..10
  final String summary;
  final String iconName;

  HealthCategory({
    required this.categoryName,
    required this.score,
    required this.summary,
    required this.iconName,
  });

  factory HealthCategory.fromJson(Map<String, dynamic> j) => HealthCategory(
        categoryName: j['categoryName'] is List
            ? (j['categoryName'] as List).join(' ')
            : (j['categoryName'] ?? ''),
        score: j['score'] ?? 0,
        summary: j['summary'] ?? '',
        iconName: j['iconName'] ?? 'Activity',
      );

  Map<String, dynamic> toJson() => {
        'categoryName': categoryName,
        'score': score,
        'summary': summary,
        'iconName': iconName,
      };
}

class MetricItem {
  final String name;
  final String value;
  final String unit;
  final String referenceRange;
  final String classification; // Cao/Thấp/Bình thường
  final String explanation;

  MetricItem({
    required this.name,
    required this.value,
    required this.unit,
    required this.referenceRange,
    required this.classification,
    required this.explanation,
  });

  factory MetricItem.fromJson(Map<String, dynamic> j) => MetricItem(
        name: j['name'] ?? '',
        value: j['value'] ?? '',
        unit: j['unit'] ?? '',
        referenceRange: j['referenceRange'] ?? '',
        classification: j['classification'] ?? '',
        explanation: j['explanation'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
        'unit': unit,
        'referenceRange': referenceRange,
        'classification': classification,
        'explanation': explanation,
      };
}

class RecommendedFood {
  final String foodName;
  final String benefit;
  final String servingSuggestion;
  final String suggestedStore; // Lotte Mart/Co.op Food/Bách Hóa Xanh

  RecommendedFood({
    required this.foodName,
    required this.benefit,
    required this.servingSuggestion,
    required this.suggestedStore,
  });

  factory RecommendedFood.fromJson(Map<String, dynamic> j) => RecommendedFood(
        foodName: j['foodName'] ?? '',
        benefit: j['benefit'] ?? '',
        servingSuggestion: j['servingSuggestion'] ?? '',
        suggestedStore: j['suggestedStore'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'foodName': foodName,
        'benefit': benefit,
        'servingSuggestion': servingSuggestion,
        'suggestedStore': suggestedStore,
      };
}

class AnalysisResult {
  final OverallHealthScore overallHealthScore;
  final String bmiSummary;
  final List<HealthCategory> categories;
  final List<MetricItem> metrics;
  final List<RecommendedFood> recommendedFoods;

  AnalysisResult({
    required this.overallHealthScore,
    required this.bmiSummary,
    required this.categories,
    required this.metrics,
    required this.recommendedFoods,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> j) => AnalysisResult(
        overallHealthScore: OverallHealthScore.fromJson(j['overallHealthScore'] ?? {}),
        bmiSummary: (j['bmiAnalysis']?['summary'] ?? '') as String,
        categories: (j['healthAnalysis']?['categories'] as List? ?? [])
            .map((e) => HealthCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
        metrics: (j['metrics'] as List? ?? [])
            .map((e) => MetricItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        recommendedFoods: (j['recommendedFoods'] as List? ?? [])
            .map((e) => RecommendedFood.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'overallHealthScore': overallHealthScore.toJson(),
        'bmiAnalysis': {'summary': bmiSummary},
        'healthAnalysis': {'categories': categories.map((e) => e.toJson()).toList()},
        'metrics': metrics.map((e) => e.toJson()).toList(),
        'recommendedFoods': recommendedFoods.map((e) => e.toJson()).toList(),
      };
}

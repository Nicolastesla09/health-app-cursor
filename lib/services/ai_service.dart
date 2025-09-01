import 'dart:typed_data';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/analysis.dart';
import '../models/plan.dart';

class AiService {
  // Prefer env if provided, else fall back to baked-in key
  // so the app runs without --dart-define every time.
  static const _envApiKey = String.fromEnvironment('API_KEY');
  static const _fallbackApiKey = 'AIzaSyAvG-tC7bXwVW3DPleOoF28NQ-oh3jhm44';
  static String get _resolvedApiKey =>
      _envApiKey.isNotEmpty ? _envApiKey : _fallbackApiKey;
  static const _modelName = String.fromEnvironment('MODEL', defaultValue: 'gemini-1.5-flash');

  final GenerativeModel _model;

  AiService()
      : _model = GenerativeModel(
          model: _modelName,
          apiKey: _resolvedApiKey,
          safetySettings: const [],
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );

  Future<AnalysisResult> analyze({
    required int age,
    required double heightCm,
    required double weightKg,
    required String gender,
    required String occupation,
    required List<({Uint8List bytes, String mimeType})> files,
    String langCode = 'vi',
  }) async {
    // API key resolved via env or baked-in fallback.

    final bmi = weightKg / ((heightCm / 100.0) * (heightCm / 100.0));

    final prompt = _buildPromptV2(age, heightCm, weightKg, bmi, gender, occupation, langCode);

    final parts = <Part>[TextPart(prompt)];
    for (final f in files) {
      parts.add(DataPart(f.mimeType, f.bytes));
    }

    // Response schema mirroring the web app contract
    final schema = Schema.object(properties: {
      'overallHealthScore': Schema.object(properties: {
        'score': Schema.number(),
        'label': Schema.string(),
        'explanation': Schema.string(),
      }, requiredProperties: ['score', 'label', 'explanation']),
      'bmiAnalysis': Schema.object(properties: {
        'summary': Schema.string(),
      }, requiredProperties: ['summary']),
      'healthAnalysis': Schema.object(properties: {
        'categories': Schema.array(items: Schema.object(properties: {
          'categoryName': Schema.array(items: Schema.string()),
          'score': Schema.number(),
          'summary': Schema.string(),
          'iconName': Schema.string(),
        }, requiredProperties: ['categoryName', 'score', 'summary', 'iconName'])),
      }, requiredProperties: ['categories']),
      'metrics': Schema.array(items: Schema.object(properties: {
        'name': Schema.string(),
        'value': Schema.string(),
        'unit': Schema.string(),
        'referenceRange': Schema.string(),
        'classification': Schema.string(),
        'explanation': Schema.string(),
      }, requiredProperties: ['name', 'value', 'unit', 'referenceRange', 'classification', 'explanation'])),
      'recommendedFoods': Schema.array(items: Schema.object(properties: {
        'foodName': Schema.string(),
        'benefit': Schema.string(),
        'servingSuggestion': Schema.string(),
        'suggestedStore': Schema.string(),
      }, requiredProperties: ['foodName', 'benefit', 'servingSuggestion', 'suggestedStore'])),
    }, requiredProperties: [
      'overallHealthScore',
      'bmiAnalysis',
      'healthAnalysis',
      'metrics',
      'recommendedFoods',
    ]);

    final response = await _model.generateContent(
      [Content.multi(parts)],
      generationConfig: GenerationConfig(responseMimeType: 'application/json', responseSchema: schema),
    );

    final text = response.text ?? '{}';
    final jsonMap = jsonDecode(text) as Map<String, dynamic>;
    return AnalysisResult.fromJson(jsonMap);
  }

  // Wrap base prompt with language guidance to ensure EN/VI outputs
  String _buildPromptV2(int age, double height, double weight, double bmi, String gender, String occupation, String langCode) {
    final base = _buildPrompt(age, height, weight, bmi, gender, occupation);
    if (langCode == 'en') {
      return 'Please respond in clear English. Use classification terms High/Low/Normal and provide categoryName in English.\n' + base;
    }
    return base; // Vietnamese default
  }

  Future<String> askDoctor({required String question, AnalysisResult? context}) async {
    // Lightweight QA: allow free-form text, include recent metrics for context if available.
    final sb = StringBuffer();
    sb.writeln('Bạn là bác sĩ AI trả lời ngắn gọn, dễ hiểu, tiếng Việt.');
    if (context != null) {
      sb.writeln('Bối cảnh xét nghiệm gần nhất:');
      sb.writeln('- Điểm sức khỏe tổng: ${context.overallHealthScore.score} (${context.overallHealthScore.label})');
      if (context.metrics.isNotEmpty) {
        sb.writeln('- Một số chỉ số:');
        for (final m in context.metrics.take(8)) {
          sb.writeln('  • ${m.name}: ${m.value} ${m.unit} | ${m.classification}');
        }
      }
    }
    sb.writeln('Câu hỏi: $question');
    sb.writeln('Nếu chỉ số nguy hiểm, khuyến nghị đi khám bác sĩ ngay.');

    final response = await _model.generateContent([Content.text(sb.toString())], generationConfig: GenerationConfig());
    return response.text ?? 'Xin lỗi, tôi chưa có câu trả lời.';
  }

  String _buildPrompt(int age, double height, double weight, double bmi, String gender, String occupation) {
    return '''
Bạn là trợ lý AI y tế. Hãy phân tích dữ liệu xét nghiệm tải lên (ảnh/PDF) kết hợp thông tin người dùng sau:
- Tuổi: $age
- Giới tính: $gender
- Chiều cao: ${height.toStringAsFixed(0)} cm
- Cân nặng: ${weight.toStringAsFixed(1)} kg
- BMI: ${bmi.toStringAsFixed(1)}
- Nghề nghiệp: $occupation

Yêu cầu:
1) Tạo overallHealthScore (0..100) gồm score, label, explanation.
2) Viết tóm tắt BMI (bmiAnalysis.summary) bằng tiếng Việt, ngắn gọn.
3) healthAnalysis.categories (5-8 mục). Với mỗi mục gồm: categoryName (mảng từ để hiển thị multi-line), score (0..10), summary (rõ ràng, thực tế), iconName (HeartPulse/BrainCircuit/ShieldCheck/Flame/Bone/Droplets/Activity/TestTube2).
4) metrics: danh sách chỉ số chi tiết từ xét nghiệm với name, value, unit, referenceRange, classification (Cao/Thấp/Bình thường) và explanation.
5) recommendedFoods: 4-6 món ăn, kèm benefit, servingSuggestion và suggestedStore trong ['Lotte Mart','Co.op Food','Bách Hóa Xanh'].

Chỉ trả JSON đúng schema.''';
  }

  Future<MealPlan> generateMealPlan({
    required String goal, // e.g., giảm cân/tăng cơ/ăn sạch
    required String constraints, // thói quen, dị ứng, khung giờ
  }) async {
    // API key resolved via env or baked-in fallback.
    final prompt = '''
Bạn là chuyên gia dinh dưỡng. Tạo kế hoạch ăn uống 7 ngày bằng tiếng Việt, thực tế, dễ nấu tại Việt Nam.
Mục tiêu: $goal
Ràng buộc: $constraints

Trả JSON với schema:
{
  "summary": string,
  "days": [
    {"day": "Ngày 1", "breakfast": [{"name": string, "description": string, "calories": string}], "lunch": [...], "dinner": [...], "snacks": [...]},
    ... đến "Ngày 7"
  ]
}
''';
    final schema = Schema.object(properties: {
      'summary': Schema.string(),
      'days': Schema.array(items: Schema.object(properties: {
        'day': Schema.string(),
        'breakfast': Schema.array(items: Schema.object(properties: {
          'name': Schema.string(), 'description': Schema.string(), 'calories': Schema.string(),
        })),
        'lunch': Schema.array(items: Schema.object(properties: {
          'name': Schema.string(), 'description': Schema.string(), 'calories': Schema.string(),
        })),
        'dinner': Schema.array(items: Schema.object(properties: {
          'name': Schema.string(), 'description': Schema.string(), 'calories': Schema.string(),
        })),
        'snacks': Schema.array(items: Schema.object(properties: {
          'name': Schema.string(), 'description': Schema.string(), 'calories': Schema.string(),
        })),
      })),
    }, requiredProperties: ['summary', 'days']);

    final response = await _model.generateContent([
      Content.text(prompt),
    ], generationConfig: GenerationConfig(responseMimeType: 'application/json', responseSchema: schema));
    final text = response.text ?? '{}';
    return MealPlan.fromJson(jsonDecode(text));
  }

  Future<WorkoutPlan> generateWorkoutPlan({
    required String goal, // tăng sức bền, tăng cơ, giảm mỡ...
    required String level, // mới bắt đầu/trung bình/nâng cao
    required String equipment, // có/không có dụng cụ, thời gian mỗi buổi
  }) async {
    // API key resolved via env or baked-in fallback.
    final prompt = '''
Bạn là HLV thể hình. Tạo kế hoạch tập luyện 7 ngày bằng tiếng Việt, an toàn, có thể thực hiện tại nhà hoặc phòng gym.
Mục tiêu: $goal
Trình độ: $level
Thiết bị: $equipment

Trả JSON với schema:
{
  "summary": string,
  "days": [
    {"day": "Ngày 1", "items": [{"name": string, "focus": string, "prescription": string}]},
    ... đến "Ngày 7"
  ]
}
''';
    final schema = Schema.object(properties: {
      'summary': Schema.string(),
      'days': Schema.array(items: Schema.object(properties: {
        'day': Schema.string(),
        'items': Schema.array(items: Schema.object(properties: {
          'name': Schema.string(), 'focus': Schema.string(), 'prescription': Schema.string(),
        })),
      })),
    }, requiredProperties: ['summary', 'days']);

    final response = await _model.generateContent([
      Content.text(prompt),
    ], generationConfig: GenerationConfig(responseMimeType: 'application/json', responseSchema: schema));
    final text = response.text ?? '{}';
    return WorkoutPlan.fromJson(jsonDecode(text));
  }
}

import 'package:flutter/widgets.dart';

enum AppLang { vi, en }

class AppStrings {
  final AppLang lang;
  const AppStrings(this.lang);

  static const _t = {
    'dashboard': {'vi': 'Tổng quan', 'en': 'Dashboard'},
    'health': {'vi': 'Sức khỏe', 'en': 'Health'},
    'add': {'vi': 'Thêm', 'en': 'Add'},
    'plans': {'vi': 'Kế hoạch', 'en': 'Plans'},
    'profile': {'vi': 'Cá nhân', 'en': 'Profile'},
    'overall_health_score': {'vi': 'Điểm sức khỏe tổng', 'en': 'Overall Health Score'},
    'quick_actions': {'vi': 'Tác vụ nhanh', 'en': 'Quick Actions'},
    'qa_new_analysis': {'vi': 'Phân tích xét nghiệm mới', 'en': 'New Lab Analysis'},
    'qa_log_meal': {'vi': 'Nhập bữa ăn', 'en': 'Log Meal'},
    'qa_update_body': {'vi': 'Cập nhật cân nặng, chiều cao', 'en': 'Update Weight/Height'},
    'highlights': {'vi': 'Gợi ý nổi bật', 'en': 'Highlights'},
    'lab_results': {'vi': 'Kết quả xét nghiệm', 'en': 'Lab Results'},
    'history_trends': {'vi': 'Lịch sử & Xu hướng', 'en': 'History & Trends'},
    'ai_doctor': {'vi': 'Bác sĩ AI', 'en': 'AI Doctor'},
    'ask_here': {'vi': 'Hỏi về chỉ số, ăn uống, tập luyện...', 'en': 'Ask about labs, diet, training...'},
    'send': {'vi': 'Gửi', 'en': 'Send'},
    'no_data': {'vi': 'Chưa có dữ liệu', 'en': 'No data yet'},
    'personal_info': {'vi': 'Hồ sơ cá nhân', 'en': 'Personal Info'},
    'language': {'vi': 'Ngôn ngữ', 'en': 'Language'},
    'vietnamese': {'vi': 'Tiếng Việt', 'en': 'Vietnamese'},
    'english': {'vi': 'Tiếng Anh', 'en': 'English'},
    'categories_main': {'vi': 'Danh mục chính', 'en': 'Main Categories'},
    'metrics_table': {'vi': 'Bảng chỉ số', 'en': 'Metrics Table'},
    'reference_range': {'vi': 'Ngưỡng tham chiếu', 'en': 'Reference Range'},
    'status': {'vi': 'Trạng thái', 'en': 'Status'},
    'take_photo': {'vi': 'Chụp ảnh', 'en': 'Take photo'},
    'pick_files': {'vi': 'Chọn/Thêm ảnh hoặc PDF', 'en': 'Pick/Attach images or PDF'},
    'ai_lab_title': {'vi': 'Phân tích xét nghiệm AI', 'en': 'AI Lab Analysis'},
    'age': {'vi': 'Tuổi', 'en': 'Age'},
    'height_cm': {'vi': 'Chiều cao (cm)', 'en': 'Height (cm)'},
    'weight_kg': {'vi': 'Cân nặng (kg)', 'en': 'Weight (kg)'},
    'gender': {'vi': 'Giới tính', 'en': 'Gender'},
    'male': {'vi': 'Nam', 'en': 'Male'},
    'female': {'vi': 'Nữ', 'en': 'Female'},
    'occupation': {'vi': 'Công việc hiện tại', 'en': 'Occupation'},
    'analyze': {'vi': 'Phân tích', 'en': 'Analyze'},
    'analyzing': {'vi': 'Đang xử lý...', 'en': 'Analyzing...'},
    'day': {'vi': 'Ngày', 'en': 'Day'},
    'score': {'vi': 'Điểm', 'en': 'Score'},
    // Planner / Profile
    'meal_tab': {'vi': 'Thực đơn', 'en': 'Meals'},
    'workout_tab': {'vi': 'Bài tập', 'en': 'Workout'},
    'compact': {'vi': 'Gọn', 'en': 'Compact'},
    'goal': {'vi': 'Mục tiêu', 'en': 'Goal'},
    'constraints': {'vi': 'Ràng buộc', 'en': 'Constraints'},
    'level': {'vi': 'Trình độ', 'en': 'Level'},
    'equipment': {'vi': 'Thiết bị/Thời lượng', 'en': 'Equipment/Duration'},
    'create_meal': {'vi': 'Tạo thực đơn', 'en': 'Create meal plan'},
    'creating': {'vi': 'Đang tạo...', 'en': 'Creating...'},
    'create_workout': {'vi': 'Tạo bài tập', 'en': 'Create workout'},
    'gamification': {'vi': 'Thành tích', 'en': 'Gamification'},
    'settings': {'vi': 'Cài đặt', 'en': 'Settings'},
    'sync': {'vi': 'Đồng bộ dữ liệu', 'en': 'Sync data'},
    'coming_soon': {'vi': 'Tính năng sắp có', 'en': 'Coming soon'},
    'export_pdf': {'vi': 'Xuất PDF', 'en': 'Export PDF'},
    'go_to_results_export': {'vi': 'Vào Kết quả để xuất báo cáo', 'en': 'Export from Results tab'},
    'sign_out': {'vi': 'Đăng xuất', 'en': 'Sign out'},
  };

  String t(String key) {
    final m = _t[key];
    if (m == null) return key;
    return lang == AppLang.vi ? (m['vi'] ?? key) : (m['en'] ?? key);
  }

  static AppStrings of(BuildContext context) => AppStrings(AppStringsScope.of(context));
}

class AppStringsScope extends InheritedWidget {
  final AppLang lang;
  const AppStringsScope({super.key, required this.lang, required super.child});

  static AppLang of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<AppStringsScope>();
    return s?.lang ?? AppLang.vi;
  }

  @override
  bool updateShouldNotify(covariant AppStringsScope oldWidget) => oldWidget.lang != lang;
}

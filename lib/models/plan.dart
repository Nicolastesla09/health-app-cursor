class MealItem {
  final String name;
  final String description;
  final String calories;
  MealItem({required this.name, required this.description, required this.calories});
  factory MealItem.fromJson(Map<String, dynamic> j) => MealItem(
        name: j['name'] ?? '',
        description: j['description'] ?? '',
        calories: j['calories'] ?? '',
      );
  Map<String, dynamic> toJson() => {'name': name, 'description': description, 'calories': calories};
}

class MealDay {
  final String day;
  final List<MealItem> breakfast;
  final List<MealItem> lunch;
  final List<MealItem> dinner;
  final List<MealItem> snacks;
  MealDay({required this.day, required this.breakfast, required this.lunch, required this.dinner, required this.snacks});
  factory MealDay.fromJson(Map<String, dynamic> j) => MealDay(
        day: j['day'] ?? '',
        breakfast: (j['breakfast'] as List? ?? []).map((e) => MealItem.fromJson(e)).toList(),
        lunch: (j['lunch'] as List? ?? []).map((e) => MealItem.fromJson(e)).toList(),
        dinner: (j['dinner'] as List? ?? []).map((e) => MealItem.fromJson(e)).toList(),
        snacks: (j['snacks'] as List? ?? []).map((e) => MealItem.fromJson(e)).toList(),
      );
  Map<String, dynamic> toJson() => {
        'day': day,
        'breakfast': breakfast.map((e) => e.toJson()).toList(),
        'lunch': lunch.map((e) => e.toJson()).toList(),
        'dinner': dinner.map((e) => e.toJson()).toList(),
        'snacks': snacks.map((e) => e.toJson()).toList(),
      };
}

class MealPlan {
  final String summary;
  final List<MealDay> days;
  MealPlan({required this.summary, required this.days});
  factory MealPlan.fromJson(Map<String, dynamic> j) => MealPlan(
        summary: j['summary'] ?? '',
        days: (j['days'] as List? ?? []).map((e) => MealDay.fromJson(e)).toList(),
      );
  Map<String, dynamic> toJson() => {'summary': summary, 'days': days.map((e) => e.toJson()).toList()};
}

class WorkoutItem {
  final String name;
  final String focus; // body part/focus
  final String prescription; // sets x reps or duration
  WorkoutItem({required this.name, required this.focus, required this.prescription});
  factory WorkoutItem.fromJson(Map<String, dynamic> j) => WorkoutItem(
        name: j['name'] ?? '',
        focus: j['focus'] ?? '',
        prescription: j['prescription'] ?? '',
      );
  Map<String, dynamic> toJson() => {'name': name, 'focus': focus, 'prescription': prescription};
}

class WorkoutDay {
  final String day;
  final List<WorkoutItem> items;
  WorkoutDay({required this.day, required this.items});
  factory WorkoutDay.fromJson(Map<String, dynamic> j) => WorkoutDay(
        day: j['day'] ?? '',
        items: (j['items'] as List? ?? []).map((e) => WorkoutItem.fromJson(e)).toList(),
      );
  Map<String, dynamic> toJson() => {'day': day, 'items': items.map((e) => e.toJson()).toList()};
}

class WorkoutPlan {
  final String summary;
  final List<WorkoutDay> days;
  WorkoutPlan({required this.summary, required this.days});
  factory WorkoutPlan.fromJson(Map<String, dynamic> j) => WorkoutPlan(
        summary: j['summary'] ?? '',
        days: (j['days'] as List? ?? []).map((e) => WorkoutDay.fromJson(e)).toList(),
      );
  Map<String, dynamic> toJson() => {'summary': summary, 'days': days.map((e) => e.toJson()).toList()};
}

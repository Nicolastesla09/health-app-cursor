import 'package:flutter/material.dart';
import '../models/plan.dart';
import '../services/ai_service.dart';
import '../l10n.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  String _tab = 'meal';
  bool _compact = false;

  final _mealGoal = TextEditingController(text: 'Giảm mỡ, ăn cân bằng');
  final _mealConstraints = TextEditingController(text: 'Không dị ứng, 3 bữa chính + 1 bữa phụ mỗi ngày');
  final _workoutGoal = TextEditingController(text: 'Giảm mỡ, tăng sức bền');
  final _workoutLevel = TextEditingController(text: 'Mới bắt đầu');
  final _workoutEquipment = TextEditingController(text: '30 phút/buổi, có tạ tay nhẹ');

  MealPlan? _mealPlan;
  WorkoutPlan? _workoutPlan;
  String? _error;
  bool _loading = false;

  Future<void> _generateMeal() async {
    setState(() { _loading = true; _error = null; });
    try {
      final ai = AiService();
      final plan = await ai.generateMealPlan(goal: _mealGoal.text.trim(), constraints: _mealConstraints.text.trim());
      setState(() { _mealPlan = plan; });
    } catch (e) { setState(() { _error = 'Lỗi tạo thực đơn: $e'; }); }
    finally { setState(() { _loading = false; }); }
  }

  Future<void> _generateWorkout() async {
    setState(() { _loading = true; _error = null; });
    try {
      final ai = AiService();
      final plan = await ai.generateWorkoutPlan(goal: _workoutGoal.text.trim(), level: _workoutLevel.text.trim(), equipment: _workoutEquipment.text.trim());
      setState(() { _workoutPlan = plan; });
    } catch (e) { setState(() { _error = 'Lỗi tạo bài tập: $e'; }); }
    finally { setState(() { _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'meal', label: Text('Thực đơn')), 
              ButtonSegment(value: 'workout', label: Text('Bài tập'))
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() => _tab = s.first),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Gọn'),
                Switch(value: _compact, onChanged: (v) => setState(() => _compact = v)),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _tab == 'meal' ? _buildMeal(context) : _buildWorkout(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeal(BuildContext context) {
    final pad = EdgeInsets.all(_compact ? 12 : 16);
    final cardPad = EdgeInsets.all(_compact ? 10 : 12);
    return ListView(
      key: const ValueKey('meal'),
      padding: pad,
      children: [
        LayoutBuilder(builder: (ctx, c) {
          final narrow = c.maxWidth < 600;
          final gap = SizedBox(width: _compact ? 8 : 12);
          final row = Row(children: [
            Expanded(child: TextField(controller: _mealGoal, decoration: const InputDecoration(labelText: 'Mục tiêu'))),
            gap,
            Expanded(child: TextField(controller: _mealConstraints, decoration: const InputDecoration(labelText: 'Ràng buộc'))),
          ]);
          final col = Column(children: [
            TextField(controller: _mealGoal, decoration: const InputDecoration(labelText: 'Mục tiêu')),
            SizedBox(height: _compact ? 8 : 12),
            TextField(controller: _mealConstraints, decoration: const InputDecoration(labelText: 'Ràng buộc')),
          ]);
          return narrow ? col : row;
        }),
        SizedBox(height: _compact ? 8 : 12),
        FilledButton.icon(onPressed: _loading ? null : _generateMeal, icon: _loading? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.restaurant), label: Text(_loading? 'Đang tạo...' : 'Tạo thực đơn')),
        SizedBox(height: _compact ? 8 : 12),
        if (_mealPlan != null) ...[
          Card(child: Padding(padding: cardPad, child: Text(_mealPlan!.summary))),
          SizedBox(height: _compact ? 6 : 8),
          for (final d in _mealPlan!.days)
            Card(
              child: Padding(
                padding: cardPad,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.day, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: _compact ? 14 : null)),
                  SizedBox(height: _compact ? 4 : 6),
                  _section('Bữa sáng', d.breakfast),
                  _section('Bữa trưa', d.lunch),
                  _section('Bữa tối', d.dinner),
                  if (d.snacks.isNotEmpty) _section('Bữa phụ', d.snacks),
                ]),
              ),
            ),
        ],
      ],
    );
  }

  Widget _section(String title, List<MealItem> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      for (final m in items)
        ListTile(contentPadding: EdgeInsets.zero, dense: _compact, title: Text(m.name), subtitle: Text('${m.description}\n${m.calories}')),
      SizedBox(height: _compact ? 4 : 6),
    ]);
  }

  Widget _buildWorkout(BuildContext context) {
    final pad = EdgeInsets.all(_compact ? 12 : 16);
    final cardPad = EdgeInsets.all(_compact ? 10 : 12);
    return ListView(
      key: const ValueKey('workout'),
      padding: pad,
      children: [
        LayoutBuilder(builder: (ctx, c) {
          final narrow = c.maxWidth < 600;
          final goal = TextField(controller: _workoutGoal, decoration: const InputDecoration(labelText: 'Mục tiêu'));
          final level = TextField(controller: _workoutLevel, decoration: const InputDecoration(labelText: 'Trình độ'));
          if (narrow) {
            return Column(children: [goal, SizedBox(height: _compact ? 8 : 12), level]);
          }
          return Row(children: [Expanded(child: goal), SizedBox(width: _compact ? 8 : 12), Expanded(child: level)]);
        }),
        SizedBox(height: _compact ? 8 : 12),
        TextField(controller: _workoutEquipment, decoration: const InputDecoration(labelText: 'Thiết bị/Thời lượng')),
        SizedBox(height: _compact ? 8 : 12),
        FilledButton.icon(onPressed: _loading ? null : _generateWorkout, icon: _loading? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.fitness_center), label: Text(_loading? 'Đang tạo...' : 'Tạo bài tập')),
        SizedBox(height: _compact ? 8 : 12),
        if (_workoutPlan != null) ...[
          Card(child: Padding(padding: cardPad, child: Text(_workoutPlan!.summary))),
          SizedBox(height: _compact ? 6 : 8),
          for (final d in _workoutPlan!.days)
            Card(
              child: Padding(
                padding: cardPad,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.day, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: _compact ? 14 : null)),
                  SizedBox(height: _compact ? 4 : 6),
                  for (final w in d.items)
                    ListTile(contentPadding: EdgeInsets.zero, dense: _compact, title: Text(w.name), subtitle: Text('${w.focus} • ${w.prescription}')),
                ]),
              ),
            ),
        ],
      ],
    );
  }
}

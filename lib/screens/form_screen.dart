import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/analysis.dart';
import '../l10n.dart';
import '../services/ai_service.dart';

class FormScreen extends StatefulWidget {
  final Future<void> Function(AnalysisResult, Map<String, dynamic>) onAnalysisDone;
  const FormScreen({super.key, required this.onAnalysisDone});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _occupation = TextEditingController();
  String _gender = 'Nam';
  List<({Uint8List bytes, String mimeType, String name})> _files = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _occupation.dispose();
    super.dispose();
  }

  bool get _valid {
    return int.tryParse(_age.text) != null &&
        double.tryParse(_height.text) != null &&
        double.tryParse(_weight.text) != null &&
        _files.isNotEmpty;
  }

  Future<void> _pickFiles() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'heic', 'pdf'],
    );
    
    if (res == null || res.files.isEmpty) return;
    
    final picked = <({Uint8List bytes, String mimeType, String name})>[];
    for (final f in res.files) {
      if (f.bytes == null) continue;
      final name = f.name;
      final lower = name.toLowerCase();
      final ext = lower.contains('.') ? lower.split('.').last : '';
      final mime = lower.endsWith('.pdf') ? 'application/pdf' : 'image/$ext';
      picked.add((bytes: f.bytes!, mimeType: mime, name: name));
    }
    
    // Merge with existing selections and de-duplicate by name+length.
    final merged = <({Uint8List bytes, String mimeType, String name})>[];
    final seen = <String>{};
    for (final item in [..._files, ...picked]) {
      final key = '${item.name}|${item.bytes.length}';
      if (seen.add(key)) merged.add(item);
    }
    setState(() => _files = merged);
  }

  Future<void> _takePhoto() async {
    // Placeholder for camera capture; avoids adding extra dependencies.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chụp ảnh sẽ khả dụng khi bật quyền Camera. Sử dụng Tải lên để chọn ảnh hiện có.')),
    );
  }

  Future<void> _analyze() async {
    if (!_valid) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lang = AppStringsScope.of(context);
      final langCode = lang == AppLang.en ? 'en' : 'vi';
      final age = int.parse(_age.text);
      final h = double.parse(_height.text);
      final w = double.parse(_weight.text);
      final genderCode = _gender.toLowerCase().contains('nữ') || _gender.toLowerCase().contains('female') ? 'female' : 'male';
      final ai = AiService();
      final result = await ai.analyze(
        age: age,
        heightCm: h,
        weightKg: w,
        gender: genderCode,
        occupation: _occupation.text.trim(),
        files: _files.map((e) => (bytes: e.bytes, mimeType: e.mimeType)).toList(),
        langCode: langCode,
      );

      await widget.onAnalysisDone(result, {
        'age': age,
        'height': h,
        'weight': w,
        'gender': _gender,
        'occupation': _occupation.text.trim(),
      });
    } catch (e) {
      setState(() => _error = 'Có lỗi khi phân tích. Kiểm tra API_KEY/kết nối và thử lại.\n$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phân tích xét nghiệm AI', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Wrap(
              runSpacing: 12,
              spacing: 12,
              children: [
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: _age,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Tuổi', prefixIcon: Icon(Icons.cake_outlined)),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _height,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Chiều cao (cm)', prefixIcon: Icon(Icons.height)),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _weight,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cân nặng (kg)', prefixIcon: Icon(Icons.monitor_weight_outlined)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Giới tính:'),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Nam'),
                  selected: _gender == 'Nam',
                  onSelected: (_) => setState(() => _gender = 'Nam'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Nữ'),
                  selected: _gender == 'Nữ',
                  onSelected: (_) => setState(() => _gender = 'Nữ'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _occupation,
              decoration: const InputDecoration(labelText: 'Công việc hiện tại', prefixIcon: Icon(Icons.work_outline)),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(onPressed: _takePhoto, icon: const Icon(Icons.photo_camera_outlined), label: const Text('Chụp ảnh')),
              OutlinedButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Chọn/Thêm ảnh hoặc PDF'),
              ),
            ]),
            if (_files.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in _files.asMap().entries)
                    Chip(
                      avatar: const Icon(Icons.insert_drive_file_outlined),
                      label: Text(entry.value.name, overflow: TextOverflow.ellipsis),
                      onDeleted: () {
                        setState(() {
                          _files.removeAt(entry.key);
                        });
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: !_valid || _loading ? null : _analyze,
                icon: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                label: Text(_loading ? 'Đang xử lý...' : 'Phân tích'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

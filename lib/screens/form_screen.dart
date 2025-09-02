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
            // Header với icon và title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phân tích xét nghiệm AI',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tải lên kết quả xét nghiệm để nhận phân tích chi tiết',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Thông tin cá nhân
            _buildSectionTitle('Thông tin cá nhân', Icons.person_outline),
            const SizedBox(height: 16),
            
            // Form fields - responsive cho mobile
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 400;
                if (isNarrow) {
                  // Mobile layout - vertical
                  return Column(
                    children: [
                      _buildTextField(_age, 'Tuổi', Icons.cake_outlined, TextInputType.number),
                      const SizedBox(height: 16),
                      _buildTextField(_height, 'Chiều cao (cm)', Icons.height, TextInputType.number),
                      const SizedBox(height: 16),
                      _buildTextField(_weight, 'Cân nặng (kg)', Icons.monitor_weight_outlined, TextInputType.number),
                    ],
                  );
                } else {
                  // Tablet layout - horizontal
                  return Wrap(
                    runSpacing: 16,
                    spacing: 16,
                    children: [
                      SizedBox(
                        width: 160,
                        child: _buildTextField(_age, 'Tuổi', Icons.cake_outlined, TextInputType.number),
                      ),
                      SizedBox(
                        width: 180,
                        child: _buildTextField(_height, 'Chiều cao (cm)', Icons.height, TextInputType.number),
                      ),
                      SizedBox(
                        width: 180,
                        child: _buildTextField(_weight, 'Cân nặng (kg)', Icons.monitor_weight_outlined, TextInputType.number),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Giới tính
            _buildSectionTitle('Giới tính', Icons.person),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Nam'),
                    selected: _gender == 'Nam',
                    onSelected: (_) => setState(() => _gender = 'Nam'),
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Nữ'),
                    selected: _gender == 'Nữ',
                    onSelected: (_) => setState(() => _gender = 'Nữ'),
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Công việc
            _buildTextField(_occupation, 'Công việc hiện tại', Icons.work_outline, TextInputType.text),
            const SizedBox(height: 20),
            
            // Tải lên file
            _buildSectionTitle('Tải lên kết quả xét nghiệm', Icons.upload_file),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Chụp ảnh'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Chọn file'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            if (_files.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionTitle('File đã chọn (${_files.length})', Icons.file_copy),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _files.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                  ),
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: file.mimeType.startsWith('image/')
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          file.mimeType.startsWith('image/') ? Icons.image : Icons.picture_as_pdf,
                          color: file.mimeType.startsWith('image/')
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        file.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        file.mimeType.startsWith('image/') ? 'Hình ảnh' : 'PDF',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          setState(() {
                            _files.removeAt(index);
                          });
                        },
                        color: Theme.of(context).colorScheme.error,
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            
            // Nút phân tích
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            Container(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: !_valid || _loading ? null : _analyze,
                icon: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.analytics_outlined, size: 20),
                label: Text(
                  _loading ? 'Đang phân tích...' : 'Bắt đầu phân tích',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, TextInputType keyboardType) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

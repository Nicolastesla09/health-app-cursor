import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/analysis.dart';
import '../l10n.dart';
import '../services/ai_service.dart';

class FormScreen extends StatefulWidget {
  final Future<void> Function(AnalysisResult, Map<String, dynamic>) onAnalysisDone;
  const FormScreen({super.key, required this.onAnalysisDone});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _occupation = TextEditingController();
  String _gender = 'Nam';
  List<({Uint8List bytes, String mimeType, String name})> _files = [];
  bool _loading = false;
  String? _error;
  int _currentStep = 0;

  late AnimationController _animationController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pageController = PageController();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _occupation.dispose();
    super.dispose();
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return int.tryParse(_age.text) != null && 
               double.tryParse(_height.text) != null && 
               double.tryParse(_weight.text) != null;
      case 1:
        return true; // Gender and occupation are optional for proceeding
      case 2:
        return _files.isNotEmpty;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_canProceed && _currentStep < 2) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _pickFiles() async {
    HapticFeedback.mediumImpact();
    
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
    
    final merged = <({Uint8List bytes, String mimeType, String name})>[];
    final seen = <String>{};
    for (final item in [..._files, ...picked]) {
      final key = '${item.name}|${item.bytes.length}';
      if (seen.add(key)) merged.add(item);
    }
    setState(() => _files = merged);
  }

  Future<void> _takePhoto() async {
    HapticFeedback.lightImpact();
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text('Chức năng chụp ảnh sẽ được cập nhật trong phiên bản tới')),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _removeFile(int index) {
    HapticFeedback.lightImpact();
    setState(() => _files.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _files.isEmpty || _loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    HapticFeedback.mediumImpact();

    try {
      final ai = AiService();
      final age = int.parse(_age.text);
      final height = double.parse(_height.text);
      final weight = double.parse(_weight.text);
      final occupation = _occupation.text.trim();

      final result = await ai.analyzeLabs(
        files: _files,
        age: age,
        gender: _gender,
        height: height,
        weight: weight,
        occupation: occupation.isNotEmpty ? occupation : null,
      );

      if (result == null) {
        throw Exception('Không thể phân tích kết quả xét nghiệm. Vui lòng thử lại.');
      }

      final inputs = {
        'age': age,
        'gender': _gender,
        'height': height,
        'weight': weight,
        'occupation': occupation,
        'files': _files.length,
      };

      if (widget.onAnalysisDone != null) {
        await widget.onAnalysisDone(result, inputs);
      } else {
        throw Exception('Lỗi callback: không thể xử lý kết quả.');
      }
    } catch (e) {
      setState(() => _error = e.toString());
      HapticFeedback.heavyImpact();
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Progress Header
              _buildProgressHeader(context),
            
            // Form Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildBasicInfoStep(context, s),
                  _buildPersonalInfoStep(context, s),
                  _buildFileUploadStep(context, s),
                ],
              ),
            ),
            
            // Navigation Buttons
            _buildNavigationButtons(context),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phân tích xét nghiệm',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Bước ${_currentStep + 1}/3',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress Indicator
          Row(
            children: List.generate(3, (index) {
              final isActive = index <= _currentStep;
              final isCompleted = index < _currentStep;
              
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index < 2 ? 8 : 0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: isCompleted
                      ? Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            ),
                          ),
                        )
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep(BuildContext context, AppStrings s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            _buildStepHeader(
              context,
              '📊 Thông tin cơ bản',
              'Nhập thông tin cần thiết để phân tích chính xác',
            ),
            const SizedBox(height: 24),
            
            // Age Field
            _buildTextField(
              controller: _age,
              label: 'Tuổi',
              hint: 'Ví dụ: 25',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.cake_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Vui lòng nhập tuổi';
                final age = int.tryParse(value);
                if (age == null || age < 1 || age > 120) {
                  return 'Tuổi không hợp lệ (1-120)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Height and Weight Row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _height,
                    label: 'Chiều cao (cm)',
                    hint: '170',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.height,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Nhập chiều cao';
                      final height = double.tryParse(value);
                      if (height == null || height < 50 || height > 250) {
                        return 'Không hợp lệ';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _weight,
                    label: 'Cân nặng (kg)',
                    hint: '65',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.monitor_weight_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Nhập cân nặng';
                      final weight = double.tryParse(value);
                      if (weight == null || weight < 10 || weight > 300) {
                        return 'Không hợp lệ';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // BMI Display
            if (_height.text.isNotEmpty && _weight.text.isNotEmpty)
              _buildBMIDisplay(context),
          ],
        ),
    );
  }

  Widget _buildPersonalInfoStep(BuildContext context, AppStrings s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            context,
            '👤 Thông tin cá nhân',
            'Giúp AI phân tích chính xác hơn theo từng cá nhân',
          ),
          const SizedBox(height: 24),
          
          // Gender Selection
          Text(
            'Giới tính',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildGenderOption(context, 'Nam', Icons.male),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderOption(context, 'Nữ', Icons.female),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Occupation Field
          _buildTextField(
            controller: _occupation,
            label: 'Nghề nghiệp (tùy chọn)',
            hint: 'Ví dụ: Kỹ sư, Giáo viên, Sinh viên...',
            prefixIcon: Icons.work_outline,
            maxLines: 1,
          ),
          const SizedBox(height: 24),
          
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Thông tin này giúp AI đưa ra lời khuyên phù hợp với giới tính và lối sống của bạn.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadStep(BuildContext context, AppStrings s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            context,
            '📁 Tải lên xét nghiệm',
            'Hỗ trợ ảnh (JPG, PNG, HEIC) và file PDF',
          ),
          const SizedBox(height: 24),
          
          // Upload Actions
          Row(
            children: [
              Expanded(
                child: _buildUploadButton(
                  context,
                  onPressed: _pickFiles,
                  icon: Icons.upload_file,
                  label: 'Chọn file',
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUploadButton(
                  context,
                  onPressed: _takePhoto,
                  icon: Icons.camera_alt,
                  label: 'Chụp ảnh',
                  isPrimary: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Files List
          if (_files.isNotEmpty) ...[
            Text(
              'Đã chọn ${_files.length} file',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ..._files.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return _buildFileItem(context, file, index);
            }),
          ] else
            _buildEmptyFileState(context),
          
          // Error Display
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Back Button
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _prevStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Quay lại'),
                ),
              ),
            
            if (_currentStep > 0) const SizedBox(width: 12),
            
            // Next/Submit Button
            Expanded(
              flex: _currentStep == 0 ? 1 : 1,
              child: FilledButton(
                onPressed: _currentStep == 2 
                    ? (_files.isEmpty || _loading ? null : _submit)
                    : (_canProceed ? _nextStep : null),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _currentStep == 2 ? 'Phân tích ngay' : 'Tiếp tục',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader(BuildContext context, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onChanged: (_) => setState(() {}), // Trigger rebuild for BMI
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            prefixIcon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildBMIDisplay(BuildContext context) {
    final height = double.tryParse(_height.text);
    final weight = double.tryParse(_weight.text);
    
    if (height == null || weight == null) return const SizedBox.shrink();
    
    final bmi = weight / ((height / 100) * (height / 100));
    final bmiText = bmi.toStringAsFixed(1);
    
    String category;
    Color color;
    
    if (bmi < 18.5) {
      category = 'Thiếu cân';
      color = const Color(0xFF2196F3);
    } else if (bmi < 25) {
      category = 'Bình thường';
      color = const Color(0xFF4CAF50);
    } else if (bmi < 30) {
      category = 'Thừa cân';
      color = const Color(0xFFFF9800);
    } else {
      category = 'Béo phì';
      color = const Color(0xFFF44336);
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.monitor_weight, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chỉ số BMI',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$bmiText - $category',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(BuildContext context, String gender, IconData icon) {
    final isSelected = _gender == gender;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _gender = gender);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              gender,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton(
    BuildContext context, {
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    return SizedBox(
      height: 56,
      child: isPrimary
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );
  }

  Widget _buildFileItem(
    BuildContext context,
    ({Uint8List bytes, String mimeType, String name}) file,
    int index,
  ) {
    final isImage = file.mimeType.startsWith('image/');
    final size = (file.bytes.length / 1024).toStringAsFixed(1);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isImage
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isImage ? Icons.image : Icons.picture_as_pdf,
            color: isImage
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary,
            size: 20,
          ),
        ),
        title: Text(
          file.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('$size KB'),
        trailing: IconButton(
          onPressed: () => _removeFile(index),
          icon: const Icon(Icons.delete_outline),
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  Widget _buildEmptyFileState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có file nào được chọn',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng tải lên ít nhất 1 file kết quả xét nghiệm\n(hỗ trợ JPG, PNG, HEIC, PDF)',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

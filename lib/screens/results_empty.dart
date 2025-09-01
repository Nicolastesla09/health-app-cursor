import 'package:flutter/material.dart';

class ResultsEmpty extends StatelessWidget {
  final VoidCallback? onGoToInput;
  const ResultsEmpty({super.key, this.onGoToInput});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_outlined, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            const Text('Chưa có kết quả', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Hãy vào tab "Nhập liệu" để tải ảnh/PDF xét nghiệm và phân tích.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onGoToInput,
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('Đi đến Nhập liệu'),
            ),
          ],
        ),
      ),
    );
  }
}


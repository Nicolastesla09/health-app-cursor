import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  final ValueChanged<String> onSignedIn;
  final VoidCallback onThemeToggle;
  const AuthScreen({super.key, required this.onSignedIn, required this.onThemeToggle});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPw = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Health Track', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Đăng nhập để tiếp tục', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: !_showPw,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _showPw = !_showPw),
                        icon: Icon(_showPw ? Icons.visibility : Icons.visibility_off),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final email = _email.text.trim();
                        if (email.isEmpty) return;
                        widget.onSignedIn(email);
                      },
                      child: const Text('Đăng nhập'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: widget.onThemeToggle,
                    icon: const Icon(Icons.color_lens_outlined),
                    label: const Text('Đổi giao diện'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tuyên bố miễn trừ trách nhiệm: Ứng dụng dùng AI để cung cấp thông tin tham khảo, không thay thế tư vấn y tế chuyên nghiệp. Luôn tham khảo ý kiến bác sĩ để có chẩn đoán và điều trị chính xác.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

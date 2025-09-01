import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n.dart';

class ProfileScreen extends StatelessWidget {
  final AppLang lang;
  final ValueChanged<AppLang> onLanguageChange;
  final Future<void> Function() onSignOut;
  const ProfileScreen({super.key, required this.lang, required this.onLanguageChange, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(lang);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.t('personal_info'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: const Text('User'),
              subtitle: const Text('Health goals: Better habits'),
            ),
          ),
          const SizedBox(height: 12),
          Text('Gamification', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(children: const [
                _Stat(label: 'Health XP', value: '1200'),
                SizedBox(width: 12),
                _Stat(label: 'Streak', value: '7d'),
                SizedBox(width: 12),
                _Stat(label: 'Badges', value: '3'),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Text('Settings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(s.t('language')),
                subtitle: Text(lang == AppLang.vi ? s.t('vietnamese') : s.t('english')),
                trailing: DropdownButton<AppLang>(
                  value: lang,
                  items: const [
                    DropdownMenuItem(value: AppLang.vi, child: Text('Tiếng Việt')),
                    DropdownMenuItem(value: AppLang.en, child: Text('English')),
                  ],
                  onChanged: (v) { if (v != null) onLanguageChange(v); },
                ),
              ),
              const Divider(height: 0),
              ListTile(leading: const Icon(Icons.cloud_sync_outlined), title: const Text('Đồng bộ dữ liệu'), subtitle: const Text('Tính năng sắp có')), 
              const Divider(height: 0),
              ListTile(leading: const Icon(Icons.picture_as_pdf_outlined), title: const Text('Xuất PDF'), subtitle: const Text('Vào Kết quả để xuất báo cáo')), 
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Đăng xuất'),
                onTap: () async {
                  // Clear stored email as part of sign-out
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('user_email');
                  await onSignOut();
                },
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ]),
    );
  }
}


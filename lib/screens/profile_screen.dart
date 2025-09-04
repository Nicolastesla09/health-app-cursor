import 'package:flutter/material.dart';
import '../l10n.dart';

class ProfileScreen extends StatefulWidget {
  final AppLang lang;
  final ValueChanged<AppLang> onLanguageChange;
  final Future<void> Function() onSignOut;

  const ProfileScreen({
    super.key,
    required this.lang,
    required this.onLanguageChange,
    required this.onSignOut,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('profile')),
      ),
      body: ListView(
        children: [
          // Language Settings
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(s.t('language')),
            subtitle: Text(widget.lang == AppLang.en ? 'English' : 'Tiếng Việt'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(s.t('language')),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Tiếng Việt'),
                        leading: Radio<AppLang>(
                          value: AppLang.vi,
                          groupValue: widget.lang,
                          onChanged: (value) {
                            if (value != null) {
                              widget.onLanguageChange(value);
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text('English'),
                        leading: Radio<AppLang>(
                          value: AppLang.en,
                          groupValue: widget.lang,
                          onChanged: (value) {
                            if (value != null) {
                              widget.onLanguageChange(value);
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const Divider(),

          // Sign Out
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xác nhận'),
                  content: const Text('Bạn có chắc muốn đăng xuất?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await widget.onSignOut();
              }
            },
          ),
        ],
      ),
    );
  }
}

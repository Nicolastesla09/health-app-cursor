import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/analysis.dart';
import 'l10n.dart';
import 'screens/auth_screen.dart';
// import 'screens/results_screen.dart';
// import 'screens/results_empty.dart';
import 'screens/planner_screen.dart';
// import 'screens/history_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/health_screen.dart';
import 'screens/add_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HealthTrackApp());
}

class HealthTrackApp extends StatefulWidget {
  const HealthTrackApp({super.key});

  @override
  State<HealthTrackApp> createState() => _HealthTrackAppState();
}

class _HealthTrackAppState extends State<HealthTrackApp> {
  ThemeMode _themeMode = ThemeMode.system;
  String? _email;
  AnalysisResult? _lastResult;
  AppLang _lang = AppLang.vi;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    final theme = prefs.getString('theme_mode');
    final lang = prefs.getString('app_lang');
    setState(() {
      _email = email;
      _themeMode = switch (theme) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      };
      _lang = (lang == 'en') ? AppLang.en : AppLang.vi;
    });
    if (email != null) {
      await _loadLatestFromHistory(email);
    }
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    });
    setState(() => _themeMode = mode);
  }

  Future<void> _onSignedIn(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
    setState(() => _email = email);
    await _loadLatestFromHistory(email);
  }

  Future<void> _onSignOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    setState(() => _email = null);
  }

  Future<void> _loadLatestFromHistory(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'health_history_${email}';
      final list = prefs.getStringList(key) ?? const <String>[];
      if (list.isNotEmpty) {
        // Newest item stored at index 0 in _saveToHistory
        final latestJson = list.first;
        final m = jsonDecode(latestJson) as Map<String, dynamic>;
        final analysis = AnalysisResult.fromJson(m['analysis'] as Map<String, dynamic>);
        setState(() => _lastResult = analysis);
      }
    } catch (_) {
      // Ignore corrupted history entries.
    }
  }

  Future<void> _saveToHistory(AnalysisResult result, Map<String, dynamic> inputs) async {
    // Always update in-memory last result so the Results tab can render,
    // even if the user isn't signed in yet. Persist to history only when logged in.
    if (_email != null) {
      final prefs = await SharedPreferences.getInstance();
      final key = 'health_history_${_email!}';
      final list = prefs.getStringList(key) ?? <String>[];
      final item = jsonEncode({
        'date': DateTime.now().toIso8601String(),
        'analysis': result.toJson(),
        'inputs': inputs,
      });
      list.insert(0, item);
      await prefs.setStringList(key, list);
    }
    setState(() => _lastResult = result);
  }

  Future<void> _setLanguage(AppLang lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', lang == AppLang.en ? 'en' : 'vi');
    setState(() => _lang = lang);
  }

  @override
  Widget build(BuildContext context) {
    return AppStringsScope(
      lang: _lang,
      child: MaterialApp(
        title: 'Health Track',
        themeMode: _themeMode,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5A8A3A)),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF98C379), brightness: Brightness.dark),
          useMaterial3: true,
        ),
        home: _email == null
            ? AuthScreen(onSignedIn: _onSignedIn, onThemeToggle: () {
                _setThemeMode(_themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
              })
            : _Home(
                email: _email!,
                themeMode: _themeMode,
                onThemeChange: _setThemeMode,
                onSignOut: _onSignOut,
                lastResult: _lastResult,
                onSaveHistory: _saveToHistory,
                lang: _lang,
                onLanguageChange: _setLanguage,
              ),
      ),
    );
  }
}

class _Home extends StatefulWidget {
  final String email;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChange;
  final Future<void> Function() onSignOut;
  final AnalysisResult? lastResult;
  final Future<void> Function(AnalysisResult, Map<String, dynamic>) onSaveHistory;
  final AppLang lang;
  final ValueChanged<AppLang> onLanguageChange;

  const _Home({
    required this.email,
    required this.themeMode,
    required this.onThemeChange,
    required this.onSignOut,
    required this.lastResult,
    required this.onSaveHistory,
    required this.lang,
    required this.onLanguageChange,
  });

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  String _tab = 'dashboard';

  @override
  Widget build(BuildContext context) {
    final lang = AppStringsScope.of(context);
    final s = AppStrings(lang);
    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => setState(() => _tab = 'add'),
        tooltip: s.t('add'),
        child: const Icon(Icons.add, size: 20),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      appBar: AppBar(
        title: const Text('Health Track'),
        actions: [
          IconButton(
            tooltip: 'Đổi giao diện',
            onPressed: () => widget.onThemeChange(
              widget.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
            ),
            icon: Icon(widget.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: switch (_tab) {
          'dashboard' => DashboardScreen(
              lastResult: widget.lastResult,
              onNewAnalysis: () => setState(() => _tab = 'add'),
              onLogMeal: () => setState(() => _tab = 'plans'),
              onUpdateBody: () => setState(() => _tab = 'add'),
            ),
          'health' => HealthScreen(email: widget.email, lastResult: widget.lastResult),
          'add' => AddScreen(
              onAnalysisDone: (r, inputs) async {
                await widget.onSaveHistory(r, inputs);
                if (mounted) setState(() => _tab = 'health');
              },
            ),
          'plans' => const PlannerScreen(),
          'profile' => ProfileScreen(lang: widget.lang, onLanguageChange: widget.onLanguageChange, onSignOut: widget.onSignOut),
          _ => DashboardScreen(lastResult: widget.lastResult, onNewAnalysis: () => setState(() => _tab = 'add'), onLogMeal: () => setState(() => _tab = 'plans'), onUpdateBody: () => setState(() => _tab = 'add')),
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: switch (_tab) { 'dashboard' => 0, 'health' => 1, 'plans' => 2, 'profile' => 3, _ => 0 },
        onDestinationSelected: (i) => setState(() => _tab = ['dashboard', 'health', 'plans', 'profile'][i]),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.dashboard_outlined), label: s.t('dashboard')),
          NavigationDestination(icon: const Icon(Icons.favorite_outline), label: s.t('health')),
          NavigationDestination(icon: const Icon(Icons.auto_awesome), label: s.t('plans')),
          NavigationDestination(icon: const Icon(Icons.person_outline), label: s.t('profile')),
        ],
      ),
    );
  }
}


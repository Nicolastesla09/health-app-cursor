import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/analysis.dart';
import 'l10n.dart';
import 'screens/auth_screen.dart';
import 'screens/planner_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/health_screen.dart';
import 'screens/add_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style for better mobile experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  
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
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        debugShowCheckedModeBanner: false,
        home: _email == null
            ? AuthScreen(
                onSignedIn: _onSignedIn, 
                onThemeToggle: () {
                  _setThemeMode(_themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
                }
              )
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

  ThemeData _buildLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5A8A3A),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF98C379),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

class _HomeState extends State<_Home> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    // Animate FAB for add screen
    if (index == 2) {
      _fabAnimationController.reverse();
    } else {
      _fabAnimationController.forward();
    }
  }

  void _onAddPressed() {
    setState(() => _selectedIndex = 2);
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _fabAnimationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppStringsScope.of(context);
    final s = AppStrings(lang);
    
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.favorite,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Health Track'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Đổi giao diện',
            onPressed: () => widget.onThemeChange(
              widget.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
            ),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                widget.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                key: ValueKey(widget.themeMode),
              ),
            ),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _selectedIndex = index);
          if (index == 2) {
            _fabAnimationController.reverse();
          } else {
            _fabAnimationController.forward();
          }
        },
        children: [
          DashboardScreen(
            lastResult: widget.lastResult,
            onNewAnalysis: () => _onDestinationSelected(2),
            onLogMeal: () => _onDestinationSelected(3),
            onUpdateBody: () => _onDestinationSelected(2),
          ),
          HealthScreen(email: widget.email, lastResult: widget.lastResult),
          AddScreen(
            onAnalysisDone: (r, inputs) async {
              await widget.onSaveHistory(r, inputs);
              if (mounted) _onDestinationSelected(1);
            },
          ),
          const PlannerScreen(),
          ProfileScreen(
            lang: widget.lang,
            onLanguageChange: widget.onLanguageChange,
            onSignOut: widget.onSignOut,
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimationController,
        child: FloatingActionButton(
          onPressed: _onAddPressed,
          tooltip: s.t('add'),
          elevation: 4,
          child: const Icon(Icons.add, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.95),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard),
              label: s.t('dashboard'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.favorite_outline),
              selectedIcon: const Icon(Icons.favorite),
              label: s.t('health'),
            ),
            NavigationDestination(
              icon: const SizedBox(width: 24), // Placeholder for FAB space
              label: '',
            ),
            NavigationDestination(
              icon: const Icon(Icons.auto_awesome_outlined),
              selectedIcon: const Icon(Icons.auto_awesome),
              label: s.t('plans'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: s.t('profile'),
            ),
          ],
        ),
      ),
    );
  }
}
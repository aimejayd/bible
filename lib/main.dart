import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'bible_storage.dart';
import 'screens/read_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/today_screen.dart';
import 'splash.dart';
import 'theme.dart';

void main() => runApp(const IjamboApp());

class IjamboApp extends StatefulWidget {
  const IjamboApp({super.key, this.splashDuration = const Duration(milliseconds: 1600)});

  /// How long the branded splash stays up at minimum.
  final Duration splashDuration;

  @override
  State<IjamboApp> createState() => _IjamboAppState();
}

class _IjamboAppState extends State<IjamboApp> {
  final _controller = AppController(BibleStorage());
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future.wait([_controller.load(), Future<void>.delayed(widget.splashDuration)]).whenComplete(() {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => MaterialApp(
          title: 'Ijambo Bible',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: _controller.themeMode,
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 550),
            switchInCurve: Curves.easeOutCubic,
            child: _ready ? HomeShell(key: const ValueKey('home'), controller: _controller) : const SplashView(key: ValueKey('splash')),
          ),
        ),
      );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});
  final AppController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  void _goToReader() => setState(() => _tab = 1);

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          TodayScreen(controller: c, onRead: _goToReader),
          ReadScreen(controller: c),
          SavedScreen(controller: c, onOpen: _goToReader),
          SettingsScreen(controller: c),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.wb_sunny_outlined), selectedIcon: Icon(Icons.wb_sunny_rounded), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'Read'),
          NavigationDestination(icon: Icon(Icons.bookmark_outline_rounded), selectedIcon: Icon(Icons.bookmark_rounded), label: 'Saved'),
          NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}

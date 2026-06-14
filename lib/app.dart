import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'screens/auth_gate.dart';
import 'screens/onboarding_screen.dart';
import 'state/app_controller.dart';
import 'theme/app_theme.dart';

class SudarshanMobileApp extends StatefulWidget {
  const SudarshanMobileApp({super.key});

  @override
  State<SudarshanMobileApp> createState() => _SudarshanMobileAppState();
}

class _SudarshanMobileAppState extends State<SudarshanMobileApp>
    with WidgetsBindingObserver {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AppController()..initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _controller.updateAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _controller.handleAppResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'Sudarshan Mobile',
          debugShowCheckedModeBanner: false,
          theme: buildSudarshanTheme(isDark: false),
          darkTheme: buildSudarshanTheme(isDark: true),
          themeMode: _controller.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: _controller.isBooting
              ? const _BootScreen()
              : !_controller.onboardingDone
                  ? OnboardingScreen(controller: _controller)
                  : _controller.hasSession
                      ? HomeShell(controller: _controller)
                      : AuthGateScreen(controller: _controller),
        );
      },
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

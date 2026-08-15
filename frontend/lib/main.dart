import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() {
  runApp(const HerDoorApp());
}

class HerDoorApp extends StatefulWidget {
  const HerDoorApp({super.key});

  @override
  State<HerDoorApp> createState() => _HerDoorAppState();
}

class _HerDoorAppState extends State<HerDoorApp> {
  bool _isSplashDone = false;
  bool _isLoggedIn = false; // Opens Login / Register / Forgot Password screen after splash

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HerDoor Flour Mill',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: !_isSplashDone
          ? SplashScreen(
              onFinish: () => setState(() => _isSplashDone = true),
            )
          : (_isLoggedIn
              ? MainNavigationScreen(
                  onLogout: () => setState(() => _isLoggedIn = false),
                )
              : LoginScreen(
                  onLoginSuccess: () => setState(() => _isLoggedIn = true),
                )),
    );
  }
}

import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'models/merchant_models.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/merchant/merchant_main_navigation_screen.dart';
import 'screens/delivery/delivery_main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HerDoorApp());
}

class HerDoorApp extends StatefulWidget {
  const HerDoorApp({super.key});

  @override
  State<HerDoorApp> createState() => _HerDoorAppState();
}

class _HerDoorAppState extends State<HerDoorApp> {
  bool _isSplashDone = false;
  bool _isLoggedIn = false;
  UserRole _activeRole = UserRole.delivery; // Default to Delivery to showcase new rider side

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
              ? (_activeRole == UserRole.merchant
                  ? MerchantMainNavigationScreen(
                      onLogout: () => setState(() => _isLoggedIn = false),
                      onSwitchToCustomer: () {
                        setState(() {
                          _activeRole = UserRole.customer;
                        });
                      },
                    )
                  : (_activeRole == UserRole.delivery
                      ? DeliveryMainNavigationScreen(
                          onLogout: () => setState(() => _isLoggedIn = false),
                          onSwitchToCustomer: () {
                            setState(() {
                              _activeRole = UserRole.customer;
                            });
                          },
                          onSwitchToMerchant: () {
                            setState(() {
                              _activeRole = UserRole.merchant;
                            });
                          },
                        )
                      : MainNavigationScreen(
                          onLogout: () => setState(() => _isLoggedIn = false),
                          onSwitchToMerchant: () {
                            setState(() {
                              _activeRole = UserRole.merchant;
                            });
                          },
                        )))
              : LoginScreen(
                  onLoginSuccess: (role) {
                    setState(() {
                      _activeRole = role;
                      _isLoggedIn = true;
                    });
                  },
                )),
    );
  }
}

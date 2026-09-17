import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/merchant_models.dart';
import 'delivery_dashboard_screen.dart';
import 'delivery_trip_sheet_screen.dart';
import 'delivery_earnings_screen.dart';
import 'delivery_profile_screen.dart';
import 'delivery_drawer.dart';

import '../../services/auth_api_service.dart';

class DeliveryMainNavigationScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback onSwitchToCustomer;
  final VoidCallback onSwitchToMerchant;

  const DeliveryMainNavigationScreen({
    super.key,
    required this.onLogout,
    required this.onSwitchToCustomer,
    required this.onSwitchToMerchant,
  });

  @override
  State<DeliveryMainNavigationScreen> createState() => _DeliveryMainNavigationScreenState();
}

class _DeliveryMainNavigationScreenState extends State<DeliveryMainNavigationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  DeliveryTrip? _currentActiveTrip;

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final tab = await AuthApiService.instance.getSavedTab(UserRole.delivery);
    final allSavedTrips = await AuthApiService.instance.getAllSavedActiveTrips();

    if (mounted) {
      setState(() {
        if (tab >= 0 && tab < 4) {
          _currentIndex = tab;
        }
        if (allSavedTrips.isNotEmpty) {
          try {
            _currentActiveTrip = DeliveryTrip.fromJson(allSavedTrips.first);
            _currentIndex = 1; // Direct to trip sheet if active trip restored
          } catch (e) {
            debugPrint('Failed to parse saved active trip: $e');
          }
        }
      });
    }
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _onSelectTab(int index) {
    setState(() => _currentIndex = index);
    AuthApiService.instance.saveActiveTab(UserRole.delivery, index);
  }

  void _setActiveTrip(DeliveryTrip? trip) {
    setState(() {
      _currentActiveTrip = trip;
    });
    if (trip != null) {
      AuthApiService.instance.saveActiveTripData(trip.toJson());
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DeliveryDashboardScreen(
        onOpenDrawer: _openDrawer,
        onTripAccepted: (trip) {
          _setActiveTrip(trip);
          _onSelectTab(1); // Switch to Trip Sheet tab
        },
      ),
      DeliveryTripSheetScreen(
        activeTrip: _currentActiveTrip,
        onOpenDrawer: _openDrawer,
        onTripSelected: (trip) {
          _setActiveTrip(trip);
        },
        onExploreRadar: () {
          _onSelectTab(0);
        },
        onTripCompleted: () {
          _setActiveTrip(null);
        },
      ),
      DeliveryEarningsScreen(
        onOpenDrawer: _openDrawer,
      ),
      DeliveryProfileScreen(
        onOpenDrawer: _openDrawer,
        onLogout: widget.onLogout,
        onSwitchToCustomer: widget.onSwitchToCustomer,
        onSwitchToMerchant: widget.onSwitchToMerchant,
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: DeliveryDrawer(
        onSelectTab: _onSelectTab,
        onLogout: widget.onLogout,
        onSwitchToCustomer: widget.onSwitchToCustomer,
        onSwitchToMerchant: widget.onSwitchToMerchant,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppTheme.borderLight, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryTerracotta,
          unselectedItemColor: AppTheme.textSecondary,
          selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500),
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.radar_rounded),
              activeIcon: Icon(Icons.radar_rounded, color: AppTheme.primaryTerracotta),
              label: 'Radar',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.navigation_outlined),
                  if (_currentActiveTrip != null)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF2ECC71),
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: const Icon(Icons.navigation_rounded, color: AppTheme.primaryTerracotta),
              label: 'Trip Sheet',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryTerracotta),
              label: 'Earnings',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.two_wheeler_outlined),
              activeIcon: Icon(Icons.two_wheeler_rounded, color: AppTheme.primaryTerracotta),
              label: 'Rider',
            ),
          ],
        ),
      ),
    );
  }
}

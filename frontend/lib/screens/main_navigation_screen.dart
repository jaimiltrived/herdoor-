import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'favorites_screen.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'mills_list_screen.dart';
import 'orders_list_screen.dart';
import '../widgets/app_drawer.dart';

class MainNavigationScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback? onSwitchToMerchant;

  const MainNavigationScreen({
    super.key,
    required this.onLogout,
    this.onSwitchToMerchant,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _isDrawerOpen = false;

  void _onSelectTab(int index) {
    setState(() {
      _currentIndex = index;
      _isDrawerOpen = false;
    });
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardScreen(
        onNavigateTab: _onSelectTab,
        onStartNewOrder: () => _onSelectTab(1),
        onOpenDrawer: _toggleDrawer,
      ),
      MillsListScreen(
        onStartOrder: () => _onSelectTab(2),
        onOpenDrawer: _toggleDrawer,
      ),
      OrdersListScreen(
        onOpenDrawer: _toggleDrawer,
      ),
      FavoritesScreen(
        onOpenDrawer: _toggleDrawer,
        onNavigateTab: _onSelectTab,
      ),
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth * 0.8;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          
          // Scrim overlay
          if (_isDrawerOpen)
            GestureDetector(
              onTap: _toggleDrawer,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                opacity: _isDrawerOpen ? 1.0 : 0.0,
                child: Container(
                  color: Colors.black54,
                ),
              ),
            ),
            
          // Custom Slow Drawer
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            left: _isDrawerOpen ? 0 : -drawerWidth,
            top: 0,
            bottom: 0,
            width: drawerWidth,
            child: Material(
              elevation: 16,
              child: AppDrawer(
                onSelectTab: _onSelectTab,
                onLogout: widget.onLogout,
                onSwitchRole: widget.onSwitchToMerchant,
                onCloseDrawer: _toggleDrawer,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                activeColor: AppTheme.primaryTerracotta,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.list_alt_rounded,
                activeIcon: Icons.list_rounded,
                label: 'List',
                activeColor: AppTheme.mustardGold,
                isProminent: true,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.local_shipping_outlined,
                activeIcon: Icons.local_shipping_rounded,
                label: 'Orders',
                activeColor: AppTheme.mustardGold,
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.favorite_outline_rounded,
                activeIcon: Icons.favorite_rounded,
                label: 'Favorites',
                activeColor: AppTheme.primaryTerracotta,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color activeColor,
    bool isProminent = false,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onSelectTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 14,
          vertical: isSelected ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isSelected
                ? Row(
                    key: const ValueKey('row'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(activeIcon, color: Colors.white, size: 22),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Column(
                    key: const ValueKey('col'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: AppTheme.textSecondary, size: 22),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

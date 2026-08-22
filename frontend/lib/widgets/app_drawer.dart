import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../screens/mills_list_screen.dart';
import '../screens/saved_addresses_screen.dart';
import '../screens/payment_methods_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  final Function(int) onSelectTab;
  final VoidCallback onLogout;
  final bool isMerchantMode;
  final VoidCallback? onSwitchRole;
  final VoidCallback? onCloseDrawer;

  const AppDrawer({
    super.key,
    required this.onSelectTab,
    required this.onLogout,
    this.isMerchantMode = false,
    this.onSwitchRole,
    this.onCloseDrawer,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.background,
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 54, 20, 24),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceWarm,
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryTerracotta, width: 2),
                        image: DecorationImage(
                          image: NetworkImage(
                            isMerchantMode
                                ? 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=300&q=80'
                                : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=300&q=80',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isMerchantMode ? const Color(0xFF6E5616) : AppTheme.mustardGold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isMerchantMode ? 'Merchant Admin' : 'Gold Customer',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  isMerchantMode ? 'Artisan Mill Co.' : 'Sarah Jenkins',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  isMerchantMode ? 'merchant@artisanmill.com' : 'sarah.jenkins@example.com',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Role Switcher Tile Banner inside Drawer
          if (onSwitchRole != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: InkWell(
                onTap: () {
                  (onCloseDrawer != null ? onCloseDrawer!.call() : Navigator.pop(context));
                  onSwitchRole!();
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMerchantMode ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isMerchantMode ? Colors.orange[300]! : Colors.green[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isMerchantMode ? Icons.shopping_bag_outlined : Icons.storefront_rounded,
                        color: isMerchantMode ? Colors.deepOrange : Colors.green[800],
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMerchantMode ? 'Switch to Customer App' : 'Switch to Merchant Portal',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              isMerchantMode ? 'Order flour & track' : 'Manage orders & shop status',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 6),

          // Drawer Navigation List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildDrawerItem(
                  context,
                  icon: isMerchantMode ? Icons.grid_view_rounded : Icons.home_outlined,
                  title: isMerchantMode ? 'Merchant Dashboard' : 'Home / Shop',
                  onTap: () {
                    (onCloseDrawer != null ? onCloseDrawer!.call() : Navigator.pop(context));
                    onSelectTab(0);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: isMerchantMode ? Icons.receipt_long_rounded : Icons.add_circle_outline_rounded,
                  title: isMerchantMode ? 'Incoming Orders (12)' : 'Place New Order',
                  onTap: () {
                    (onCloseDrawer != null ? onCloseDrawer!.call() : Navigator.pop(context));
                    onSelectTab(1);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: isMerchantMode ? Icons.inventory_2_rounded : Icons.local_shipping_outlined,
                  title: isMerchantMode ? 'Manage Inventory' : 'Track Active Orders',
                  onTap: () {
                    (onCloseDrawer != null ? onCloseDrawer!.call() : Navigator.pop(context));
                    onSelectTab(2);
                  },
                ),
                if (!isMerchantMode)
                  _buildDrawerItem(
                    context,
                    icon: Icons.storefront_outlined,
                    title: 'Flour Mills Near You',
                    onTap: () {
                      (onCloseDrawer != null ? onCloseDrawer!.call() : Navigator.pop(context));
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MillsListScreen(
                            onStartOrder: () => onSelectTab(1),
                          ),
                        ),
                      );
                    },
                  ),
                const Divider(height: 24, color: AppTheme.borderLight),
                _buildDrawerItem(
                  context,
                  icon: Icons.person_outline_rounded,
                  title: isMerchantMode ? 'Store Profile' : 'My Profile',
                  onTap: () {
                    (onCloseDrawer != null ? onCloseDrawer!.call() : Navigator.pop(context));
                    onSelectTab(3);
                  },
                ),
                if (!isMerchantMode) ...[
                  _buildDrawerItem(
                    context,
                    icon: Icons.location_on_outlined,
                    title: 'Saved Addresses',
                    onTap: () {
                      (onCloseDrawer != null ? onCloseDrawer!.call() : Navigator.pop(context));
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SavedAddressesScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.payment_outlined,
                    title: 'Payment Methods',
                    onTap: () {
                      (onCloseDrawer != null ? onCloseDrawer!.call() : Navigator.pop(context));
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()),
                      );
                    },
                  ),
                ],
                _buildDrawerItem(
                  context,
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  onTap: () {
                    (onCloseDrawer != null ? onCloseDrawer!.call() : Navigator.pop(context));
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                    );
                  },
                ),
                const Divider(height: 24, color: AppTheme.borderLight),
                _buildDrawerItem(
                  context,
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  onTap: () {
                    (onCloseDrawer != null ? onCloseDrawer!.call() : Navigator.pop(context));
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    (onCloseDrawer != null ? onCloseDrawer!.call() : Navigator.pop(context));
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          // Logout Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  (onCloseDrawer != null ? onCloseDrawer!.call() : Navigator.pop(context));
                  onLogout();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryTerracotta,
                  side: const BorderSide(color: AppTheme.primaryTerracotta),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(
                  'Log Out',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      dense: true,
      horizontalTitleGap: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, color: AppTheme.primaryTerracotta, size: 22),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
    );
  }
}

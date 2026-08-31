import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_api_service.dart';
import '../services/customer_api_service.dart';
import 'saved_addresses_screen.dart';
import 'payment_methods_screen.dart';
import 'notifications_screen.dart';
import 'help_support_screen.dart';
import 'settings_screen.dart';
import 'orders_list_screen.dart';
import 'edit_profile_screen.dart';
import 'merchant_application_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  final Function(int)? onNavigateTab;
  final VoidCallback? onOpenDrawer;

  const ProfileScreen({
    super.key,
    this.onLogout,
    this.onNavigateTab,
    this.onOpenDrawer,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  int _activeOrdersCount = 0;
  int _completedOrdersCount = 0;
  String _addressSummary = 'Add delivery address';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final userFuture = AuthApiService.instance.getMe();
      final ordersFuture = CustomerApiService.instance.getCustomerOrders();
      final addressesFuture = CustomerApiService.instance.getAddresses();

      final results = await Future.wait([userFuture, ordersFuture, addressesFuture]);

      final fetchedUser = results[0] as Map<String, dynamic>?;
      final fetchedOrders = results[1] as List?;
      final fetchedAddresses = results[2] as List<Map<String, dynamic>>?;

      int active = 0;
      int completed = 0;
      if (fetchedOrders != null) {
        for (var o in fetchedOrders) {
          final status = o.status?.toString().toUpperCase() ?? '';
          if (status == 'DELIVERED' || status == 'COMPLETED' || status == 'CANCELLED') {
            completed++;
          } else {
            active++;
          }
        }
      }

      String addrText = '12 Market Yard, Ellisbridge, Ahmedabad';
      if (fetchedAddresses != null && fetchedAddresses.isNotEmpty) {
        final def = fetchedAddresses.firstWhere((a) => a['isDefault'] == true, orElse: () => fetchedAddresses.first);
        addrText = '${def['addressLine1'] ?? ''}, ${def['city'] ?? ''}'.trim();
      }

      if (mounted) {
        setState(() {
          _user = fetchedUser ?? AuthApiService.instance.currentUser;
          _activeOrdersCount = active > 0 ? active : 1;
          _completedOrdersCount = completed > 0 ? completed : 3;
          _addressSummary = addrText.isNotEmpty ? addrText : '12 Market Yard, Ellisbridge, Ahmedabad';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _user = AuthApiService.instance.currentUser;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final currentUser = _user ?? AuthApiService.instance.currentUser;
    final userName = currentUser?['name']?.toString() ?? 'Ramesh Patel';
    final userPhone = currentUser?['phone']?.toString() ?? '+919876543210';
    final userEmail = currentUser?['email']?.toString() ?? 'ramesh@example.com';
    final profileImg = currentUser?['profile_image']?.toString() ?? currentUser?['profileImage']?.toString();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : (widget.onOpenDrawer != null
                ? IconButton(
                    icon: const Icon(Icons.menu, color: AppTheme.textPrimary),
                    onPressed: widget.onOpenDrawer,
                  )
                : null),
        title: Text(
          'My Profile',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryTerracotta,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfileData,
          color: AppTheme.primaryTerracotta,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(color: AppTheme.primaryTerracotta, minHeight: 2),
                  ),

                // User Card Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppTheme.borderLight),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryTerracotta, width: 2),
                          image: DecorationImage(
                            image: NetworkImage(
                              (profileImg != null && profileImg.startsWith('http'))
                                  ? profileImg
                                  : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userPhone,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              userEmail,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryTerracotta),
                        onPressed: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(initialUser: currentUser),
                            ),
                          );
                          if (updated == true) {
                            _loadProfileData();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Account Settings Menu
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.shopping_bag_outlined,
                        title: 'My Orders History',
                        subtitle: '$_activeOrdersCount active orders • $_completedOrdersCount completed',
                        onTap: () {
                          if (widget.onNavigateTab != null) {
                            widget.onNavigateTab!(2);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const OrdersListScreen()),
                            );
                          }
                        },
                      ),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      _buildMenuItem(
                        icon: Icons.location_on_outlined,
                        title: 'Saved Delivery Addresses',
                        subtitle: _addressSummary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SavedAddressesScreen()),
                          ).then((_) => _loadProfileData());
                        },
                      ),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      _buildMenuItem(
                        icon: Icons.payment_outlined,
                        title: 'Payment Methods',
                        subtitle: 'UPI / NetBanking / Cash on Delivery',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      _buildMenuItem(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notification Preferences',
                        subtitle: 'Order tracking & delivery updates',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      _buildMenuItem(
                        icon: Icons.storefront_rounded,
                        title: 'Become a Shopkeeper / Mill Partner',
                        subtitle: 'Register your flour mill & start selling on HerDoor',
                        trailingBadge: 'Partner with Us',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MerchantApplicationScreen()),
                          ).then((_) => _loadProfileData());
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Support & General
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        subtitle: 'FAQs and Customer Service',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      _buildMenuItem(
                        icon: Icons.settings_outlined,
                        title: 'App Settings & Privacy',
                        subtitle: 'Language, notifications & storage',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (widget.onLogout != null) {
                        widget.onLogout!();
                      } else {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryTerracotta,
                      side: const BorderSide(color: AppTheme.primaryTerracotta, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(
                      'Log Out',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? trailingBadge,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceCream,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryTerracotta, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingBadge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9D9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trailingBadge,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6E5616),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}


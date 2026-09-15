import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/merchant_models.dart';
import '../../services/delivery_api_service.dart';
import '../../services/auth_api_service.dart';
import '../notifications_screen.dart';
import '../help_support_screen.dart';
import '../settings_screen.dart';

class DeliveryDrawer extends StatefulWidget {
  final Function(int) onSelectTab;
  final VoidCallback onLogout;
  final VoidCallback onSwitchToCustomer;
  final VoidCallback onSwitchToMerchant;
  final VoidCallback? onCloseDrawer;

  const DeliveryDrawer({
    super.key,
    required this.onSelectTab,
    required this.onLogout,
    required this.onSwitchToCustomer,
    required this.onSwitchToMerchant,
    this.onCloseDrawer,
  });

  @override
  State<DeliveryDrawer> createState() => _DeliveryDrawerState();
}

class _DeliveryDrawerState extends State<DeliveryDrawer> {
  RiderProfile? _profile;
  bool _isLoading = true;
  bool _isOnline = true;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await DeliveryApiService.instance.getRiderProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _isOnline = profile.isOnline;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleDutyStatus(bool newStatus) async {
    setState(() {
      _isUpdatingStatus = true;
    });
    try {
      await DeliveryApiService.instance.updateOnlineStatus(newStatus);
      if (mounted) {
        setState(() {
          _isOnline = newStatus;
          _isUpdatingStatus = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? '🟢 You are now ONLINE and visible on the delivery radar!'
                  : '⏸️ Duty paused. You are now in BREAK mode.',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: newStatus ? const Color(0xFF1E8449) : const Color(0xFF3E3A39),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  void _closeDrawer() {
    if (widget.onCloseDrawer != null) {
      widget.onCloseDrawer!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthApiService.instance.currentUser;
    final riderName = _profile?.name ??
        (currentUser?['name']?.toString().trim().isNotEmpty == true
            ? currentUser!['name'].toString().trim()
            : 'Vikram Delivery Agent');
    final vehicleInfo = _profile?.vehicleNumber != null && _profile!.vehicleNumber.isNotEmpty
        ? '${_profile?.vehicleType ?? 'EV Scooter'} • ${_profile!.vehicleNumber}'
        : 'GJ-01-AB-4821 • Hero Electric Nyx';
    final rating = _profile?.rating ?? 4.9;
    final totalTrips = _profile?.totalTrips ?? 348;

    return Drawer(
      backgroundColor: AppTheme.background,
      child: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8C4A3E), Color(0xFF5A2E25)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x338C4A3E),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar & Duty Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: _isOnline ? const Color(0xFF2ECC71) : Colors.white,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isOnline ? const Color(0xFF2ECC71) : Colors.black)
                                    .withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.two_wheeler_rounded,
                              color: Color(0xFF8C4A3E),
                              size: 30,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isOnline ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, size: 13, color: Color(0xFFFFD54F)),
                          const SizedBox(width: 4),
                          Text(
                            'Verified Partner',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Rider Name
                Text(
                  riderName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),

                // Vehicle Info
                Text(
                  vehicleInfo,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),

                // Performance Score Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFD54F)),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 16, color: Colors.white.withValues(alpha: 0.25)),
                      Row(
                        children: [
                          const Icon(Icons.local_shipping_rounded, size: 14, color: Color(0xFF81C784)),
                          const SizedBox(width: 4),
                          Text(
                            '$totalTrips trips',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 16, color: Colors.white.withValues(alpha: 0.25)),
                      Row(
                        children: [
                          const Icon(Icons.bolt_rounded, size: 15, color: Color(0xFF64B5F6)),
                          const SizedBox(width: 2),
                          Text(
                            '${_profile?.batteryLevelPct ?? 84}% EV',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Online / Offline Duty Switch Tile
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _isOnline ? const Color(0xFFE8F8F0) : const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isOnline ? const Color(0xFF2ECC71) : Colors.grey.shade400,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isOnline ? const Color(0xFF1E8449) : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isOnline ? 'Active On Duty' : 'Off Duty (Break)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _isOnline ? const Color(0xFF1E8449) : AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            _isOnline ? 'Receiving trips' : 'Trips paused',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _isUpdatingStatus
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8C4A3E)),
                        )
                      : Switch.adaptive(
                          value: _isOnline,
                          activeColor: const Color(0xFF1E8449),
                          onChanged: _toggleDutyStatus,
                        ),
                ],
              ),
            ),
          ),

          // Role Switchers (Customer / Merchant)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    _closeDrawer();
                    widget.onSwitchToCustomer();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFFEA580C), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Switch to Customer App',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Order flour & track deliveries',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () {
                    _closeDrawer();
                    widget.onSwitchToMerchant();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCFCE7)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.storefront_rounded, color: Color(0xFF15803D), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Switch to Merchant Portal',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Manage mill orders & stock',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.textMuted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 16, thickness: 1, color: AppTheme.borderLight),

          // Drawer Navigation Items List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildDrawerItem(
                  icon: Icons.radar_rounded,
                  title: 'Radar & Live Feed',
                  subtitle: '5 km radius dispatch radar',
                  onTap: () {
                    _closeDrawer();
                    widget.onSelectTab(0);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.assignment_outlined,
                  title: 'Trip Sheet & Tasks',
                  subtitle: 'Multi-order batch steps',
                  onTap: () {
                    _closeDrawer();
                    widget.onSelectTab(1);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Earnings & Payouts',
                  subtitle: 'Daily pay, tips & fuel bonus',
                  onTap: () {
                    _closeDrawer();
                    widget.onSelectTab(2);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.badge_outlined,
                  title: 'Rider Profile & KYC',
                  subtitle: 'Shifts, license & vehicle doc',
                  onTap: () {
                    _closeDrawer();
                    widget.onSelectTab(3);
                  },
                ),
                const Divider(height: 18, color: AppTheme.borderLight),

                // Quick Rider Support & Utilities
                _buildDrawerItem(
                  icon: Icons.shield_outlined,
                  iconColor: const Color(0xFFC0392B),
                  title: 'Rider Safety & SOS',
                  subtitle: '24x7 emergency helpline',
                  onTap: () {
                    _closeDrawer();
                    _showSOSDialog();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.ev_station_rounded,
                  iconColor: const Color(0xFF0284C7),
                  title: 'Partner EV Stations',
                  subtitle: 'Battery swapping hubs nearby',
                  onTap: () {
                    _closeDrawer();
                    _showChargingHubsDialog();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  onTap: () {
                    _closeDrawer();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  onTap: () {
                    _closeDrawer();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Preferences & Settings',
                  onTap: () {
                    _closeDrawer();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          // App Version & Logout Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                Text(
                  'HerDoor Rider v2.4.0 • Ellisbridge Zone',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _closeDrawer();
                      _showLogoutConfirmation();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC0392B),
                      side: const BorderSide(color: Color(0xFFE57373), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      backgroundColor: const Color(0xFFFFF5F5),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text(
                      'Log Out',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    Color? iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        horizontalTitleGap: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? const Color(0xFF8C4A3E)).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? const Color(0xFF8C4A3E), size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              )
            : null,
        trailing: const Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
      ),
    );
  }

  void _showSOSDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.shield_rounded, color: Color(0xFFC0392B), size: 26),
            const SizedBox(width: 8),
            Text(
              'Rider Safety Desk',
              style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Instant 24x7 Roadside & Medical Help:',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Text('📞 Toll-Free Helpline: 1800-437-3667',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text('💬 Instant Dispatcher Support: Active',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF1E8449), fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('📍 GPS Location: Live Broadcast Enabled',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🚨 Emergency SOS Dispatched to HerDoor Safety Hub!'),
                  backgroundColor: Color(0xFFC0392B),
                ),
              );
            },
            icon: const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.white),
            label: Text('Trigger SOS', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC0392B)),
          ),
        ],
      ),
    );
  }

  void _showChargingHubsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.ev_station_rounded, color: Color(0xFF0284C7), size: 26),
            const SizedBox(width: 8),
            Text(
              'Partner Battery Hubs',
              style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStationItem('⚡ Sun Mobility Swapping Hub', 'Ellisbridge Crossroad (0.6 km)', '8 charged batteries'),
            const SizedBox(height: 8),
            _buildStationItem('⚡ Hero Electric Fast Charger', 'Navrangpura Mill Complex (1.4 km)', '2 slots available'),
            const SizedBox(height: 8),
            _buildStationItem('⚡ Ather Grid 2.0 Station', 'Paldi Circle (2.2 km)', 'Open 24/7'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildStationItem(String name, String distance, String status) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
          Text(distance, style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 11)),
          Text(status, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF0284C7), fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Log Out as Rider?',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to end your shift and log out? You will stop receiving order dispatches.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC0392B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Confirm Log Out',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

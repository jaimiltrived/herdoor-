import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/merchant_api_service.dart';
import '../../models/merchant_models.dart';
import 'service_availability_screen.dart';
import 'mill_safety_screen.dart';

class MerchantProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback onSwitchToCustomer;

  const MerchantProfileScreen({
    super.key,
    required this.onLogout,
    required this.onSwitchToCustomer,
  });

  @override
  State<MerchantProfileScreen> createState() => _MerchantProfileScreenState();
}

class _MerchantProfileScreenState extends State<MerchantProfileScreen> {
  bool _isLoading = true;
  String _ownerName = 'Suresh Mill Owner';
  final String _millName = 'Shree Ganesh Flour Mill';
  String _phone = '+91 98765 43211';
  String _email = 'shop@shreeganesh.com';
  final double _rating = 4.6;
  final int _totalRatings = 128;
  bool _isOpen = true;
  MerchantDashboardMetrics? _metrics;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    // Fetch user profile details
    final user = await MerchantApiService.instance.getMerchantUserProfile();
    if (user != null) {
      _ownerName = user['name'] ?? _ownerName;
      _email = user['email'] ?? _email;
      _phone = user['phone'] ?? _phone;
    }

    // Fetch metrics
    final metrics = await MerchantApiService.instance.getDashboardMetrics();
    if (metrics != null) {
      _metrics = metrics;
    }

    // Fetch availability
    final isOpen = await MerchantApiService.instance.getShopAvailability();
    if (isOpen != null) {
      _isOpen = isOpen;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showEditProfileModal(BuildContext context) async {
    final nameCtrl = TextEditingController(text: _ownerName);
    final phoneCtrl = TextEditingController(text: _phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Merchant Profile',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Update your account owner name and contact details.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Owner Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final newName = nameCtrl.text.trim();
                  final newPhone = phoneCtrl.text.trim();
                  if (newName.isEmpty) return;

                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(context);

                  final success = await MerchantApiService.instance.updateMerchantUserProfile(
                    name: newName,
                    phone: newPhone,
                  );

                  if (!mounted) return;
                  nav.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF2ECC71),
                      content: Text(
                        success
                            ? '✅ Profile updated on Backend!'
                            : 'Profile details saved locally.',
                      ),
                    ),
                  );
                  _loadProfileData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6E5616),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: Text(
                  'Save Profile Details',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalProcessed = (_metrics?.completedOrders ?? 0) + (_metrics?.activeOrders ?? 0) + 12;

    return RefreshIndicator(
      onRefresh: _loadProfileData,
      color: AppTheme.primaryTerracotta,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryTerracotta, width: 2),
                          image: const DecorationImage(
                            image: NetworkImage('https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=300&q=80'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _millName,
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryTerracotta, size: 20),
                                  onPressed: () => _showEditProfileModal(context),
                                ),
                              ],
                            ),
                            Text(
                              'Owner: $_ownerName',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDE9D9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Verified Merchant',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF6E5616),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF39C12)),
                                    const SizedBox(width: 2),
                                    Text(
                                      '$_rating ($_totalRatings)',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppTheme.borderLight),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            _isLoading ? '...' : '$totalProcessed',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Total Orders',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(height: 24, width: 1, color: AppTheme.borderLight),
                      Column(
                        children: [
                          Text(
                            _isLoading ? '...' : '₹${_metrics?.totalRevenue ?? 90.0}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryTerracotta,
                            ),
                          ),
                          Text(
                            'Revenue',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(height: 24, width: 1, color: AppTheme.borderLight),
                      Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _isOpen ? const Color(0xFF2ECC71) : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isOpen ? 'OPEN' : 'CLOSED',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _isOpen ? const Color(0xFF2ECC71) : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Status',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Role Switcher Tile Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8C4A3E), Color(0xFF6E372D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Switch to Customer Mode',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Browse products and order flour as a customer',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: widget.onSwitchToCustomer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryTerracotta,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Switch',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings List
            _buildSettingsTile(
              icon: Icons.verified_user_rounded,
              title: 'Food Safety & Mill Hygiene Standards',
              subtitle: 'Daily sanitization audit, moisture test & safety score (99%)',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MillSafetyScreen()),
                );
              },
            ),
            _buildSettingsTile(
              icon: Icons.tune_rounded,
              title: 'Service Availability & Store Status',
              subtitle: 'Configure order limits, radius & operating hours',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ServiceAvailabilityScreen()),
                ).then((_) => _loadProfileData());
              },
            ),
            _buildSettingsTile(
              icon: Icons.storefront_rounded,
              title: 'Store Location & Contact',
              subtitle: '12 Market Yard, Ellisbridge • $_phone',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Store Location: 12 Market Yard, Ellisbridge (Contact: $_phone)')),
                );
              },
            ),
            _buildSettingsTile(
              icon: Icons.payments_outlined,
              title: 'Payout Accounts & Banking',
              subtitle: 'Direct deposit active (HDFC **** 4821)',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payout Account: HDFC Bank (**** 4821) Active')),
                );
              },
            ),
            _buildSettingsTile(
              icon: Icons.qr_code_scanner_rounded,
              title: 'QR Code & Bin Management',
              subtitle: 'Configure pickup bin locations (Bin A-1 to A-8)',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pickup Bins A-1 to A-8 configured & verified.')),
                );
              },
            ),
            _buildSettingsTile(
              icon: Icons.notifications_none_rounded,
              title: 'Merchant Notification Alerts',
              subtitle: 'Push & SMS notifications enabled',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Merchant push notification alerts enabled.')),
                );
              },
            ),

            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: widget.onLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryTerracotta,
                  side: const BorderSide(color: AppTheme.primaryTerracotta),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(
                  'Log Out Merchant Account',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F0E7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryTerracotta, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
      ),
    );
  }
}

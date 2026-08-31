import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/merchant_models.dart';
import '../../services/delivery_api_service.dart';

class DeliveryProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback onSwitchToCustomer;
  final VoidCallback onSwitchToMerchant;

  const DeliveryProfileScreen({
    super.key,
    required this.onLogout,
    required this.onSwitchToCustomer,
    required this.onSwitchToMerchant,
  });

  @override
  State<DeliveryProfileScreen> createState() => _DeliveryProfileScreenState();
}

class _DeliveryProfileScreenState extends State<DeliveryProfileScreen> {
  bool _isLoading = true;
  RiderProfile? _profile;
  List<RiderShiftSlot> _shifts = [];
  List<RiderLeaderboardEntry> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    final profile = await DeliveryApiService.instance.getRiderProfile();
    final shifts = await DeliveryApiService.instance.getShiftSlots();
    final leaderboard = await DeliveryApiService.instance.getLeaderboard();

    if (mounted) {
      setState(() {
        _profile = profile;
        _shifts = shifts;
        _leaderboard = leaderboard;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleShift(RiderShiftSlot shift) async {
    await DeliveryApiService.instance.toggleShiftBooking(shift.id);
    _loadProfileData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(shift.isBooked ? '❌ Shift booking cancelled' : '✅ Slot reserved for ${shift.title}!'),
        backgroundColor: shift.isBooked ? const Color(0xFF756D69) : const Color(0xFF1E8449),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Rider Hub & Profile',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryTerracotta,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryTerracotta))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rider Profile Card
                  _buildRiderHeroCard(),
                  const SizedBox(height: 18),

                  // Performance Scorecard
                  _buildPerformanceScorecard(),
                  const SizedBox(height: 18),

                  // Shift Reservation Hub (Guaranteed Min Pay)
                  _buildShiftBookingHub(),
                  const SizedBox(height: 18),

                  // City Rider Leaderboard
                  _buildLeaderboardSection(),
                  const SizedBox(height: 18),

                  // Vehicle & Digital Document Locker
                  _buildVehicleComplianceCard(),
                  const SizedBox(height: 18),

                  // Settings & Role Switcher
                  _buildAccountActionsCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildRiderHeroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8C4A3E), Color(0xFF5A2E25)],
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.two_wheeler_rounded, size: 34, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profile?.name ?? 'Vikram Delivery Agent',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rider ID: #HD-RD-4821 • Ahmedabad Central',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFF6AD55)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFB7791F)),
                              const SizedBox(width: 3),
                              Text(
                                '${_profile?.rating ?? 4.9} (348 ratings)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFB7791F),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F8F5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '🛡️ Verified Partner',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E8449),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Badges Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBadgeItem('⚡ Super Fast', 'Avg 16 mins'),
              _buildBadgeItem('🛡️ Zero Spill', '100% Bag Safe'),
              _buildBadgeItem('🏆 Top 2% Rider', 'Ahmedabad Zone'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(String title, String subtitle) {
    return Column(
      children: [
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildPerformanceScorecard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Partner Performance & Ratings',
            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetricBlock('98.4%', 'Order Acceptance', Icons.done_all_rounded, const Color(0xFF1E8449)),
              ),
              Expanded(
                child: _buildMetricBlock('99.1%', 'On-Time Handover', Icons.schedule_rounded, const Color(0xFF2980B9)),
              ),
              Expanded(
                child: _buildMetricBlock('0.0%', 'Cancellation Rate', Icons.cancel_outlined, const Color(0xFF16A085)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Text('Top Customer Compliments:', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildComplimentChip('🌾 Careful with Flour Bags (142)'),
              _buildComplimentChip('🤝 Super Polite & Courteous (189)'),
              _buildComplimentChip('🛵 Quick Delivery (210)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBlock(String val, String title, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(val, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textSecondary), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildComplimentChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3ECE1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6E5616))),
    );
  }

  Widget _buildShiftBookingHub() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_available_rounded, color: AppTheme.primaryTerracotta),
                  const SizedBox(width: 6),
                  Text(
                    'Shift Booking Hub',
                    style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                'Guaranteed Hourly Pay',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1E8449)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _shifts.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final s = _shifts[i];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: s.isBooked ? const Color(0xFFE8F8F5) : const Color(0xFFFBF9F6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: s.isBooked ? const Color(0xFF2ECC71) : AppTheme.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('${s.timing} • ${s.zone}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
                        const SizedBox(height: 2),
                        Text('Min ₹${s.guaranteedPay.toStringAsFixed(0)} Pay (${s.surgeMultiplier} Surge)', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1E8449))),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _toggleShift(s),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: s.isBooked ? const Color(0xFFC0392B) : const Color(0xFF1E8449),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        s.isBooked ? 'Cancel' : 'Book Slot',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.leaderboard_rounded, color: Color(0xFFB7791F)),
                  const SizedBox(width: 6),
                  Text(
                    'Ahmedabad Rider Leaderboard',
                    style: GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                'Weekly Rank #2',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFFB7791F)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _leaderboard.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final r = _leaderboard[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: r.isMe ? const Color(0xFFFFF8E7) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: r.isMe ? Border.all(color: const Color(0xFFF6AD55)) : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: r.rank == 1 ? const Color(0xFFF1C40F) : r.rank == 2 ? const Color(0xFFBDC3C7) : const Color(0xFFE67E22),
                      ),
                      child: Text('${r.rank}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${r.name} ${r.isMe ? '(You)' : ''}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('${r.totalTrips} trips • ${r.badge}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Text('₹${r.earnings.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 13, color: const Color(0xFF1E8449))),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleComplianceCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle & Digital Locker',
            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          _buildLockerRow('Vehicle Model', _profile?.vehicleType ?? 'Hero Electric Nyx Scooter', Icons.electric_scooter_outlined),
          _buildLockerRow('Registration No.', _profile?.vehicleNumber ?? 'GJ-01-AB-4821', Icons.pin_outlined),
          _buildLockerRow('Driving License', _profile?.drivingLicense ?? 'GJ-01-2022-009841 (Valid till 2032)', Icons.badge_outlined),
          _buildLockerRow('Commercial Insurance', 'HDFC ERGO • Valid till Oct 2027', Icons.health_and_safety_outlined),
          _buildLockerRow('EV Battery Health', '84% (48 km range) • Optimal Health', Icons.battery_charging_full_outlined),
        ],
      ),
    );
  }

  Widget _buildLockerRow(String title, String desc, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryTerracotta),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
                Text(desc, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              ],
            ),
          ),
          const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF1E8449)),
        ],
      ),
    );
  }

  Widget _buildAccountActionsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.swap_horiz_rounded, color: AppTheme.primaryTerracotta),
            title: Text('Switch to Customer Mode', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right_rounded, size: 18),
            onTap: widget.onSwitchToCustomer,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.storefront_outlined, color: AppTheme.primaryTerracotta),
            title: Text('Switch to Merchant Mode', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right_rounded, size: 18),
            onTap: widget.onSwitchToMerchant,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Color(0xFFC0392B)),
            title: Text('Logout Delivery Account', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFC0392B))),
            onTap: widget.onLogout,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/merchant_api_service.dart';

class ServiceAvailabilityScreen extends StatefulWidget {
  const ServiceAvailabilityScreen({super.key});

  @override
  State<ServiceAvailabilityScreen> createState() => _ServiceAvailabilityScreenState();
}

class _ServiceAvailabilityScreenState extends State<ServiceAvailabilityScreen> {
  int _storeStatusMode = 0; // 0: Accepting Orders, 1: High Demand, 2: Closed
  double _deliveryRadiusKm = 5.0;
  bool _expressDeliveryEnabled = true;
  bool _selfPickupEnabled = true;
  String _workingHours = '08:00 AM - 08:00 PM';
  List<String> _services = ['Flour Grinding', 'Packing', 'Home Delivery', 'Cleaning'];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() => _isLoading = true);
    final data = await MerchantApiService.instance.getShopAvailabilityDetails();
    if (data != null && mounted) {
      setState(() {
        if (data['statusMode'] != null) {
          _storeStatusMode = data['statusMode'] as int;
        } else if (data['isOpen'] != null) {
          _storeStatusMode = (data['isOpen'] as bool) ? 0 : 2;
        }
        if (data['deliveryRadiusKm'] != null) {
          _deliveryRadiusKm = (data['deliveryRadiusKm'] as num).toDouble();
        }
        if (data['expressDeliveryEnabled'] != null) {
          _expressDeliveryEnabled = data['expressDeliveryEnabled'] as bool;
        }
        if (data['selfPickupEnabled'] != null) {
          _selfPickupEnabled = data['selfPickupEnabled'] as bool;
        }
        if (data['workingHours'] != null) {
          _workingHours = data['workingHours'].toString();
        }
        if (data['services'] is List) {
          _services = (data['services'] as List).map((e) => e.toString()).toList();
        }
      });
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    final bool openState = _storeStatusMode == 0 || _storeStatusMode == 1;
    final success = await MerchantApiService.instance.updateShopAvailabilityDetails(
      isOpen: openState,
      statusMode: _storeStatusMode,
      deliveryRadiusKm: _deliveryRadiusKm,
      expressDeliveryEnabled: _expressDeliveryEnabled,
      selfPickupEnabled: _selfPickupEnabled,
      workingHours: _workingHours,
      services: _services,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: success ? const Color(0xFF2ECC71) : Colors.grey[800],
          behavior: SnackBarBehavior.floating,
          content: Text(
            success
                ? '✅ Store Availability & Settings Synced to Backend!'
                : 'Availability updated locally.',
          ),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Service Availability',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryTerracotta,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryTerracotta),
            onPressed: _loadAvailability,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryTerracotta))
            : RefreshIndicator(
                onRefresh: _loadAvailability,
                color: AppTheme.primaryTerracotta,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Store & Service Configuration',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Control store order limits, delivery range & operating hours in real-time.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Store Status Mode Switcher Card
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Store Operating Status',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _storeStatusMode == 0
                                  ? const Color(0xFFE8F8F0)
                                  : (_storeStatusMode == 1 ? const Color(0xFFFEF5E7) : const Color(0xFFFDEDEC)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _storeStatusMode == 0 ? 'OPEN' : (_storeStatusMode == 1 ? 'BUSY' : 'CLOSED'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _storeStatusMode == 0
                                    ? const Color(0xFF27AE60)
                                    : (_storeStatusMode == 1 ? const Color(0xFFF39C12) : const Color(0xFFE74C3C)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Column(
                          children: [
                            _buildStatusOption(
                              modeIndex: 0,
                              title: 'Accepting Orders',
                              subtitle: 'Store is open & processing customer orders in standard time.',
                              color: const Color(0xFF2ECC71),
                              icon: Icons.check_circle_rounded,
                            ),
                            const Divider(height: 20),
                            _buildStatusOption(
                              modeIndex: 1,
                              title: 'High Demand (Busy Mode)',
                              subtitle: 'Adds +20 mins buffer to order estimated completion times.',
                              color: const Color(0xFFF39C12),
                              icon: Icons.warning_rounded,
                            ),
                            const Divider(height: 20),
                            _buildStatusOption(
                              modeIndex: 2,
                              title: 'Shop Closed / Paused',
                              subtitle: 'Temporarily pause incoming new orders while performing cleaning.',
                              color: Colors.grey[600]!,
                              icon: Icons.pause_circle_rounded,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Delivery Radius Slider Card
                      Text(
                        'Delivery Coverage Radius',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Maximum Delivery Radius',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6E5616),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_deliveryRadiusKm.toStringAsFixed(1)} km',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Slider(
                              value: _deliveryRadiusKm,
                              min: 1.0,
                              max: 20.0,
                              divisions: 19,
                              activeColor: const Color(0xFF6E5616),
                              inactiveColor: const Color(0xFFE2DACF),
                              onChanged: (val) {
                                setState(() {
                                  _deliveryRadiusKm = val;
                                });
                              },
                            ),
                            Text(
                              'Orders outside ${_deliveryRadiusKm.toStringAsFixed(1)} km will be notified of unavailability.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Fulfilment Toggles
                      Text(
                        'Fulfilment Modes Enabled',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: Text(
                                  'Express Doorstep Delivery',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                subtitle: const Text('Partner delivery riders pick up and deliver to customer home'),
                                value: _expressDeliveryEnabled,
                                activeThumbColor: Colors.white,
                                activeTrackColor: AppTheme.primaryTerracotta,
                                onChanged: (val) => setState(() => _expressDeliveryEnabled = val),
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                title: Text(
                                  'Store Self-Pickup',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                subtitle: const Text('Customers pick up directly from store bins with OTP'),
                                value: _selfPickupEnabled,
                                activeThumbColor: Colors.white,
                                activeTrackColor: AppTheme.primaryTerracotta,
                                onChanged: (val) => setState(() => _selfPickupEnabled = val),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Operating Hours Notice
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F5EF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8DFC8)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.schedule_rounded, color: Color(0xFF6E5616), size: 24),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Standard Operating Hours',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _workingHours,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: const Color(0xFF6E5616),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6E5616),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  'Save Availability Settings',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatusOption({
    required int modeIndex,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _storeStatusMode == modeIndex;

    return GestureDetector(
      onTap: () => setState(() => _storeStatusMode = modeIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.transparent,
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryTerracotta : AppTheme.textMuted,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryTerracotta,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

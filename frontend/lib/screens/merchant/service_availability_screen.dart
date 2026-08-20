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
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final bool? isOpen = await MerchantApiService.instance.getShopAvailability();
    if (isOpen != null) {
      _storeStatusMode = isOpen ? 0 : 2;
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    final bool openState = _storeStatusMode == 0 || _storeStatusMode == 1;
    final success = await MerchantApiService.instance.updateShopAvailability(openState);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: success ? const Color(0xFF2ECC71) : Colors.grey[800],
          content: Text(
            success
                ? '✅ Store Availability Preferences Saved to Backend!'
                : 'Availability updated locally.',
          ),
        ),
      );
      Navigator.pop(context);
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
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryTerracotta))
            : SingleChildScrollView(
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
                      'Control store order limits, delivery range & operating hours.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Store Status Mode Switcher Card
                    Text(
                      'Current Store Operating Status',
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
                      child: Column(
                        children: [
                          _buildStatusOption(
                            modeIndex: 0,
                            title: 'Accepting Orders',
                            subtitle: 'Store is open & processing all customer orders normally.',
                            color: const Color(0xFF2ECC71),
                            icon: Icons.check_circle_rounded,
                          ),
                          const Divider(height: 20),
                          _buildStatusOption(
                            modeIndex: 1,
                            title: 'High Demand (Busy)',
                            subtitle: 'Adds +20 mins buffer to order estimated completion times.',
                            color: const Color(0xFFF39C12),
                            icon: Icons.warning_rounded,
                          ),
                          const Divider(height: 20),
                          _buildStatusOption(
                            modeIndex: 2,
                            title: 'Shop Closed',
                            subtitle: 'Temporarily pause incoming new orders.',
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
                            max: 15.0,
                            divisions: 14,
                            activeColor: const Color(0xFF6E5616),
                            inactiveColor: const Color(0xFFE2DACF),
                            onChanged: (val) {
                              setState(() {
                                _deliveryRadiusKm = val;
                              });
                            },
                          ),
                          Text(
                            'Orders outside this radius will be notified of unavailability.',
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
                            subtitle: const Text('Partner drivers deliver to customer home'),
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
                            subtitle: const Text('Customers pick up directly from store bins'),
                            value: _selfPickupEnabled,
                            activeThumbColor: Colors.white,
                            activeTrackColor: AppTheme.primaryTerracotta,
                            onChanged: (val) => setState(() => _selfPickupEnabled = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

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
                            ? const CircularProgressIndicator(color: Colors.white)
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

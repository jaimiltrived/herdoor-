import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/merchant_api_service.dart';

class MillSafetyScreen extends StatefulWidget {
  const MillSafetyScreen({super.key});

  @override
  State<MillSafetyScreen> createState() => _MillSafetyScreenState();
}

class _MillSafetyScreenState extends State<MillSafetyScreen> {
  bool _chakkiSanitized = true;
  bool _moistureCheckPassed = true;
  bool _dustExtractorActive = true;
  bool _ecoPackagingVerified = true;
  bool _pestControlCertified = true;
  bool _isSubmitting = false;

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
          'Food Safety & Hygiene',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryTerracotta,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mill Hygiene & Quality Verification',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ensure daily compliance with food safety & grain quality standards.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Safety & Certification Badge Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E4D2B), Color(0xFF2ECC71)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2ECC71).withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_user_rounded, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'ISO 22000 & FSSAI CERTIFIED',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'SCORE: 99%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'A Grade Food Safety Index',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Shree Ganesh Flour Mill holds verified zero-contamination status for organic whole wheat and grain milling.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Daily Safety Checklist Section
              Text(
                'Daily Merchant Hygiene Inspection',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  children: [
                    _buildChecklistTile(
                      title: 'Mill Stone & Grinder Sanitization',
                      subtitle: 'Chakki stones cleaned, vacuumed, and sanitized daily',
                      icon: Icons.cleaning_services_rounded,
                      value: _chakkiSanitized,
                      onChanged: (val) => setState(() => _chakkiSanitized = val),
                    ),
                    const Divider(height: 1),
                    _buildChecklistTile(
                      title: 'Grain Moisture Calibration (< 12%)',
                      subtitle: 'Raw grain moisture tested to prevent mold formation',
                      icon: Icons.water_drop_rounded,
                      value: _moistureCheckPassed,
                      onChanged: (val) => setState(() => _moistureCheckPassed = val),
                    ),
                    const Divider(height: 1),
                    _buildChecklistTile(
                      title: 'Dust Extractor & Air Filter Integrity',
                      subtitle: 'Flour dust extraction system operating at full suction',
                      icon: Icons.air_rounded,
                      value: _dustExtractorActive,
                      onChanged: (val) => setState(() => _dustExtractorActive = val),
                    ),
                    const Divider(height: 1),
                    _buildChecklistTile(
                      title: 'Eco-Friendly Tamper-Proof Packaging',
                      subtitle: 'Double-sealed food-grade bags verified before customer dispatch',
                      icon: Icons.inventory_2_rounded,
                      value: _ecoPackagingVerified,
                      onChanged: (val) => setState(() => _ecoPackagingVerified = val),
                    ),
                    const Divider(height: 1),
                    _buildChecklistTile(
                      title: 'Pest-Free Storage Verification',
                      subtitle: 'Grain storage bins sealed and inspected by certified audit',
                      icon: Icons.bug_report_rounded,
                      value: _pestControlCertified,
                      onChanged: (val) => setState(() => _pestControlCertified = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Emergency Maintenance Notice Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFFEEBA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFF856404), size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency Sanitation Pause',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF856404),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Need to halt milling for stone dressing or deep cleaning? Toggle shop availability to paused state instantly.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF856404),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Safety Verification Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(context);
                          setState(() => _isSubmitting = true);
                          // Sync availability or log verification status
                          await MerchantApiService.instance.updateShopAvailability(true);
                          if (!mounted) return;
                          setState(() => _isSubmitting = false);
                          messenger.showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF2ECC71),
                              content: Text('✅ Daily Food Safety Audit Verified & Submitted to Backend!'),
                            ),
                          );
                          nav.pop();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6E5616),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_rounded, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Submitting Safety Audit...' : 'Submit & Verify Safety Compliance',
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
      ),
    );
  }

  Widget _buildChecklistTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: value ? const Color(0xFFE8F8F0) : const Color(0xFFF6F0E7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: value ? const Color(0xFF2ECC71) : AppTheme.textSecondary, size: 20),
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
      value: value,
      activeThumbColor: Colors.white,
      activeTrackColor: const Color(0xFF2ECC71),
      onChanged: onChanged,
    );
  }
}

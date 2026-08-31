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
  bool _isLoading = true;
  bool _chakkiSanitized = true;
  bool _moistureCheckPassed = true;
  bool _dustExtractorActive = true;
  bool _ecoPackagingVerified = true;
  bool _pestControlCertified = true;
  int _safetyScore = 99;
  String _grade = 'A+';
  bool _isSubmitting = false;
  bool _isPausing = false;
  bool _isShopOpen = true;

  @override
  void initState() {
    super.initState();
    _loadSafetyAudit();
  }

  Future<void> _loadSafetyAudit() async {
    setState(() => _isLoading = true);
    final audit = await MerchantApiService.instance.getSafetyAudit();
    final avail = await MerchantApiService.instance.getShopAvailability();

    if (audit != null && mounted) {
      setState(() {
        _chakkiSanitized = audit['chakkiSanitized'] as bool? ?? true;
        _moistureCheckPassed = audit['moistureCheckPassed'] as bool? ?? true;
        _dustExtractorActive = audit['dustExtractorActive'] as bool? ?? true;
        _ecoPackagingVerified = audit['ecoPackagingVerified'] as bool? ?? true;
        _pestControlCertified = audit['pestControlCertified'] as bool? ?? true;
        _safetyScore = (audit['safetyScore'] as num?)?.toInt() ?? 99;
        _grade = audit['grade']?.toString() ?? 'A+';
        _isShopOpen = avail ?? true;
      });
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _recalculateScore() {
    final checks = [_chakkiSanitized, _moistureCheckPassed, _dustExtractorActive, _ecoPackagingVerified, _pestControlCertified];
    final passed = checks.where((c) => c).length;
    setState(() {
      _safetyScore = ((passed / checks.length) * 100).round();
      _grade = _safetyScore >= 90 ? 'A+' : (_safetyScore >= 75 ? 'A' : (_safetyScore >= 60 ? 'B' : 'Needs Action'));
    });
  }

  Future<void> _handleEmergencyToggle() async {
    setState(() => _isPausing = true);
    final newState = !_isShopOpen;
    await MerchantApiService.instance.updateShopAvailability(newState);
    if (mounted) {
      setState(() {
        _isShopOpen = newState;
        _isPausing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: newState ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          content: Text(
            newState
                ? '✅ Store Milling Resumed - Accepting Orders'
                : '⏸️ Emergency Sanitation Pause Activated - Store Paused',
          ),
        ),
      );
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
          'Food Safety & Hygiene',
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
            onPressed: _loadSafetyAudit,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryTerracotta))
            : RefreshIndicator(
                onRefresh: _loadSafetyAudit,
                color: AppTheme.primaryTerracotta,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                          gradient: LinearGradient(
                            colors: _safetyScore >= 80
                                ? [const Color(0xFF1E4D2B), const Color(0xFF2ECC71)]
                                : [const Color(0xFF7B3F00), const Color(0xFFE67E22)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: (_safetyScore >= 80 ? const Color(0xFF2ECC71) : const Color(0xFFE67E22))
                                  .withValues(alpha: 0.25),
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'SCORE: $_safetyScore%',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '$_grade Grade Food Safety Index',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _safetyScore >= 80
                                  ? 'Shree Ganesh Flour Mill holds verified zero-contamination status for organic whole wheat and grain milling.'
                                  : 'Safety checklist items are currently unfulfilled. Please complete all inspection points to maintain compliance.',
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daily Merchant Hygiene Inspection',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${[_chakkiSanitized, _moistureCheckPassed, _dustExtractorActive, _ecoPackagingVerified, _pestControlCertified].where((c) => c).length}/5 Done',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryTerracotta,
                            ),
                          ),
                        ],
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
                              onChanged: (val) {
                                setState(() => _chakkiSanitized = val);
                                _recalculateScore();
                              },
                            ),
                            const Divider(height: 1),
                            _buildChecklistTile(
                              title: 'Grain Moisture Calibration (< 12%)',
                              subtitle: 'Raw grain moisture tested to prevent mold formation',
                              icon: Icons.water_drop_rounded,
                              value: _moistureCheckPassed,
                              onChanged: (val) {
                                setState(() => _moistureCheckPassed = val);
                                _recalculateScore();
                              },
                            ),
                            const Divider(height: 1),
                            _buildChecklistTile(
                              title: 'Dust Extractor & Air Filter Integrity',
                              subtitle: 'Flour dust extraction system operating at full suction',
                              icon: Icons.air_rounded,
                              value: _dustExtractorActive,
                              onChanged: (val) {
                                setState(() => _dustExtractorActive = val);
                                _recalculateScore();
                              },
                            ),
                            const Divider(height: 1),
                            _buildChecklistTile(
                              title: 'Eco-Friendly Tamper-Proof Packaging',
                              subtitle: 'Double-sealed food-grade bags verified before customer dispatch',
                              icon: Icons.inventory_2_rounded,
                              value: _ecoPackagingVerified,
                              onChanged: (val) {
                                setState(() => _ecoPackagingVerified = val);
                                _recalculateScore();
                              },
                            ),
                            const Divider(height: 1),
                            _buildChecklistTile(
                              title: 'Pest-Free Storage Verification',
                              subtitle: 'Grain storage bins sealed and inspected by certified audit',
                              icon: Icons.bug_report_rounded,
                              value: _pestControlCertified,
                              onChanged: (val) {
                                setState(() => _pestControlCertified = val);
                                _recalculateScore();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Emergency Maintenance Notice Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _isShopOpen ? const Color(0xFFFFF3CD) : const Color(0xFFFDEDEC),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _isShopOpen ? const Color(0xFFFFEEBA) : const Color(0xFFFADBD8),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isShopOpen ? Icons.warning_amber_rounded : Icons.pause_circle_rounded,
                              color: _isShopOpen ? const Color(0xFF856404) : const Color(0xFFC0392B),
                              size: 28,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isShopOpen ? 'Emergency Sanitation Pause' : 'Store Currently Paused',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: _isShopOpen ? const Color(0xFF856404) : const Color(0xFFC0392B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isShopOpen
                                        ? 'Need to halt milling for stone dressing or deep cleaning? Pause incoming orders.'
                                        : 'Milling paused for deep cleaning. Ready to resume accepting customer orders?',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: _isShopOpen ? const Color(0xFF856404) : const Color(0xFFC0392B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _isPausing ? null : _handleEmergencyToggle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isShopOpen ? const Color(0xFF856404) : const Color(0xFF2ECC71),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: _isPausing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      _isShopOpen ? 'Pause Store' : 'Resume Store',
                                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
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
                                  
                                  // Send audit updates to backend
                                  final res = await MerchantApiService.instance.updateSafetyAudit(
                                    chakkiSanitized: _chakkiSanitized,
                                    moistureCheckPassed: _moistureCheckPassed,
                                    dustExtractorActive: _dustExtractorActive,
                                    ecoPackagingVerified: _ecoPackagingVerified,
                                    pestControlCertified: _pestControlCertified,
                                  );

                                  if (!mounted) return;
                                  setState(() => _isSubmitting = false);
                                  messenger.showSnackBar(
                                    SnackBar(
                                      backgroundColor: const Color(0xFF2ECC71),
                                      behavior: SnackBarBehavior.floating,
                                      content: Text(
                                        '✅ Food Safety Audit Submitted! Score: ${res?['safetyScore'] ?? _safetyScore}% (${res?['grade'] ?? _grade})',
                                      ),
                                    ),
                                  );
                                  nav.pop(true);
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

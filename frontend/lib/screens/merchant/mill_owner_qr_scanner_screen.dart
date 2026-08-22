import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/merchant_models.dart';

class MillOwnerQrScannerScreen extends StatefulWidget {
  final MerchantOrder order;

  const MillOwnerQrScannerScreen({
    super.key,
    required this.order,
  });

  @override
  State<MillOwnerQrScannerScreen> createState() => _MillOwnerQrScannerScreenState();
}

class _MillOwnerQrScannerScreenState extends State<MillOwnerQrScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isTorchOn = false;
  bool _isScanned = false;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Simulate auto-scan detection after 2.5 seconds
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted && !_isScanned) {
        _handleScanSuccess();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleScanSuccess() {
    setState(() {
      _isScanned = true;
      _isScanning = false;
    });
  }

  void _handleConfirmMoveToMill() {
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanBoxSize = size.width * 0.72;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Simulated Camera Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    Color(0xFF2C2520),
                    Color(0xFF141210),
                    Colors.black,
                  ],
                ),
              ),
              child: Center(
                child: Opacity(
                  opacity: 0.25,
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    size: scanBoxSize * 0.9,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // Scanner Reticle & Viewfinder Cutout
          SafeArea(
            child: Column(
              children: [
                // Top Navigation & Actions Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context, false),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            'Mill Intake Scanner',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Align Grain Bag QR Code',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() => _isTorchOn = !_isTorchOn);
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isTorchOn ? const Color(0xFFCBA034) : Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: Icon(
                                _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Center Viewfinder Box
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Border Box
                      Container(
                        width: scanBoxSize,
                        height: scanBoxSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _isScanned
                                ? const Color(0xFF2ECC71)
                                : const Color(0xFFCBA034),
                            width: 2.5,
                          ),
                        ),
                      ),

                      // 4 Corner Markers
                      Positioned(
                        top: 0,
                        left: 0,
                        child: _buildCorner(isTop: true, isLeft: true),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _buildCorner(isTop: true, isLeft: false),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: _buildCorner(isTop: false, isLeft: true),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: _buildCorner(isTop: false, isLeft: false),
                      ),

                      // Animated Laser Scan Line
                      if (_isScanning)
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Positioned(
                              top: 20 + (_animation.value * (scanBoxSize - 40)),
                              left: 16,
                              right: 16,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Color(0xFFFFB3AC),
                                      AppTheme.primaryTerracotta,
                                      Color(0xFFFFB3AC),
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryTerracotta.withValues(alpha: 0.8),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                      // Scanned Success Badge Icon
                      if (_isScanned)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2ECC71),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF2ECC71),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Manual Scan Trigger Button if not yet scanned
                if (!_isScanned)
                  TextButton.icon(
                    onPressed: _handleScanSuccess,
                    icon: const Icon(Icons.touch_app_rounded, color: Color(0xFFCBA034), size: 18),
                    label: Text(
                      'Simulate Instant QR Scan',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFFE8C86A),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),

                const Spacer(),

                // Bottom Scanned Details Sheet
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: _isScanned ? const Color(0xFFE8F8F0) : const Color(0xFFFBF4ED),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isScanned ? Icons.verified_rounded : Icons.inventory_2_outlined,
                                  color: _isScanned ? const Color(0xFF2ECC71) : AppTheme.primaryTerracotta,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.order.orderId,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryTerracotta,
                                    ),
                                  ),
                                  Text(
                                    widget.order.customerName,
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isScanned ? const Color(0xFFE8F8F0) : const Color(0xFFFFF8E7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isScanned ? const Color(0xFFA2E4D4) : const Color(0xFFFFE082),
                              ),
                            ),
                            child: Text(
                              _isScanned ? 'QR VERIFIED' : 'SCANNING...',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _isScanned ? const Color(0xFF1E8449) : const Color(0xFFD35400),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      const SizedBox(height: 14),

                      // Grain & Quantity Details
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Grain Type',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                                Text(
                                  widget.order.grainType,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quantity',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                                Text(
                                  widget.order.quantityText,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Est. Milling',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                                Text(
                                  widget.order.estimatedCompletionTime ?? '30 Mins',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF6E5616)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Action Button: Move into Mill
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: !_isScanned ? null : _handleConfirmMoveToMill,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6E5616),
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.precision_manufacturing_rounded, color: Colors.white, size: 20),
                          label: Text(
                            !_isScanned ? 'Align QR to Verify' : 'Confirm & Move into Mill',
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({required bool isTop, required bool isLeft}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? BorderSide(color: _isScanned ? const Color(0xFF2ECC71) : const Color(0xFFCBA034), width: 5)
              : BorderSide.none,
          bottom: !isTop
              ? BorderSide(color: _isScanned ? const Color(0xFF2ECC71) : const Color(0xFFCBA034), width: 5)
              : BorderSide.none,
          left: isLeft
              ? BorderSide(color: _isScanned ? const Color(0xFF2ECC71) : const Color(0xFFCBA034), width: 5)
              : BorderSide.none,
          right: !isLeft
              ? BorderSide(color: _isScanned ? const Color(0xFF2ECC71) : const Color(0xFFCBA034), width: 5)
              : BorderSide.none,
        ),
      ),
    );
  }
}

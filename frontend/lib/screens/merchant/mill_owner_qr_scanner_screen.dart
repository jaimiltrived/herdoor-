import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/merchant_models.dart';
import '../../services/merchant_api_service.dart';
import 'merchant_active_driver_pickup_screen.dart';

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
  late List<ProductBagItem> _productBags;
  final Set<String> _scannedBagIds = {};
  int _selectedBagIndex = 0;

  bool get _isAllScanned => _productBags.isNotEmpty && _scannedBagIds.length >= _productBags.length;
  ProductBagItem get _currentBag => _productBags[_selectedBagIndex.clamp(0, _productBags.length - 1)];

  @override
  void initState() {
    super.initState();
    _productBags = widget.order.productBags;

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Auto scan first bag after 2.5s for seamless simulation
    Timer(const Duration(milliseconds: 2200), () {
      if (mounted && _scannedBagIds.isEmpty && _productBags.isNotEmpty) {
        _scanBag(_productBags.first);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _scanBag(ProductBagItem bag) {
    setState(() {
      _scannedBagIds.add(bag.bagId);
      if (!_isAllScanned && _selectedBagIndex < _productBags.length - 1) {
        _selectedBagIndex++;
      }
    });
  }

  void _scanAllBags() {
    setState(() {
      for (final b in _productBags) {
        _scannedBagIds.add(b.bagId);
      }
    });
  }

  Future<void> _handleConfirmMoveToMill() async {
    final orderId = widget.order.numericId ?? 501;
    widget.order.statusTag = 'READY FOR PICKUP';
    widget.order.statusColor = const Color(0xFFFF8A80);

    // Update backend order status to READY / READY_FOR_PICKUP
    await MerchantApiService.instance.transitionOrderStatus(orderId, 'ready');

    if (!mounted) return;

    // Immediately redirect to Live Delivery Handover Screen showing all ready orders
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MerchantActiveDriverPickupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanBoxSize = size.width * 0.72;
    final currentBagScanned = _scannedBagIds.contains(_currentBag.bagId);

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
                            _productBags.length > 1
                                ? 'Unit ${_selectedBagIndex + 1} of ${_productBags.length}: ${_currentBag.bagId}'
                                : 'Align Grain Bag QR: ${_currentBag.bagId}',
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

                // Multi-Product Unit Bag Tabs if order has multiple products
                if (_productBags.length > 1) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _productBags.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final bag = entry.value;
                          final isSelected = _selectedBagIndex == idx;
                          final isScanned = _scannedBagIds.contains(bag.bagId);

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => setState(() => _selectedBagIndex = idx),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isScanned ? const Color(0xFF1E8449) : const Color(0xFFCBA034))
                                      : (isScanned ? const Color(0xFF145A32) : Colors.white.withValues(alpha: 0.15)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? Colors.white : Colors.white24,
                                    width: isSelected ? 1.8 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isScanned ? Icons.check_circle_rounded : Icons.crop_free_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${idx + 1}. ${bag.productName} (${bag.quantityKg}kg)',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],

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
                            color: currentBagScanned
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
                        child: _buildCorner(isTop: true, isLeft: true, isScanned: currentBagScanned),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _buildCorner(isTop: true, isLeft: false, isScanned: currentBagScanned),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: _buildCorner(isTop: false, isLeft: true, isScanned: currentBagScanned),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: _buildCorner(isTop: false, isLeft: false, isScanned: currentBagScanned),
                      ),

                      // Animated Laser Scan Line
                      if (!currentBagScanned)
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
                      if (currentBagScanned)
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

                const SizedBox(height: 12),

                // Manual Scan Trigger Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!currentBagScanned)
                      TextButton.icon(
                        onPressed: () => _scanBag(_currentBag),
                        icon: const Icon(Icons.touch_app_rounded, color: Color(0xFFCBA034), size: 18),
                        label: Text(
                          'Scan Unit ${_selectedBagIndex + 1} (${_currentBag.productName})',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFE8C86A),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    if (!_isAllScanned && _productBags.length > 1) ...[
                      const SizedBox(width: 10),
                      TextButton.icon(
                        onPressed: _scanAllBags,
                        icon: const Icon(Icons.done_all_rounded, color: Color(0xFF2ECC71), size: 18),
                        label: Text(
                          'Scan All Units (${_productBags.length} Bags)',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF2ECC71),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
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
                                  color: currentBagScanned ? const Color(0xFFE8F8F0) : const Color(0xFFFBF4ED),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  currentBagScanned ? Icons.verified_rounded : Icons.inventory_2_outlined,
                                  color: currentBagScanned ? const Color(0xFF2ECC71) : AppTheme.primaryTerracotta,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.order.orderId} • ${_currentBag.bagId}',
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
                              color: currentBagScanned ? const Color(0xFFE8F8F0) : const Color(0xFFFFF8E7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: currentBagScanned ? const Color(0xFFA2E4D4) : const Color(0xFFFFE082),
                              ),
                            ),
                            child: Text(
                              currentBagScanned ? 'UNIT VERIFIED' : 'SCANNING...',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: currentBagScanned ? const Color(0xFF1E8449) : const Color(0xFFD35400),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      const SizedBox(height: 12),

                      // Unit Breakdown Summary
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Product Unit',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                                Text(
                                  _currentBag.productName,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Unit Weight',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                                Text(
                                  '${_currentBag.quantityKg} kg',
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
                                  'Total Units',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                                Text(
                                  '${_scannedBagIds.length}/${_productBags.length} Verified',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _isAllScanned ? const Color(0xFF1E8449) : const Color(0xFF6E5616),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Action Button: Move into Mill
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: !_isAllScanned ? null : _handleConfirmMoveToMill,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6E5616),
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.handshake_outlined, color: Colors.white, size: 20),
                          label: Text(
                            !_isAllScanned
                                ? 'Verify All Units (${_scannedBagIds.length}/${_productBags.length})'
                                : 'Confirm & Proceed to Handover (${_productBags.length} Bags)',
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

  Widget _buildCorner({required bool isTop, required bool isLeft, required bool isScanned}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? BorderSide(color: isScanned ? const Color(0xFF2ECC71) : const Color(0xFFCBA034), width: 5)
              : BorderSide.none,
          bottom: !isTop
              ? BorderSide(color: isScanned ? const Color(0xFF2ECC71) : const Color(0xFFCBA034), width: 5)
              : BorderSide.none,
          left: isLeft
              ? BorderSide(color: isScanned ? const Color(0xFF2ECC71) : const Color(0xFFCBA034), width: 5)
              : BorderSide.none,
          right: !isLeft
              ? BorderSide(color: isScanned ? const Color(0xFF2ECC71) : const Color(0xFFCBA034), width: 5)
              : BorderSide.none,
        ),
      ),
    );
  }
}

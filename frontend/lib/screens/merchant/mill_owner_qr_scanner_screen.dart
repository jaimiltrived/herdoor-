import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/merchant_models.dart';
import '../../services/merchant_api_service.dart';

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
  final Map<String, bool> _bagAcceptanceMap = {}; // bagId -> true (Accepted) / false (Rejected)
  final Map<String, String> _bagRejectionReasonMap = {}; // bagId -> reason
  int _selectedBagIndex = 0;
  bool _isProcessing = false;

  // Quality check states for current bag
  bool _isMoistureDry = true;
  bool _isCleanPestFree = true;
  bool _isPackagingIntact = true;
  bool _isWeightAccurate = true;

  bool get _isAllScanned => _productBags.isNotEmpty && _scannedBagIds.length >= _productBags.length;
  ProductBagItem get _currentBag => _productBags[_selectedBagIndex.clamp(0, _productBags.length - 1)];
  int get _rejectedCount => _bagAcceptanceMap.values.where((v) => v == false).length;

  @override
  void initState() {
    super.initState();
    _productBags = List.from(widget.order.productBags);

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Auto scan first bag after 1.8s for smooth interaction
    Timer(const Duration(milliseconds: 1800), () {
      if (mounted && _scannedBagIds.isEmpty && _productBags.isNotEmpty) {
        _scanBag(_productBags.first, autoAccept: true);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _scanBag(ProductBagItem bag, {bool autoAccept = true}) {
    setState(() {
      _scannedBagIds.add(bag.bagId);
      if (autoAccept && !_bagAcceptanceMap.containsKey(bag.bagId)) {
        _bagAcceptanceMap[bag.bagId] = true;
      }
      if (!_isAllScanned && _selectedBagIndex < _productBags.length - 1) {
        _selectedBagIndex++;
      }
    });
  }

  void _scanAllBags({bool acceptAll = true}) {
    setState(() {
      for (final b in _productBags) {
        _scannedBagIds.add(b.bagId);
        if (acceptAll) {
          _bagAcceptanceMap[b.bagId] = true;
        }
      }
    });
  }

  void _openBagRejectionModal(ProductBagItem bag) {
    String selectedReason = '🌾 Contaminated Grain / Insects';
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                          child: Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reject Bag ${bag.bagId}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            Text(
                              '${bag.productName} • ${bag.unitText}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppTheme.borderLight),
                const SizedBox(height: 14),
                Text('Select Rejection Reason *', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    '🌾 Contaminated Grain / Insects',
                    '💧 Wet Grain / High Moisture',
                    '📦 Torn / Damaged Packaging',
                    '⚖️ Underweight Discrepancy',
                    '🚫 Wrong Grain Variety',
                    '📝 Quality Standards Mismatch',
                  ].map((r) {
                    final isSel = selectedReason == r;
                    return ChoiceChip(
                      label: Text(r),
                      selected: isSel,
                      selectedColor: const Color(0xFFFFECEB),
                      backgroundColor: const Color(0xFFF6F0E7),
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        color: isSel ? Colors.red.shade700 : AppTheme.textPrimary,
                      ),
                      side: BorderSide(color: isSel ? Colors.red.shade400 : AppTheme.borderLight),
                      onSelected: (val) {
                        if (val) setModalState(() => selectedReason = r);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Additional Inspection Notes (Optional)', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'e.g. Moisture barrier broken, insects found near top seam...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade500),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: const Color(0xFFFCFAF7),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _scannedBagIds.add(bag.bagId);
                        _bagAcceptanceMap[bag.bagId] = false;
                        _bagRejectionReasonMap[bag.bagId] = selectedReason;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.red.shade800,
                          content: Text('❌ Bag ${bag.bagId} marked as REJECTED: $selectedReason'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.cancel_rounded, color: Colors.white),
                    label: Text('Confirm Bag Rejection', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleConfirmAcceptance() async {
    final orderId = widget.order.numericId ?? 501;
    setState(() => _isProcessing = true);

    final bagDecisions = _productBags.map((b) {
      final isAcc = _bagAcceptanceMap[b.bagId] ?? true;
      return {
        'bagId': b.bagId,
        'productName': b.productName,
        'isAccepted': isAcc,
        'rejectionReason': isAcc ? null : _bagRejectionReasonMap[b.bagId],
      };
    }).toList();

    final res = await MerchantApiService.instance.submitGrainIntakeInspection(
      orderId,
      isAccepted: true,
      notes: 'All bags scanned and verified clean at intake.',
      bagDecisions: bagDecisions,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    widget.order.statusTag = 'IN PROGRESS';
    widget.order.statusColor = const Color(0xFFCBA034);
    widget.order.intakeStatus = 'ACCEPTED';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E8449),
        content: Text(res['message'] ?? '✅ Grain intake scanned & accepted! Ready for Milling.'),
      ),
    );

    Navigator.pop(context, true);
  }

  Future<void> _handleConfirmRejectionAndReturn() async {
    final orderId = widget.order.numericId ?? 501;
    final primaryReason = _bagRejectionReasonMap.values.isNotEmpty
        ? _bagRejectionReasonMap.values.first
        : 'Quality discrepancy at mill intake';

    setState(() => _isProcessing = true);

    final bagDecisions = _productBags.map((b) {
      final isAcc = _bagAcceptanceMap[b.bagId] ?? false;
      return {
        'bagId': b.bagId,
        'productName': b.productName,
        'isAccepted': isAcc,
        'rejectionReason': isAcc ? null : (_bagRejectionReasonMap[b.bagId] ?? primaryReason),
      };
    }).toList();

    await MerchantApiService.instance.submitGrainIntakeInspection(
      orderId,
      isAccepted: false,
      reason: primaryReason,
      notes: 'Grain rejected during intake scan. Driver return leg dispatched.',
      bagDecisions: bagDecisions,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    widget.order.statusTag = 'REJECTED';
    widget.order.statusColor = Colors.red.shade700;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.assignment_return_rounded, color: Colors.red.shade700, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Grain Rejected • Return Dispatched',
              style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'The grain bags have been rejected ($primaryReason).\n\nThe delivery partner at the mill has been notified to return the bags directly to ${widget.order.customerName}\'s doorstep.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF9F5EF), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFF6E5616)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Customer and dispatch support notified automatically.', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF6E5616))),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTerracotta,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            child: Text('Understood', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentBagScanned = _scannedBagIds.contains(_currentBag.bagId);
    final currentBagAccepted = _bagAcceptanceMap[_currentBag.bagId] == true;
    final currentBagRejected = _bagAcceptanceMap[_currentBag.bagId] == false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Simulation Background
          Positioned.fill(
            child: Container(
              color: const Color(0xFF14181D),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: 0.12,
                    child: GridPaper(
                      color: Colors.white,
                      divisions: 2,
                      subdivisions: 2,
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: currentBagRejected
                              ? const Color(0xFFE74C3C)
                              : (currentBagAccepted ? const Color(0xFF2ECC71) : const Color(0xFFCBA034)),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Stack(
                        children: [
                          // Scanner Corners
                          Positioned(top: 0, left: 0, child: _buildCorner(isTop: true, isLeft: true, isAcc: currentBagAccepted, isRej: currentBagRejected)),
                          Positioned(top: 0, right: 0, child: _buildCorner(isTop: true, isLeft: false, isAcc: currentBagAccepted, isRej: currentBagRejected)),
                          Positioned(bottom: 0, left: 0, child: _buildCorner(isTop: false, isLeft: true, isAcc: currentBagAccepted, isRej: currentBagRejected)),
                          Positioned(bottom: 0, right: 0, child: _buildCorner(isTop: false, isLeft: false, isAcc: currentBagAccepted, isRej: currentBagRejected)),

                          // Animated Scan Laser
                          AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return Align(
                                alignment: Alignment(0, (_animation.value * 2) - 1),
                                child: Container(
                                  height: 3,
                                  width: 230,
                                  decoration: BoxDecoration(
                                    color: currentBagRejected
                                        ? const Color(0xFFE74C3C)
                                        : (currentBagAccepted ? const Color(0xFF2ECC71) : const Color(0xFFCBA034)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (currentBagRejected
                                                ? const Color(0xFFE74C3C)
                                                : (currentBagAccepted ? const Color(0xFF2ECC71) : const Color(0xFFCBA034)))
                                            .withValues(alpha: 0.8),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // QR Symbol in Center
                          Center(
                            child: Icon(
                              Icons.qr_code_2_rounded,
                              size: 150,
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Interactive Overlay
          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Column(
                        children: [
                          Text(
                            'Mill Intake & Inspection',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Driver Handover • Leg 1 Grain Check',
                            style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          color: _isTorchOn ? const Color(0xFFF1C40F) : Colors.white,
                        ),
                        onPressed: () => setState(() => _isTorchOn = !_isTorchOn),
                      ),
                    ],
                  ),
                ),

                // Per-Product Bag Tabs / Selector
                if (_productBags.length > 1)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: _productBags.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final bag = entry.value;
                        final isSelected = idx == _selectedBagIndex;
                        final isScanned = _scannedBagIds.contains(bag.bagId);
                        final isAcc = _bagAcceptanceMap[bag.bagId] == true;
                        final isRej = _bagAcceptanceMap[bag.bagId] == false;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isRej)
                                  const Icon(Icons.cancel, size: 14, color: Color(0xFFE74C3C))
                                else if (isAcc)
                                  const Icon(Icons.check_circle, size: 14, color: Color(0xFF2ECC71))
                                else if (isScanned)
                                  const Icon(Icons.qr_code_scanner, size: 14, color: Color(0xFFF1C40F))
                                else
                                  const Icon(Icons.radio_button_unchecked, size: 14, color: Colors.white54),
                                const SizedBox(width: 4),
                                Text('Bag ${idx + 1}: ${bag.productName}'),
                              ],
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFF6E5616),
                            backgroundColor: Colors.white12,
                            labelStyle: GoogleFonts.plusJakartaSans(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _selectedBagIndex = idx);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // Quick Scan Triggers
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!currentBagScanned)
                      TextButton.icon(
                        onPressed: () => _scanBag(_currentBag),
                        icon: const Icon(Icons.touch_app_rounded, color: Color(0xFFCBA034), size: 18),
                        label: Text(
                          'Scan Unit ${_selectedBagIndex + 1} (${_currentBag.productName})',
                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFFE8C86A), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    if (!_isAllScanned && _productBags.length > 1) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _scanAllBags(acceptAll: true),
                        icon: const Icon(Icons.done_all_rounded, color: Color(0xFF2ECC71), size: 18),
                        label: Text(
                          'Scan All (${_productBags.length} Bags)',
                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF2ECC71), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ],
                ),

                const Spacer(),

                // Bottom Inspection & Accept/Reject Controls Sheet
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Verification status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: currentBagRejected
                                      ? const Color(0xFFFDEDEC)
                                      : (currentBagAccepted ? const Color(0xFFE8F8F0) : const Color(0xFFFBF4ED)),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  currentBagRejected
                                      ? Icons.cancel_outlined
                                      : (currentBagAccepted ? Icons.verified_rounded : Icons.inventory_2_outlined),
                                  color: currentBagRejected
                                      ? const Color(0xFFC0392B)
                                      : (currentBagAccepted ? const Color(0xFF2ECC71) : AppTheme.primaryTerracotta),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.order.orderId} • ${_currentBag.bagId}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryTerracotta),
                                  ),
                                  Text(
                                    '${_currentBag.productName} (${_currentBag.unitText})',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: currentBagRejected
                                  ? const Color(0xFFFDEDEC)
                                  : (currentBagAccepted ? const Color(0xFFE8F8F0) : const Color(0xFFFFF8E7)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: currentBagRejected
                                    ? const Color(0xFFF1948A)
                                    : (currentBagAccepted ? const Color(0xFFA2E4D4) : const Color(0xFFFFE082)),
                              ),
                            ),
                            child: Text(
                              currentBagRejected
                                  ? 'REJECTED ✕'
                                  : (currentBagAccepted ? 'ACCEPTED ✓' : 'INSPECTING...'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: currentBagRejected
                                    ? const Color(0xFFC0392B)
                                    : (currentBagAccepted ? const Color(0xFF1E8449) : const Color(0xFFD35400)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      const SizedBox(height: 8),

                      // Quality Checklist Pills
                      Text('Intake Quality Inspection:', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildQualityChip('💧 Moisture Dry', _isMoistureDry, (v) => setState(() => _isMoistureDry = v)),
                          _buildQualityChip('🌾 Pest Free', _isCleanPestFree, (v) => setState(() => _isCleanPestFree = v)),
                          _buildQualityChip('📦 Bag Sealed', _isPackagingIntact, (v) => setState(() => _isPackagingIntact = v)),
                          _buildQualityChip('⚖️ Weight OK', _isWeightAccurate, (v) => setState(() => _isWeightAccurate = v)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Per-Bag Accept or Reject Trigger
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: OutlinedButton.icon(
                                onPressed: () => _openBagRejectionModal(_currentBag),
                                icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFC0392B)),
                                label: Text(
                                  currentBagRejected ? 'Reason Added' : 'Reject This Bag',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFC0392B)),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFE74C3C)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _scannedBagIds.add(_currentBag.bagId);
                                    _bagAcceptanceMap[_currentBag.bagId] = true;
                                    _bagRejectionReasonMap.remove(_currentBag.bagId);
                                    if (_selectedBagIndex < _productBags.length - 1) {
                                      _selectedBagIndex++;
                                    }
                                  });
                                },
                                icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                                label: Text(
                                  'Accept Bag',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E8449),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Master Summary & Final Transition Buttons
                      if (_rejectedCount > 0) ...[
                        // Some or all bags rejected -> Dispatch Return to Delivery Boy
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _handleConfirmRejectionAndReturn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC0392B),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                            ),
                            icon: const Icon(Icons.assignment_return_rounded, color: Colors.white, size: 20),
                            label: Text(
                              'Reject & Dispatch Return to Delivery Partner ($_rejectedCount Rejected)',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ] else ...[
                        // All accepted -> Move to Milling
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: (!_isAllScanned || _isProcessing) ? null : _handleConfirmAcceptance,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryTerracotta,
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                            ),
                            icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                            label: Text(
                              !_isAllScanned
                                  ? 'Scan All Bags (${_scannedBagIds.length}/${_productBags.length} Verified)'
                                  : 'Accept All & Move to Completed (${_productBags.length} Bags)',
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildQualityChip(String label, bool isChecked, Function(bool) onToggle) {
    return InkWell(
      onTap: () => onToggle(!isChecked),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isChecked ? const Color(0xFFE8F8F0) : const Color(0xFFFDEDEC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isChecked ? const Color(0xFFA2E4D4) : const Color(0xFFF1948A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isChecked ? Icons.check_circle : Icons.cancel, size: 12, color: isChecked ? const Color(0xFF1E8449) : const Color(0xFFC0392B)),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.bold, color: isChecked ? const Color(0xFF1E8449) : const Color(0xFFC0392B))),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner({required bool isTop, required bool isLeft, required bool isAcc, required bool isRej}) {
    final color = isRej ? const Color(0xFFE74C3C) : (isAcc ? const Color(0xFF2ECC71) : const Color(0xFFCBA034));
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? BorderSide(color: color, width: 4) : BorderSide.none,
          bottom: !isTop ? BorderSide(color: color, width: 4) : BorderSide.none,
          left: isLeft ? BorderSide(color: color, width: 4) : BorderSide.none,
          right: !isLeft ? BorderSide(color: color, width: 4) : BorderSide.none,
        ),
      ),
    );
  }
}

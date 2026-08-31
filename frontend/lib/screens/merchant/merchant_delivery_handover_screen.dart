import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/merchant_models.dart';
import '../../services/merchant_api_service.dart';

class MerchantDeliveryHandoverScreen extends StatefulWidget {
  final MerchantOrder order;

  const MerchantDeliveryHandoverScreen({
    super.key,
    required this.order,
  });

  @override
  State<MerchantDeliveryHandoverScreen> createState() => _MerchantDeliveryHandoverScreenState();
}

class _MerchantDeliveryHandoverScreenState extends State<MerchantDeliveryHandoverScreen> {
  bool _isApproved = false;
  bool _isDeclined = false;
  bool _isDispatching = false;

  void _handleApprove() {
    setState(() {
      _isApproved = true;
      _isDeclined = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF2ECC71),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Approval Granted! Order ${widget.order.orderId} is authorized for handover.',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDecline() {
    String selectedReason = 'Contaminated Grain';
    final textController = TextEditingController();
    List<String> attachedImages = [
      'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&w=400&q=80',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Decline Handover ${widget.order.orderId}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Attach reason & proof photos (Max 3)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppTheme.borderLight),
                const SizedBox(height: 14),
                Text(
                  'Select Primary Reason *',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    '🌾 Contaminated Grain',
                    '💧 Wet / High Moisture',
                    '⚙️ Machine Breakdown',
                    '📦 Damaged Packaging',
                    '📝 Other Issue',
                  ].map((r) {
                    final cleanName = r.substring(2).trim();
                    final isSelected = selectedReason == cleanName || selectedReason == r;
                    return ChoiceChip(
                      label: Text(r),
                      selected: isSelected,
                      selectedColor: const Color(0xFFFFECEB),
                      backgroundColor: const Color(0xFFF6F0E7),
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.red.shade700 : AppTheme.textPrimary,
                      ),
                      side: BorderSide(
                        color: isSelected ? Colors.red.shade400 : AppTheme.borderLight,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setModalState(() => selectedReason = cleanName);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Detailed Description / Note *',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: textController,
                  maxLines: 3,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Explain why the handover or grain cannot be accepted...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderLight),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFCFAF7),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attach Photo Proof (${attachedImages.length}/3)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (attachedImages.length < 3)
                      TextButton.icon(
                        onPressed: () {
                          setModalState(() {
                            if (attachedImages.length == 1) {
                              attachedImages.add(
                                'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=400&q=80',
                              );
                            } else if (attachedImages.length == 2) {
                              attachedImages.add(
                                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
                              );
                            }
                          });
                        },
                        icon: const Icon(Icons.add_a_photo_outlined, size: 16, color: AppTheme.primaryTerracotta),
                        label: Text(
                          'Add Photo',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryTerracotta,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...attachedImages.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final url = entry.value;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderLight),
                              image: DecorationImage(
                                image: NetworkImage(url),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  attachedImages.removeAt(idx);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    if (attachedImages.length < 3)
                      GestureDetector(
                        onTap: () {
                          setModalState(() {
                            attachedImages.add(
                              attachedImages.isEmpty
                                  ? 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&w=400&q=80'
                                  : 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=400&q=80',
                            );
                          });
                        },
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F0E7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt_outlined, color: AppTheme.textSecondary, size: 22),
                              const SizedBox(height: 4),
                              Text(
                                '+ Add',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _isDeclined = true;
                        _isApproved = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.red.shade800,
                          content: Row(
                            children: [
                              const Icon(Icons.cancel_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Handover declined: $selectedReason (${attachedImages.length} proof photos attached).',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.white, size: 18),
                    label: Text(
                      'Confirm Decline & Notify Customer',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  Future<void> _handleConfirmDispatch() async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _isDispatching = true);

    final orderId = widget.order.numericId ?? 501;
    await MerchantApiService.instance.transitionOrderStatus(orderId, 'handover');

    if (!mounted) return;
    setState(() {
      _isDispatching = false;
      widget.order.statusTag = 'OUT FOR DELIVERY';
    });

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.green[800],
        content: Text('✅ Handover Dispatched! Order ${widget.order.orderId} is Out for Delivery.'),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        nav.pop(true);
      }
    });
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
          'Delivery Handover ${widget.order.orderId}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
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
                'Handover & User Approval',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Verify package QR & customer authorization before dispatch.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Order & Pickup Location Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFC0BD)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFB3AC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: AppTheme.primaryTerracotta,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.order.orderId,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryTerracotta,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryTerracotta,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.order.binLocation ?? 'Bin A-4',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.order.customerName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            widget.order.itemsSummary,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Assigned Delivery Driver Card
              Text(
                'Assigned Delivery Driver',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF6E5616), width: 2),
                        image: const DecorationImage(
                          image: NetworkImage(
                            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.order.deliveryDriverName ?? 'Vikram Delivery Agent',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.order.deliveryDriverVehicle ?? 'Electric Scooter #GJ-01-AB-1234',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2ECC71),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Arrived at Store for Pickup',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2ECC71),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Calling Driver ${widget.order.deliveryDriverName ?? "Rajesh Kumar"}...'),
                          ),
                        );
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3ECE1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.phone_rounded, color: Color(0xFF6E5616), size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Shopkeeper QR Scan & Customer Approval Card
              Text(
                'Shopkeeper QR Scan & Customer Approval',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isApproved
                        ? const Color(0xFF2ECC71)
                        : (_isDeclined ? Colors.red.shade300 : AppTheme.borderLight),
                    width: _isApproved ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _isApproved
                          ? 'Approval Verified by Customer'
                          : (_isDeclined ? 'Handover Declined' : 'Scan Package / Driver QR'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _isApproved
                            ? const Color(0xFF27AE60)
                            : (_isDeclined ? Colors.red.shade700 : AppTheme.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isApproved
                          ? 'Order authorized for delivery handover'
                          : (_isDeclined
                              ? 'Request was rejected'
                              : 'Verify package & authorize dispatch'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // QR Code Image / Verified Center Box
                    Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        color: _isApproved
                            ? const Color(0xFFE8F8F5)
                            : (_isDeclined ? const Color(0xFFFFEBEE) : const Color(0xFFFBF4ED)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isApproved
                              ? const Color(0xFF2ECC71)
                              : (_isDeclined ? Colors.red.shade400 : const Color(0xFFB87868)),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isApproved)
                            Container(
                              color: const Color(0xFF2ECC71),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 54),
                                  const SizedBox(height: 6),
                                  Text(
                                    'APPROVED',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      letterSpacing: 1.2,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Ready for Dispatch',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (_isDeclined)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cancel_rounded, color: Colors.red.shade600, size: 54),
                                const SizedBox(height: 6),
                                Text(
                                  'DECLINED',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    letterSpacing: 1.2,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          else
                            const Icon(
                              Icons.qr_code_2_rounded,
                              size: 120,
                              color: Color(0xFF8B4538),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Two Buttons: Decline & Approve
                    Row(
                      children: [
                        // Decline Button
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton.icon(
                              onPressed: _handleDecline,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _isDeclined ? Colors.red.shade700 : AppTheme.borderLight,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                foregroundColor: _isDeclined ? Colors.red.shade700 : AppTheme.textPrimary,
                              ),
                              icon: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: _isDeclined ? Colors.red.shade700 : AppTheme.textPrimary,
                              ),
                              label: Text(
                                'Decline',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Approve Button
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: _handleApprove,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isApproved ? const Color(0xFF2ECC71) : const Color(0xFF6E5616),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: Text(
                                _isApproved ? 'Approved' : 'Approve',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Confirm Handover Action Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: (!_isApproved || _isDispatching) ? null : _handleConfirmDispatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTerracotta,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                  ),
                  icon: _isDispatching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(
                          Icons.local_shipping_rounded,
                          color: !_isApproved ? Colors.grey[600] : Colors.white,
                        ),
                  label: Text(
                    _isDispatching
                        ? 'Dispatching...'
                        : (!_isApproved ? 'Awaiting Approval' : 'Confirm Handover & Dispatch'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: !_isApproved ? Colors.grey[600] : Colors.white,
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
}

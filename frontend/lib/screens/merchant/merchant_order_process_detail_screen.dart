import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/merchant_models.dart';

class MerchantOrderProcessDetailScreen extends StatefulWidget {
  final MerchantOrder order;

  const MerchantOrderProcessDetailScreen({
    super.key,
    required this.order,
  });

  @override
  State<MerchantOrderProcessDetailScreen> createState() => _MerchantOrderProcessDetailScreenState();
}

class _MerchantOrderProcessDetailScreenState extends State<MerchantOrderProcessDetailScreen> {
  late MerchantOrder _displayOrder;

  @override
  void initState() {
    super.initState();
    final steps = widget.order.timelineSteps.isNotEmpty
        ? widget.order.timelineSteps
        : _buildStepsForOrder(widget.order);

    _displayOrder = MerchantOrder(
      numericId: widget.order.numericId,
      orderId: widget.order.orderId,
      customerName: widget.order.customerName,
      itemsSummary: widget.order.itemsSummary,
      grainType: widget.order.grainType,
      quantityText: widget.order.quantityText,
      timeAgo: widget.order.timeAgo,
      statusTag: widget.order.statusTag,
      statusColor: widget.order.statusColor,
      binLocation: widget.order.binLocation ?? 'Bin A-4',
      estimatedCompletionTime: widget.order.estimatedCompletionTime ?? '30 Mins',
      deliveryDriverName: widget.order.deliveryDriverName ?? 'Rajesh Kumar',
      deliveryDriverPhone: widget.order.deliveryDriverPhone ?? '+91 98765 43210',
      deliveryDriverVehicle: widget.order.deliveryDriverVehicle ?? 'Electric Scooter #GJ-01-AB-1234',
      timelineSteps: steps,
      totalPrice: widget.order.totalPrice,
      millName: widget.order.millName,
    );
  }

  static List<MerchantProcessStep> _buildStepsForOrder(MerchantOrder order) {
    final status = order.statusTag.toUpperCase();
    final bool isReady = status == 'READY FOR PICKUP' || status == 'READY' || status == 'OUT FOR DELIVERY' || status == 'COMPLETED';
    final bool isPacking = isReady || status == 'PACKING';
    final bool isMillingComplete = isPacking;
    final bool isMilling = isMillingComplete || status == 'IN PROGRESS' || status == 'PROCESSING' || status == 'ACCEPTED';
    final bool isSecurityPassed = isMilling || status == 'NEW' || status == 'PLACED';

    final grainName = order.grainType.isNotEmpty ? order.grainType : 'Whole Wheat';
    final qty = order.quantityText.isNotEmpty ? order.quantityText : '10 kg';
    final bin = order.binLocation ?? 'Bin A-4';

    return [
      MerchantProcessStep(
        title: 'Order Received',
        timeText: '09:00 AM',
        icon: Icons.check_circle_rounded,
        isCompleted: true,
      ),
      MerchantProcessStep(
        title: 'Security Check Passed',
        timeText: '09:15 AM',
        detailsNote: 'Grain box QR verified. Container integrity confirmed.',
        icon: Icons.shield_rounded,
        isCompleted: isSecurityPassed,
      ),
      MerchantProcessStep(
        title: 'Milling Commenced',
        timeText: '09:30 AM',
        detailsNote: '⚙️ Premium $grainName. Fine grind setting.',
        icon: Icons.grass_rounded,
        isCompleted: isMilling,
      ),
      MerchantProcessStep(
        title: 'Milling Complete',
        timeText: '10:45 AM',
        detailsNote: '$qty processed. Quality inspected.',
        icon: Icons.check_circle_rounded,
        isCompleted: isMillingComplete,
      ),
      MerchantProcessStep(
        title: 'Packing & Sealing',
        timeText: '11:00 AM',
        detailsNote: 'Eco-friendly bag sealed and labeled.',
        icon: Icons.inventory_2_rounded,
        isCompleted: isPacking,
      ),
      MerchantProcessStep(
        title: 'Ready for Pickup',
        timeText: '11:05 AM',
        detailsNote: 'Stored in $bin. Delivery partner notified.',
        icon: Icons.local_shipping_rounded,
        isCompleted: isReady,
        isCurrent: isReady,
        isHighlighted: isReady,
      ),
    ];
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
          'Order ${_displayOrder.orderId}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryTerracotta,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: AppTheme.textPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help & Support: Contacting Dispatch Manager...')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Process History',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Customer Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CUSTOMER',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _displayOrder.customerName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB3AC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_shipping_rounded,
                                size: 14,
                                color: AppTheme.primaryTerracotta,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _displayOrder.statusTag,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryTerracotta,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_displayOrder.estimatedCompletionTime != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Estimated Completion: ${_displayOrder.estimatedCompletionTime}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6E5616),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3ECE1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.grass_rounded,
                            color: AppTheme.oliveGreen,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _displayOrder.productBags.length > 1
                                    ? 'Items (${_displayOrder.productBags.length} Units)'
                                    : 'Item',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _displayOrder.itemsSummary,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_displayOrder.productBags.length > 1) ...[
                      const SizedBox(height: 12),
                      Column(
                        children: _displayOrder.productBags.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final bag = entry.value;
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF4EA),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE5D5BC)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.qr_code_2_rounded, size: 14, color: Color(0xFF6E5616)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${idx + 1}. ${bag.productName} • ${bag.unitText} • ${bag.bagId}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF5C4710),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Vertical Timeline Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < _displayOrder.timelineSteps.length; i++)
                      _buildTimelineNode(
                        _displayOrder.timelineSteps[i],
                        isLast: i == _displayOrder.timelineSteps.length - 1,
                        context: context,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineNode(
    MerchantProcessStep step, {
    required bool isLast,
    required BuildContext context,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: step.isHighlighted
                      ? const Color(0xFFB85042)
                      : (step.isCompleted ? const Color(0xFFB8A44F) : const Color(0xFFE2DACF)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  step.icon,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFE2DACF),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          step.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        step.timeText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (step.detailsNote.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: step.isHighlighted
                            ? const Color(0xFFFFECEB)
                            : const Color(0xFFF6F2EA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: step.isHighlighted
                              ? const Color(0xFFFFC0BD)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        step.detailsNote,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: step.isHighlighted ? FontWeight.w600 : FontWeight.w400,
                          color: step.isHighlighted ? const Color(0xFFB85042) : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

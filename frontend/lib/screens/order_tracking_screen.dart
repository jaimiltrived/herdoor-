import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/app_models.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  int _viewMode = 0; // 0 = Stepper View (Image 1), 1 = Map & Details View (Image 5)
  Timer? _uiRefreshTimer;
  late OrderModel _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _ensureTrackingSteps();
    _uiRefreshTimer = Timer.periodic(const Duration(seconds: 2), (t) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _ensureTrackingSteps() {
    if (_order.trackingSteps.isEmpty) {
      final s = _order.statusStep.toUpperCase();
      final isDelivered = s == 'DELIVERED' || s == 'COMPLETED';
      final isOut = s == 'OUT FOR DELIVERY' || s == 'OUT_FOR_DELIVERY';
      final isReady = s == 'READY' || s == 'READY FOR PICKUP' || s == 'READY_FOR_PICKUP' || s == 'PACKING';
      final isMilling = s == 'IN PROGRESS' || s == 'PROCESSING' || s == 'MILLING' || s == 'ACCEPTED';

      _order.trackingSteps.addAll([
        TrackingStep(
          title: 'Order Placed',
          subtitle: 'Received at mill',
          timeText: '10:00 AM',
          isCompleted: true,
          isCurrent: false,
        ),
        TrackingStep(
          title: 'Grain Cleaning',
          subtitle: 'Moisture checked',
          timeText: (isMilling || isReady || isOut || isDelivered) ? '10:15 AM' : '',
          isCompleted: (isMilling || isReady || isOut || isDelivered),
          isCurrent: !isMilling && !isReady && !isOut && !isDelivered,
        ),
        TrackingStep(
          title: 'Milling in Progress',
          subtitle: 'Stone chakki grinding',
          timeText: (isReady || isOut || isDelivered) ? '10:30 AM' : (isMilling ? 'In progress' : 'Pending'),
          isCompleted: (isReady || isOut || isDelivered),
          isCurrent: isMilling,
        ),
        TrackingStep(
          title: 'Out for Delivery',
          subtitle: 'Assigned to driver',
          timeText: isDelivered ? '11:00 AM' : (isOut ? 'On the way' : 'Pending'),
          isCompleted: isDelivered,
          isCurrent: isOut,
        ),
        TrackingStep(
          title: 'Delivered',
          subtitle: 'Doorstep handover',
          timeText: isDelivered ? '11:15 AM' : 'Pending',
          isCompleted: isDelivered,
          isCurrent: false,
        ),
      ]);
    }
  }

  void _advanceStep() {
    setState(() {
      final steps = _order.trackingSteps;
      if (steps.isEmpty) return;

      int cur = steps.indexWhere((s) => s.isCurrent);
      if (cur == -1) {
        cur = steps.indexWhere((s) => !s.isCompleted);
      }

      if (cur != -1 && cur < steps.length) {
        final now = DateTime.now();
        final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
        final period = now.hour >= 12 ? 'PM' : 'AM';
        final minute = now.minute.toString().padLeft(2, '0');
        final timeStr = '$hour:$minute $period';

        steps[cur] = TrackingStep(
          title: steps[cur].title,
          subtitle: steps[cur].subtitle,
          timeText: (steps[cur].timeText.isEmpty || steps[cur].timeText == 'Pending' || steps[cur].timeText == 'In progress')
              ? timeStr
              : steps[cur].timeText,
          isCompleted: true,
          isCurrent: false,
        );

        final next = cur + 1;
        if (next < steps.length) {
          final isLast = next == steps.length - 1;
          steps[next] = TrackingStep(
            title: steps[next].title,
            subtitle: steps[next].subtitle,
            timeText: isLast ? 'Delivered' : 'In progress',
            isCompleted: isLast,
            isCurrent: !isLast,
          );
          _order.statusStep = steps[next].title;
          if (isLast) {
            _order.isActive = false;
          }
        } else {
          _order.statusStep = 'Delivered';
          _order.isActive = false;
        }
      }
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Order status advanced to: ${_order.statusStep}',
          style: GoogleFonts.plusJakartaSans(),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<Map<String, dynamic>> _getOrderItems() {
    if (_order.items.isNotEmpty) {
      return _order.items;
    }

    final summary = _order.itemSummary;
    final qtyNumber = int.tryParse(_order.quantityKg.replaceAll(RegExp(r'[^0-9]'), '')) ?? 5;
    final total = _order.totalPrice > 0 ? _order.totalPrice : 14.0;

    if (summary.contains(',')) {
      final parts = summary.split(',');
      final itemPrice = total / parts.length;
      return parts.map((part) {
        final name = part.trim();
        return {
          'name': name,
          'type': name.toLowerCase().contains('pack') || name.toLowerCase().contains('mix') ? 'readymade' : 'milling',
          'quantity': 1,
          'price': itemPrice,
        };
      }).toList();
    }

    return [
      {
        'name': summary.isNotEmpty ? summary : 'Stone Ground Flour',
        'type': 'milling',
        'quantity': qtyNumber,
        'price': total,
      }
    ];
  }

  @override
  void dispose() {
    _uiRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _order.millName.isNotEmpty ? _order.millName : 'HerDoor Flour Mill',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryTerracotta,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _viewMode == 0 ? Icons.map_outlined : Icons.list_alt_rounded,
              color: AppTheme.primaryTerracotta,
            ),
            onPressed: () {
              setState(() => _viewMode = _viewMode == 0 ? 1 : 0);
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: AppTheme.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle View Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _viewMode = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _viewMode == 0 ? AppTheme.primaryTerracotta : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Text(
                        'Full Progress',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _viewMode == 0 ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => setState(() => _viewMode = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _viewMode == 1 ? AppTheme.primaryTerracotta : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Text(
                        'Map & Receipt',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _viewMode == 1 ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_viewMode == 0) _buildImage1StepperView() else _buildImage5MapView(),
            ],
          ),
        ),
      ),
    );
  }

  // --- IMAGE 1 UI VIEW ---
  Widget _buildImage1StepperView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Order Info Banner Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
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
                children: [
                  Text(
                    'Order ${_order.orderId}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.mustardGold,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _order.quantityKg,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _order.itemSummary,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCream,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: const Icon(Icons.access_time_rounded, color: AppTheme.mustardDark, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated Delivery',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          _order.estimatedDelivery,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Vertical Step List (Matching Image 1)
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _order.trackingSteps.length,
          itemBuilder: (context, index) {
            final step = _order.trackingSteps[index];
            final isLast = index == _order.trackingSteps.length - 1;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline Node Column
                  Column(
                    children: [
                      _buildStepNodeIcon(step, index),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: step.isCompleted ? AppTheme.oliveGreen : AppTheme.borderLight,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Content Column
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                step.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: step.isCurrent
                                      ? AppTheme.primaryTerracotta
                                      : (step.isCompleted ? AppTheme.textPrimary : AppTheme.textMuted),
                                ),
                              ),
                              if (step.timeText.isNotEmpty)
                                Text(
                                  step.timeText,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: step.isCurrent ? FontWeight.bold : FontWeight.normal,
                                    color: step.isCurrent ? AppTheme.primaryTerracotta : AppTheme.textMuted,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step.subtitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: step.isCompleted ? AppTheme.textSecondary : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        if (_order.isActive && _order.trackingSteps.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWarm,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.mustardDark.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.primaryTerracotta,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Auto-Tracking Active: Order will be completed in 20 minutes',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _advanceStep,
                  child: Text(
                    'Skip Next >',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTerracotta,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepNodeIcon(TrackingStep step, int index) {
    if (step.isCompleted) {
      return Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppTheme.oliveGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 20),
      );
    } else if (step.isCurrent) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primaryTerracotta.withValues(alpha: 0.85),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.sync, color: Colors.white, size: 20),
      );
    } else {
      final icons = [
        Icons.receipt_long_rounded,
        Icons.person_pin_circle_rounded,
        Icons.precision_manufacturing_rounded,
        Icons.two_wheeler_rounded,
        Icons.check_circle_outline_rounded,
      ];
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.surfaceCream,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Icon(
          icons[index % icons.length],
          color: AppTheme.textMuted,
          size: 18,
        ),
      );
    }
  }

  // --- IMAGE 5 MAP & RECEIPT VIEW ---
  Widget _buildImage5MapView() {
    final items = _getOrderItems();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Text(
                'Order ${_order.orderId}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Estimated completion: ${_order.estimatedDelivery}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Tracking Process Card (Dynamic)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tracking Process',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              ..._order.trackingSteps.asMap().entries.map((entry) {
                final idx = entry.key;
                final step = entry.value;
                final isLast = idx == _order.trackingSteps.length - 1;
                return _buildSimpleStep(
                  step.isCompleted,
                  step.title,
                  step.isCurrent
                      ? '${step.subtitle} • ${step.timeText}'
                      : (step.timeText.isNotEmpty ? step.timeText : step.subtitle),
                  step.isCurrent,
                  isLast: isLast,
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Map View Box
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: Image.network(
                  'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=800&q=80',
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      _order.millName.isNotEmpty ? _order.millName : 'Artisan Mill Co.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _order.deliveryAddress.isNotEmpty ? _order.deliveryAddress : '124 Heritage Way, Grain District',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Contacting ${_order.millName}...'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.surfaceCream,
                        foregroundColor: AppTheme.textPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.phone_outlined, size: 18),
                      label: Text(
                        'Contact Mill',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Items Summary Box (Dynamic)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Items Summary',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...items.map((item) {
                final name = item['name']?.toString() ?? 'Flour Item';
                final qty = item['quantity'] ?? 1;
                final price = (item['price'] is num) ? (item['price'] as num).toDouble() : 5.0;
                final isWheat = name.toLowerCase().contains('wheat');
                final badgeColor = isWheat ? const Color(0xFFB5B782) : AppTheme.mustardGold;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              name.length > 8 ? '${name.substring(0, 6)}..' : name,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Qty: $qty',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        '\$${(price * (qty is int ? qty : 1)).toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 24, color: AppTheme.borderLight),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Paid',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '\$${_order.totalPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTerracotta,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleStep(bool isDone, String title, String subtitle, bool isWorking, {bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              if (isDone)
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppTheme.oliveGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                )
              else if (isWorking)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryTerracotta, width: 3),
                  ),
                )
              else
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCream,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone ? AppTheme.oliveGreen : AppTheme.borderLight,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isWorking
                          ? AppTheme.primaryTerracotta
                          : (isDone ? AppTheme.textPrimary : AppTheme.textMuted),
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isWorking ? AppTheme.softCoral : AppTheme.textSecondary,
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

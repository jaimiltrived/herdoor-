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

  @override
  void initState() {
    super.initState();
    _uiRefreshTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {});
      }
    });
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
          'HerDoor Flour Mill',
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
    final activeOrder = widget.order;
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
                    'Order ${activeOrder.orderId}',
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
                      activeOrder.quantityKg,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                activeOrder.itemSummary,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
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
                          activeOrder.estimatedDelivery,
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
          itemCount: activeOrder.trackingSteps.length,
          itemBuilder: (context, index) {
            final step = activeOrder.trackingSteps[index];
            final isLast = index == activeOrder.trackingSteps.length - 1;
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

        if (activeOrder.isActive && activeOrder.trackingSteps.isNotEmpty) ...[
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
                  onPressed: () {
                    setState(() {
                      MockData.advanceOrderStep(activeOrder);
                    });
                  },
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Text(
                'Order ${widget.order.orderId}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Estimated completion: ${widget.order.estimatedDelivery}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Tracking Process Card (Image 5 style)
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
              _buildSimpleStep(true, 'Order Placed', '10:00 AM', false),
              _buildSimpleStep(true, 'Order Pickup', 'Picked up by Rahul Sharma', false),
              _buildSimpleStep(
                false,
                'Order Processing',
                'In Progress • In 20 mins',
                true,
              ),
              _buildSimpleStep(false, 'Out for Delivery', 'Driver on the way', false),
              _buildSimpleStep(false, 'Delivered', 'At your door', false, isLast: true),
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
                      'Artisan Mill Co.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '124 Heritage Way, Grain District',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.surfaceCream,
                        foregroundColor: AppTheme.textPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.phone_outlined, size: 18),
                      label: Text(
                        'Contact',
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

        // Items Summary Box
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
                'Items',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB5B782),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Whole\nWheat',
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
                            'Stone Ground Flour',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '(2kg)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '\$14.00',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, color: AppTheme.borderLight),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '\$14.00',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
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

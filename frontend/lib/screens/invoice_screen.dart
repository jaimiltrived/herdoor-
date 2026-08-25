import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/app_models.dart';
import 'order_tracking_screen.dart';

class InvoiceScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final String millName;
  final double subtotal;
  final double pickupFee;
  final double deliveryFee;
  final double total;
  final String pickupTime; // Doubles as delivery time for readymade
  final String address;
  final String paymentMethod;
  final String? orderNumber;

  const InvoiceScreen({
    super.key,
    this.cartItems = const [],
    this.millName = 'Shree Ganesh Flour Mill',
    this.subtotal = 0.0,
    this.pickupFee = 0.0,
    this.deliveryFee = 0.0,
    this.total = 0.0,
    this.pickupTime = 'Within 24 Hours',
    this.address = '456 Heritage Block, District 9, NY',
    this.paymentMethod = 'Visa Card',
    this.orderNumber,
  });

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  late String _receiptId;
  late OrderModel _order;
  int _secondsRemaining = 3;
  Timer? _autoRedirectTimer;

  @override
  void initState() {
    super.initState();
    _receiptId = widget.orderNumber ?? '#HD-${6000 + Random().nextInt(899)}';

    _order = OrderModel(
      orderId: _receiptId,
      millName: widget.millName,
      itemSummary: widget.cartItems.map((item) => item['name']).join(', '),
      quantityKg: '${widget.cartItems.fold<int>(0, (sum, item) => sum + ((item['quantity'] ?? 1) as num).toInt())} items',
      estimatedDelivery: widget.pickupTime,
      statusStep: 'Order Placed',
      totalPrice: widget.total,
      trackingSteps: [
        TrackingStep(
          title: 'Order Placed',
          subtitle: 'We received your order.',
          timeText: 'Now',
          isCompleted: true,
        ),
        TrackingStep(
          title: 'Order Pickup',
          subtitle: 'Picked up by Rahul Sharma (Pickup Agent)',
          timeText: 'In 20 mins',
          isCurrent: true,
        ),
        TrackingStep(
          title: 'Order Processing',
          subtitle: 'Milling & quality packaging in progress at mill.',
          timeText: '',
        ),
        TrackingStep(
          title: 'Out for Delivery',
          subtitle: 'Delivery partner on the way to your door.',
          timeText: '',
        ),
        TrackingStep(
          title: 'Delivered',
          subtitle: 'Fresh flour delivered at your door.',
          timeText: '',
        ),
      ],
      isActive: true,
      date: 'Today',
      selectedGrain: widget.cartItems.isNotEmpty ? widget.cartItems[0]['name'] : '',
      grainSource: 1,
      pickupAddress: widget.address,
      deliveryAddress: widget.address,
      paymentMethod: widget.paymentMethod,
      millingFee: widget.subtotal,
      deliveryFee: widget.deliveryFee,
      items: List<Map<String, dynamic>>.from(widget.cartItems.map((item) => Map<String, dynamic>.from(item))),
    );

    MockData.orders.insert(0, _order);

    // Auto-redirect to home in 5 seconds if no action is taken
    _autoRedirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _redirectToHome();
      }
    });
  }

  void _redirectToHome() {
    _autoRedirectTimer?.cancel();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _trackOrder() {
    _autoRedirectTimer?.cancel();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OrderTrackingScreen(order: _order)),
    );
  }

  @override
  void dispose() {
    _autoRedirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: _redirectToHome,
        ),
        title: Text(
          'Order Invoice',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryTerracotta,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success Header
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 48),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Order Successful',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Order $_receiptId has been confirmed',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Mill & Time Info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCream,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.storefront, color: AppTheme.primaryTerracotta),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            widget.millName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppTheme.borderLight),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: AppTheme.textSecondary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.address.isNotEmpty ? widget.address : '456 Heritage Block, District 9, NY',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: AppTheme.textSecondary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          widget.pickupTime,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Order Details Breakdown
              Text(
                'Order Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  children: [
                    ...widget.cartItems.map((item) {
                      final name = item['name'] ?? 'Item';
                      final type = item['type'] ?? 'milling';
                      final qty = item['quantity'] ?? 1;
                      final price = item['price'] ?? 0.0;
                      final itemTotal = (price * qty).toStringAsFixed(2);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${qty}x ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryTerracotta,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    type == 'milling' ? 'Milling Service' : 'Readymade Product',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\$$itemTotal',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 24, color: AppTheme.borderLight),
                    _buildInvoiceRow('Subtotal', '\$${widget.subtotal.toStringAsFixed(2)}'),
                    if (widget.pickupFee > 0)
                      _buildInvoiceRow('Pickup Fee', '\$${widget.pickupFee.toStringAsFixed(2)}'),
                    _buildInvoiceRow('Delivery Fee', '\$${widget.deliveryFee.toStringAsFixed(2)}'),
                    const Divider(height: 24, color: AppTheme.borderLight),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Grand Total',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '\$${widget.total.toStringAsFixed(2)}',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryTerracotta,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment Info
              Text(
                'Payment Info',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payment, color: AppTheme.primaryTerracotta),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${widget.paymentMethod} (•••• 4242)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Paid',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: _trackOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTerracotta,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                ),
                child: Text(
                  'Track Order',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _redirectToHome,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryTerracotta, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Back to Home',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryTerracotta,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCream,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_secondsRemaining}s',
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
              ),
              const SizedBox(height: 6),
              Text(
                'Auto-redirecting to Home in $_secondsRemaining seconds...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

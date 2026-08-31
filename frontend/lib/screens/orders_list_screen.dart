import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/app_models.dart';
import '../models/merchant_models.dart';
import '../services/customer_api_service.dart';
import 'order_tracking_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class OrdersListScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  const OrdersListScreen({super.key, this.onOpenDrawer});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  bool _showActiveOrders = true;
  bool _isLoading = false;
  List<MerchantOrder>? _apiOrders;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchOrders(showLoading: true);
    // Real-time automatic background polling every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchOrders(showLoading: false);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrders({bool showLoading = false}) async {
    if (!mounted) return;
    if (showLoading) setState(() => _isLoading = true);
    final orders = await CustomerApiService.instance.getCustomerOrders();
    if (mounted) {
      setState(() {
        _apiOrders = orders;
        if (showLoading) _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Map dynamic orders to OrderModel if available
    List<OrderModel> dynamicActive = [];
    List<OrderModel> dynamicPast = [];

    if (_apiOrders != null && _apiOrders!.isNotEmpty) {
      for (final o in _apiOrders!) {
        final s = o.statusTag.toUpperCase();
        final isActive = [
          'NEW',
          'PLACED',
          'ACCEPTED',
          'PROCESSING',
          'PACKING',
          'READY',
          'READY FOR PICKUP',
          'READY_FOR_PICKUP',
          'OUT FOR DELIVERY',
          'OUT_FOR_DELIVERY',
          'IN PROGRESS'
        ].contains(s);

        final mapped = OrderModel(
          orderId: o.orderId,
          millName: o.millName.isNotEmpty ? o.millName : 'Artisan Mill Co.',
          itemSummary: o.itemsSummary,
          quantityKg: o.quantityText,
          estimatedDelivery: 'Within 20 minutes',
          statusStep: o.statusTag,
          totalPrice: o.totalPrice,
          isActive: isActive,
          date: o.timeAgo,
          selectedGrain: o.grainType,
          trackingSteps: [
            TrackingStep(title: 'Order Placed', subtitle: 'Received at mill', timeText: '10:00 AM', isCompleted: true),
            TrackingStep(title: 'Grain Cleaning', subtitle: 'Moisture checked', timeText: '10:15 AM', isCompleted: true),
            TrackingStep(title: 'Milling in Progress', subtitle: 'Stone chakki grinding', timeText: '10:30 AM', isCurrent: isActive),
            TrackingStep(title: 'Out for Delivery', subtitle: 'Assigned to driver', timeText: 'Pending'),
            TrackingStep(title: 'Delivered', subtitle: 'Doorstep handover', timeText: 'Pending'),
          ],
        );

        if (isActive) {
          dynamicActive.add(mapped);
        } else {
          dynamicPast.add(mapped);
        }
      }
    }

    final activeOrders = dynamicActive.isNotEmpty ? dynamicActive : MockData.orders.where((o) => o.isActive).toList();
    final pastOrders = dynamicPast.isNotEmpty ? dynamicPast : MockData.orders.where((o) => !o.isActive).toList();
    
    final displayOrders = _showActiveOrders ? activeOrders : pastOrders;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppTheme.textPrimary),
          onPressed: widget.onOpenDrawer,
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
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.borderLight, width: 2),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=200&q=80',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        color: AppTheme.primaryTerracotta,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order History',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              
              // Toggle Switch
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showActiveOrders = true),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _showActiveOrders ? AppTheme.primaryTerracotta : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            'Current',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              color: _showActiveOrders ? Colors.white : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showActiveOrders = false),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: !_showActiveOrders ? AppTheme.primaryTerracotta : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            'Previous',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              color: !_showActiveOrders ? Colors.white : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              if (_isLoading && _apiOrders == null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 60.0),
                    child: CircularProgressIndicator(color: AppTheme.primaryTerracotta),
                  ),
                )
              else if (displayOrders.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 56,
                          color: AppTheme.textSecondary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No ${_showActiveOrders ? 'current' : 'previous'} orders.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _showActiveOrders
                              ? 'Any new orders will appear here in real-time.'
                              : 'Your completed order receipts will show here.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...displayOrders.asMap().entries.map((entry) => _buildOrderCard(context, entry.value, entry.key)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          if (order.isActive) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderTrackingScreen(order: order),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartScreen(
                  cartItems: [
                    {
                      'name': order.itemSummary,
                      'type': 'milling',
                      'source': 'Own Grain',
                      'quantity': 5,
                      'price': 0.50,
                    }
                  ],
                  millName: order.millName,
                  millId: order.millName.toLowerCase().contains('navrang') ? 102 : 101,
                ),
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.orderId,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTerracotta,
                    ),
                  ),
                  _buildStatusBadge(order.statusStep),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                order.millName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order.itemSummary.toLowerCase().contains(order.quantityKg.toLowerCase())
                    ? order.itemSummary
                    : (order.quantityKg.isNotEmpty ? '${order.itemSummary} • ${order.quantityKg}' : order.itemSummary),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: AppTheme.borderLight, height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.date,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '₹${order.totalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F5EF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              order.isActive ? 'View & Track' : 'Reorder',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryTerracotta,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppTheme.primaryTerracotta),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final s = status.toUpperCase();
    Color bgColor;
    Color textColor;

    if (s.contains('NEW') || s.contains('PLACED') || s.contains('COMPLETED') || s.contains('DELIVERED')) {
      bgColor = const Color(0xFFE8F5E9); // soft green
      textColor = const Color(0xFF43A047);
    } else if (s.contains('PROGRESS') || s.contains('PROCESS') || s.contains('PACK') || s.contains('READY') || s.contains('PICKUP')) {
      bgColor = const Color(0xFFFFF8E1); // soft mustard amber
      textColor = const Color(0xFF8D6E1F);
    } else if (s.contains('OUT') || s.contains('DELIVERY') || s.contains('ASSIGNED')) {
      bgColor = const Color(0xFFE1F5FE); // soft blue
      textColor = const Color(0xFF0288D1);
    } else {
      bgColor = const Color(0xFFF5F5F5);
      textColor = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}


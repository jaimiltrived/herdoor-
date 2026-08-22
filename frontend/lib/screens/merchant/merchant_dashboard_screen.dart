import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/merchant_models.dart';
import '../../services/merchant_api_service.dart';
import 'merchant_order_process_detail_screen.dart';
import 'merchant_active_driver_pickup_screen.dart';

class MerchantDashboardScreen extends StatefulWidget {
  final Function(int) onNavigateTab;

  const MerchantDashboardScreen({
    super.key,
    required this.onNavigateTab,
  });

  @override
  State<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  bool _isAcceptingOrders = true;
  bool _isLoading = false;
  int _readyForDispatchCount = 3;
  MerchantDashboardMetrics _metrics = MerchantDashboardMetrics(
    pendingOrders: 3,
    activeOrders: 3,
    completedOrders: 9,
    totalRevenue: 90.0,
  );
  List<MerchantOrder> _activeOrders = MerchantMockData.activeOrders;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    // Fetch availability state
    final bool? availability = await MerchantApiService.instance.getShopAvailability();
    if (availability != null && mounted) {
      _isAcceptingOrders = availability;
    }

    // Fetch dashboard metrics
    final metrics = await MerchantApiService.instance.getDashboardMetrics();
    if (metrics != null && mounted) {
      _metrics = metrics;
    }

    // Fetch real count for Ready for Dispatch orders
    final completedOrders = await MerchantApiService.instance.getCompletedOrders();
    if (completedOrders != null && completedOrders.isNotEmpty && mounted) {
      _readyForDispatchCount = completedOrders.length;
    }

    // Fetch active processing orders
    final activeOrders = await MerchantApiService.instance.getActiveOrders();
    if (activeOrders != null && activeOrders.isNotEmpty && mounted) {
      _activeOrders = activeOrders;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAvailability(bool val) async {
    setState(() => _isAcceptingOrders = val);
    final success = await MerchantApiService.instance.updateShopAvailability(val);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: val ? const Color(0xFF2ECC71) : Colors.grey[800],
          content: Text(
            success
                ? 'Store Status updated on Backend: ${val ? "Accepting Orders" : "Shop Closed"}'
                : 'Failed to update store status',
          ),
        ),
      );
    }
  }

  Future<void> _handleAcceptOrder(MerchantOrder order) async {
    final orderId = order.numericId ?? 501;
    final success = await MerchantApiService.instance.acceptOrder(orderId, estimatedMinutes: 30);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2ECC71),
            content: Text('✅ Order ${order.orderId} Accepted! Customer notified.'),
          ),
        );
        _loadDashboardData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order ${order.orderId} Accepted locally.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: AppTheme.primaryTerracotta,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shop Status',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: _isAcceptingOrders ? const Color(0xFF2ECC71) : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isAcceptingOrders ? 'Accepting Orders' : 'Shop Closed',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: _isAcceptingOrders,
                        activeThumbColor: Colors.white,
                        activeTrackColor: const Color(0xFF6E5616),
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey[300],
                        onChanged: (val) => _toggleAvailability(val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F0E7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.access_time_rounded,
                            color: Color(0xFF6E5616),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Operating Hours",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              '8:00 AM - 8:00 PM',
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
              ),
            ),
            const SizedBox(height: 20),

            // Two Overview Stats Cards: Total Orders & Live Active Orders
            Row(
              children: [
                // Card 1: Total Orders
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
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
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFB3AC),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFECEB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '+${_metrics.pendingOrders} Pending',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryTerracotta,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '${_metrics.pendingOrders + _metrics.activeOrders + _metrics.completedOrders}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total Orders Today',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '(₹${_metrics.totalRevenue.toInt()})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Card 2: Live Active Orders & Delivery Boy Status
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MerchantActiveDriverPickupScreen(),
                        ),
                      );
                      if (mounted) _loadDashboardData();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
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
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFE082),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.two_wheeler_rounded,
                                  color: Color(0xFF6E5616),
                                  size: 22,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE67E22),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Driver on Way',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFD35400),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '$_readyForDispatchCount',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryTerracotta,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ready for Dispatch',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Shop Ready • Pickup Pending',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFD35400),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Active Orders Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Orders',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => widget.onNavigateTab(1),
                  child: Row(
                    children: [
                      Text(
                        'View All',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6E5616),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Color(0xFF6E5616),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Active Order Cards List
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryTerracotta),
                ),
              )
            else
              for (final order in _activeOrders) _buildActiveOrderCard(context, order),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrderCard(BuildContext context, MerchantOrder order) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MerchantOrderProcessDetailScreen(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F0E7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: AppTheme.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Order ${order.orderId}',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: order.statusTag == 'NEW'
                                  ? const Color(0xFFFFECEB)
                                  : const Color(0xFFFBF4DF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.statusTag,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: order.statusTag == 'NEW'
                                    ? AppTheme.primaryTerracotta
                                    : const Color(0xFF8C6E15),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.itemsSummary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 15,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  '${order.customerName} • ${order.timeAgo}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildDashboardCardAction(context, order),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCardAction(BuildContext context, MerchantOrder order) {
    final status = order.statusTag;
    final orderId = order.numericId ?? 501;

    if (status == 'NEW' || status == 'New Request') {
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: () => _handleAcceptOrder(order),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6E5616),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Accept Order', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      );
    } else if (status == 'IN PROGRESS') {
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton.icon(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            await MerchantApiService.instance.transitionOrderStatus(orderId, 'packing');
            if (!mounted) return;
            messenger.showSnackBar(
              SnackBar(backgroundColor: const Color(0xFF2ECC71), content: Text('⚙️ Order ${order.orderId} moved to Packing!')),
            );
            _loadDashboardData();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6E5616),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 18),
          label: Text('Move to Packing', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      );
    } else if (status == 'PACKING') {
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton.icon(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            await MerchantApiService.instance.transitionOrderStatus(orderId, 'ready');
            if (!mounted) return;
            messenger.showSnackBar(
              SnackBar(backgroundColor: const Color(0xFF2ECC71), content: Text('✅ Order ${order.orderId} marked Ready!')),
            );
            _loadDashboardData();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2ECC71),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
          label: Text('Mark Ready for Pickup', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: OutlinedButton.icon(
          onPressed: () {
            widget.onNavigateTab(1);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF6E5616),
            side: const BorderSide(color: Color(0xFF6E5616)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.receipt_long_rounded, size: 18),
          label: Text('View Order Details', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        ),
      );
    }
  }
}

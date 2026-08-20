import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/merchant_models.dart';
import '../../services/merchant_api_service.dart';
import 'merchant_order_process_detail_screen.dart';
import 'merchant_delivery_handover_screen.dart';

class MerchantOrdersScreen extends StatefulWidget {
  const MerchantOrdersScreen({super.key});

  @override
  State<MerchantOrdersScreen> createState() => _MerchantOrdersScreenState();
}

class _MerchantOrdersScreenState extends State<MerchantOrdersScreen> {
  int _selectedFilterTab = 0; // 0: New, 1: Pending (Active), 2: Completed
  bool _isLoading = true;
  MerchantDashboardMetrics? _metrics;
  List<MerchantOrder> _orders = MerchantMockData.pendingRequests;

  @override
  void initState() {
    super.initState();
    _fetchOrdersData();
  }

  Future<void> _fetchOrdersData() async {
    setState(() => _isLoading = true);

    // Load Overview Metrics
    final metrics = await MerchantApiService.instance.getDashboardMetrics();
    if (metrics != null) {
      _metrics = metrics;
    }

    // Load Orders List according to selected filter tab
    List<MerchantOrder>? fetched;
    if (_selectedFilterTab == 0) {
      fetched = await MerchantApiService.instance.getNewOrders();
    } else if (_selectedFilterTab == 1) {
      fetched = await MerchantApiService.instance.getActiveOrders();
    } else {
      fetched = await MerchantApiService.instance.getCompletedOrders();
    }

    if (fetched != null) {
      _orders = fetched;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onTabChanged(int index) async {
    setState(() {
      _selectedFilterTab = index;
    });
    await _fetchOrdersData();
  }

  Future<void> _handleDecline(MerchantOrder order) async {
    final orderId = order.numericId ?? 501;
    final success = await MerchantApiService.instance.rejectOrder(orderId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Order ${order.orderId} Declined on Backend'
                : 'Order ${order.orderId} Declined locally',
          ),
        ),
      );
      _fetchOrdersData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final int pendingCount = _metrics?.pendingOrders ?? 0;
    final int activeCount = _metrics?.activeOrders ?? 0;
    final int completedCount = _metrics?.completedOrders ?? 0;
    final int totalOrdersCount = pendingCount + activeCount + completedCount;

    return RefreshIndicator(
      onRefresh: _fetchOrdersData,
      color: AppTheme.primaryTerracotta,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Management',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Review and process incoming merchant requests.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 18),

            // Action Buttons: Filter & Export
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showFilterBottomSheet(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.textSecondary, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      icon: const Icon(Icons.filter_list_rounded, size: 20),
                      label: Text(
                        'Filter',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Exporting order report to CSV...')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTerracotta,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      icon: const Icon(Icons.file_download_outlined, size: 20),
                      label: Text(
                        'Export',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Today's Overview Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFCF9F5),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF3ECE1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Overview",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isLoading ? '...' : '$totalOrdersCount',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Total Orders',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isLoading ? '...' : '${pendingCount + activeCount}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryTerracotta,
                              ),
                            ),
                            Text(
                              'Active / Action Required',
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
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Filter Tab Bar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F0E7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildFilterTab(0, 'NEW', '$pendingCount', Icons.new_label_outlined),
                  _buildFilterTab(1, 'Pending', '$activeCount', Icons.hourglass_empty_rounded),
                  _buildFilterTab(2, 'Completed', '$completedCount', Icons.check_circle_outline_rounded),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Orders List
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: CircularProgressIndicator(color: AppTheme.primaryTerracotta)),
              )
            else if (_orders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: Text(
                    'No orders in this category.',
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              for (final order in _orders) _buildOrderRequestCard(context, order),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(int index, String title, String count, IconData icon) {
    final isSelected = _selectedFilterTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFAF2DD) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: const Color(0xFFD4C094)) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? const Color(0xFF6E5616) : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6E5616) : const Color(0xFFE2DACF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderRequestCard(BuildContext context, MerchantOrder order) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MerchantOrderProcessDetailScreen(order: order),
          ),
        ).then((_) => _fetchOrdersData());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.orderId,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9D9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF6E5616),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              order.statusTag,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6E5616),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order.customerName,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            Container(
              color: const Color(0xFFFCFAF7),
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3ECE1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.grass_rounded,
                          color: Color(0xFF6E5616),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Grain Type',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            order.grainType,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3ECE1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.hourglass_bottom_rounded,
                          color: Color(0xFF6E5616),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quantity',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            order.quantityText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dynamic Action Controls based on Order Status
                  _buildOrderCardActions(context, order),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCardActions(BuildContext context, MerchantOrder order) {
    final status = order.statusTag;
    final orderId = order.numericId ?? 501;

    if (status == 'NEW' || status == 'New Request') {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: () => _handleDecline(order),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.textSecondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Decline',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () => _showAcceptOrderTimeModal(context, order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6E5616),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Accept Order',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
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
              SnackBar(
                backgroundColor: const Color(0xFF2ECC71),
                content: Text('⚙️ Order ${order.orderId} moved to Packing!'),
              ),
            );
            _fetchOrdersData();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6E5616),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 18),
          label: Text(
            'Move to Packing',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white),
          ),
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
              SnackBar(
                backgroundColor: const Color(0xFF2ECC71),
                content: Text('✅ Order ${order.orderId} marked Ready for Pickup!'),
              ),
            );
            _fetchOrdersData();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2ECC71),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
          label: Text(
            'Mark Ready for Pickup',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      );
    } else if (status == 'READY FOR PICKUP' || status == 'READY') {
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MerchantDeliveryHandoverScreen(order: order)),
            ).then((_) => _fetchOrdersData());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryTerracotta,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 18),
          label: Text(
            'Handover to Delivery',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      );
    } else if (status == 'OUT FOR DELIVERY') {
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton.icon(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            await MerchantApiService.instance.transitionOrderStatus(orderId, 'complete');
            if (!mounted) return;
            messenger.showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF2ECC71),
                content: Text('🎉 Order ${order.orderId} Completed!'),
              ),
            );
            _fetchOrdersData();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2ECC71),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.done_all_rounded, color: Colors.white, size: 18),
          label: Text(
            'Complete Order',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      );
    } else {
      // COMPLETED
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F8F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_rounded, color: Color(0xFF2ECC71), size: 18),
              const SizedBox(width: 6),
              Text(
                'Order Delivered & Completed',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF2ECC71), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showAcceptOrderTimeModal(BuildContext context, MerchantOrder order) {
    String selectedTime = '30 Mins';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Accept Order & Set Completion Time',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Estimate when order ${order.orderId} for ${order.customerName} will be ready for pickup / delivery.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Time Presets
              Text(
                'Select Estimated Completion Time:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ['15 Mins', '30 Mins', '45 Mins', '1 Hour'].map((timeStr) {
                  final isSel = selectedTime == timeStr;
                  return ChoiceChip(
                    label: Text(timeStr),
                    selected: isSel,
                    selectedColor: AppTheme.primaryTerracotta,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      setModalState(() {
                        selectedTime = timeStr;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final int mins = int.tryParse(selectedTime.split(' ').first) ?? 30;
                    final orderId = order.numericId ?? 501;
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(context);

                    await MerchantApiService.instance.acceptOrder(orderId, estimatedMinutes: mins);

                    setState(() {
                      order.statusTag = 'IN PROGRESS';
                      order.estimatedCompletionTime = selectedTime;
                    });
                    if (!mounted) return;
                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.green[800],
                        content: Text(
                          '✅ Order ${order.orderId} Accepted on Backend! Completion time set to $selectedTime.',
                        ),
                      ),
                    );
                    _fetchOrdersData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6E5616),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                  label: Text(
                    'Confirm Acceptance & Notify Customer',
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
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Orders',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(label: const Text('Whole Wheat'), selected: true, onSelected: (val) {}),
                FilterChip(label: const Text('Rye Blend'), selected: false, onSelected: (val) {}),
                FilterChip(label: const Text('Priority'), selected: false, onSelected: (val) {}),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

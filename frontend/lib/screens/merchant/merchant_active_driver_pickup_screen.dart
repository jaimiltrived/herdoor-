import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/merchant_models.dart';
import '../../services/merchant_api_service.dart';

class MerchantActiveDriverPickupScreen extends StatefulWidget {
  const MerchantActiveDriverPickupScreen({super.key});

  @override
  State<MerchantActiveDriverPickupScreen> createState() => _MerchantActiveDriverPickupScreenState();
}

class _MerchantActiveDriverPickupScreenState extends State<MerchantActiveDriverPickupScreen> {
  bool _isLoading = false;
  Timer? _pollingTimer;
  List<MerchantOrder> _readyOrders = [];
  final List<MerchantOrder> _dispatchedOrders = [];

  @override
  void initState() {
    super.initState();
    _fetchReadyOrders(showLoading: true);
    // Real-time auto-polling every 3 seconds for live completed orders
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchReadyOrders(showLoading: false);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchReadyOrders({bool showLoading = false}) async {
    if (showLoading) setState(() => _isLoading = true);
    try {
      final fetchedReady = await MerchantApiService.instance.getReadyOrders();
      final fetchedActive = await MerchantApiService.instance.getActiveOrders();
      if (mounted) {
        final List<MerchantOrder> combined = [];
        if (fetchedReady != null && fetchedReady.isNotEmpty) {
          combined.addAll(fetchedReady);
        }
        if (fetchedActive != null) {
          final readyFromActive = fetchedActive.where((o) =>
              o.statusTag == 'READY FOR PICKUP' ||
              o.statusTag == 'READY' ||
              o.statusTag == 'Ready for Pickup' ||
              o.statusTag == 'PACKING');
          for (var o in readyFromActive) {
            if (!combined.any((x) => x.orderId == o.orderId)) {
              combined.add(o);
            }
          }
        }

        setState(() {
          _readyOrders = combined
              .where((o) => !_dispatchedOrders.any((d) => d.orderId == o.orderId))
              .toList();
          if (showLoading) _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && showLoading) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleHandoverOrder(MerchantOrder order) async {
    final orderId = order.numericId ?? 501;
    setState(() {
      order.statusTag = 'OUT FOR DELIVERY';
      _readyOrders.removeWhere((o) => o.orderId == order.orderId);
      _dispatchedOrders.insert(0, order);
    });

    await MerchantApiService.instance.transitionOrderStatus(orderId, 'handover');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF2ECC71),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '✅ Authorized! Order ${order.orderId} handed over to ${order.deliveryDriverName ?? "Driver"}.',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
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
          'Ready for Dispatch',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryTerracotta,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchReadyOrders,
          color: AppTheme.primaryTerracotta,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Delivery Handover',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Completed orders waiting for assigned delivery partners.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Ready Orders List Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ready for Handover (${_readyOrders.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF2DD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Shop Ready',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6E5616),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryTerracotta),
                    ),
                  )
                else if (_readyOrders.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.task_alt_rounded, color: Color(0xFF2ECC71), size: 48),
                      const SizedBox(height: 10),
                      Text(
                        'All Ready Orders Handed Over!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All milled packages are out with delivery drivers.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final order in _readyOrders) _buildReadyOrderPickupCard(context, order),

              const SizedBox(height: 20),

              // Dispatched Orders Section if any
              if (_dispatchedOrders.isNotEmpty) ...[
                Text(
                  'Recently Dispatched (${_dispatchedOrders.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                for (final order in _dispatchedOrders)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8F0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFA2E4D4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.two_wheeler_rounded, color: Color(0xFF2ECC71), size: 22),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.orderId,
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  '${order.customerName} • ${order.quantityText}',
                                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2ECC71),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'OUT FOR DELIVERY',
                            style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildReadyOrderPickupCard(BuildContext context, MerchantOrder order) {
    return Container(
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
                Text(
                  order.orderId.isNotEmpty ? order.orderId : '#ORD-9921-A',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  order.customerName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  order.itemsSummary,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Grain Type', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
                          Text(order.grainType, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quantity', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
                          Text(order.quantityText, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Assigned Delivery Boy Div (Only this boy is authorized)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F5EF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8DFC8)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFE082),
                          border: Border.all(color: const Color(0xFF6E5616), width: 1.5),
                        ),
                        child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF6E5616), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  order.deliveryDriverName ?? 'Vikram Delivery Agent',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.verified_rounded, color: Color(0xFF2ECC71), size: 15),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${order.deliveryDriverVehicle ?? "Electric Scooter #GJ-01-AB-1234"} • Only Authorized Boy',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF6E5616),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Verified Boy',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF27AE60),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Shopkeeper Allow & Handover Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleHandoverOrder(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B4513),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                    label: Text(
                      'Allow & Handover to ${order.deliveryDriverName?.split(' ').first ?? 'Driver'}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
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
    );
  }
}

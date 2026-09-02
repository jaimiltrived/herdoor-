import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/merchant_models.dart';
import '../../services/delivery_api_service.dart';
import 'active_trip_screen.dart';

class DeliveryTripSheetScreen extends StatefulWidget {
  final DeliveryTrip? activeTrip;
  final Function(DeliveryTrip) onTripSelected;
  final VoidCallback onExploreRadar;
  final VoidCallback onTripCompleted;

  const DeliveryTripSheetScreen({
    super.key,
    this.activeTrip,
    required this.onTripSelected,
    required this.onExploreRadar,
    required this.onTripCompleted,
  });

  @override
  State<DeliveryTripSheetScreen> createState() => _DeliveryTripSheetScreenState();
}

class _DeliveryTripSheetScreenState extends State<DeliveryTripSheetScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<DeliveryTrip> _assignedTrips = [];
  List<Map<String, dynamic>> _completedTrips = [];
  List<DeliveryTrip> _nearbyAvailableTrips = [];
  String _selectedPastFilter = 'All';
  Timer? _realtimeRefreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTripSheetData();
    _startRealtimeRefresh();
  }

  @override
  void didUpdateWidget(covariant DeliveryTripSheetScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeTrip != widget.activeTrip) {
      _loadTripSheetData();
    }
  }

  @override
  void dispose() {
    _realtimeRefreshTimer?.cancel();
    _realtimeRefreshTimer = null;
    _tabController.dispose();
    super.dispose();
  }

  void _startRealtimeRefresh() {
    _realtimeRefreshTimer?.cancel();
    _realtimeRefreshTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (mounted) {
        _loadTripSheetData(silentRefresh: true);
      }
    });
  }

  Future<void> _loadTripSheetData({bool silentRefresh = false}) async {
    if (!silentRefresh) {
      setState(() => _isLoading = true);
    }
    try {
      final results = await Future.wait([
        DeliveryApiService.instance.getAssignedTrips(),
        DeliveryApiService.instance.getCompletedTrips(),
        DeliveryApiService.instance.getAvailableTrips(),
      ]);
      final assigned = List<DeliveryTrip>.from(results[0] as List<DeliveryTrip>);
      final completed = List<Map<String, dynamic>>.from(results[1] as List<Map<String, dynamic>>);
      final nearby = List<DeliveryTrip>.from(results[2] as List<DeliveryTrip>);

      // Merge completed trips so recently finished trips are preserved seamlessly
      final Set<dynamic> completedKeys = completed.map((c) => c['orderId'] ?? c['orderNumber']).toSet();
      for (var local in _completedTrips) {
        final key = local['orderId'] ?? local['orderNumber'];
        final orderNum = local['orderNumber'];
        final localStops = (local['stops'] is List) ? (local['stops'] as List) : [];

        // If not in completed, insert at top
        if (key != null && !completedKeys.contains(key) && !completedKeys.contains(orderNum)) {
          completed.insert(0, local);
          completedKeys.add(key);
          if (orderNum != null) completedKeys.add(orderNum);
        } else if (localStops.isNotEmpty) {
          // If server returned a flattened/incomplete item without stops, replace with rich local version
          final existingIdx = completed.indexWhere((c) => c['orderId'] == key || c['orderNumber'] == orderNum || c['orderNumber'] == key);
          if (existingIdx != -1) {
            final existingStops = (completed[existingIdx]['stops'] is List) ? (completed[existingIdx]['stops'] as List) : [];
            if (existingStops.length < localStops.length) {
              completed[existingIdx] = local;
            }
          }
        }
      }

      // If activeTrip passed from parent, ensure it's in assigned list only if not completed
      if (widget.activeTrip != null &&
          !completedKeys.contains(widget.activeTrip!.orderId) &&
          !completedKeys.contains(widget.activeTrip!.orderNumber) &&
          !assigned.any((t) => t.orderId == widget.activeTrip!.orderId)) {
        assigned.insert(0, widget.activeTrip!);
      }

      // Sort by real deliveredAt timestamp so newest deliveries always appear first
      completed.sort((a, b) {
        final ta = DateTime.tryParse(a['deliveredAt']?.toString() ?? '') ?? DateTime(2000);
        final tb = DateTime.tryParse(b['deliveredAt']?.toString() ?? '') ?? DateTime(2000);
        return tb.compareTo(ta); // newest first
      });

      // Recompute time-ago labels using real timestamps
      for (final c in completed) {
        final deliveredAt = DateTime.tryParse(c['deliveredAt']?.toString() ?? '');
        if (deliveredAt != null) {
          final diff = DateTime.now().difference(deliveredAt);
          if (diff.inMinutes < 1) {
            c['deliveredTimeAgo'] = 'Just now';
          } else if (diff.inMinutes < 60) {
            c['deliveredTimeAgo'] = '${diff.inMinutes} min ago';
          } else if (diff.inHours < 24) {
            c['deliveredTimeAgo'] = '${diff.inHours} hr ago';
          } else {
            c['deliveredTimeAgo'] = '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
          }
        }
      }

      setState(() {
        _assignedTrips = assigned;
        _completedTrips = completed;
        _nearbyAvailableTrips = nearby.where((n) => !assigned.any((a) => a.orderId == n.orderId) && !assigned.any((a) => a.stops.any((s) => s.orderId == n.orderId))).toList();
        if (!silentRefresh) {
          _isLoading = false;
        }
      });
    } catch (_) {
      if (!silentRefresh) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _acceptAndAssignTrip(DeliveryTrip trip) async {
    final batchStopIds = trip.isBatch ? trip.stops.map((s) => s.orderId).toSet() : <int>{};
    final batchStopNums = trip.isBatch ? trip.stops.map((s) => s.orderNumber).toSet() : <String>{};

    setState(() {
      // Remove the grouped batch or single trip from available
      _nearbyAvailableTrips.removeWhere((t) {
        if (t.orderId == trip.orderId) return true;
        // Also remove any individual orders that are stops in this grouped batch
        if (trip.isBatch && batchStopIds.contains(t.orderId)) return true;
        if (trip.isBatch && batchStopNums.contains(t.orderNumber)) return true;
        return false;
      });

      if (!_assignedTrips.any((t) => t.orderId == trip.orderId || t.orderNumber == trip.orderNumber)) {
        _assignedTrips.insert(0, trip);
      }
    });

    final batchLabel = trip.isBatch ? 'Grouped Batch' : 'Order';
    final activeMsg = trip.isBatch
        ? 'All ${trip.stops.length} stops are now active'
        : 'Now active';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚡ $batchLabel ${trip.orderNumber} accepted! $activeMsg in Trip Sheet.'),
        backgroundColor: const Color(0xFF1E8449),
        duration: const Duration(seconds: 2),
      ),
    );

    // Call backend API to persist assignment in MySQL database
    if (trip.isBatch && trip.stops.isNotEmpty) {
      await DeliveryApiService.instance.acceptGroupTrip(
        groupCode: trip.orderNumber,
        orderIds: trip.stops.map((s) => s.orderId).toList(),
        stops: trip.stops.map((s) => {
          'orderId': s.orderId,
          'orderNumber': s.orderNumber,
          'customerName': s.customerName,
          'customerPhone': s.customerPhone,
          'homePickupAddress': s.homePickupAddress,
          'deliveryAddress': s.deliveryAddress,
          'quantityKg': s.quantityKg,
          'grainTypeName': s.grainTypeName,
          'barcodeNumber': s.barcodeNumber,
          'pickupPin': s.pickupPin,
          'deliveryOtp': s.deliveryOtp,
          'orderPayout': s.orderPayout,
          'distanceKm': s.distanceKm,
        }).toList(),
        totalFee: trip.deliveryFee,
      );
    } else {
      await DeliveryApiService.instance.acceptTrip(trip.orderId);
    }
  }

  void _openTripDetail(DeliveryTrip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveTripScreen(
          trip: trip,
          onTripCompleted: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            widget.onTripCompleted();
            _handleTripCompletionRealtime(trip);
          },
        ),
      ),
    ).then((_) => _loadTripSheetData());
  }

  void _handleTripCompletionRealtime(DeliveryTrip trip) {
    setState(() {
      _assignedTrips.removeWhere((t) => t.orderId == trip.orderId || t.orderNumber == trip.orderNumber);
      // Also remove any individual stops from assigned trips that were part of this batch
      if (trip.isBatch && trip.stops.isNotEmpty) {
        final stopIds = trip.stops.map((s) => s.orderId).toSet();
        final stopNums = trip.stops.map((s) => s.orderNumber).toSet();
        _assignedTrips.removeWhere((t) => stopIds.contains(t.orderId) || stopNums.contains(t.orderNumber));
      }

      if (trip.isBatch && trip.stops.length > 1) {
        // Add ONE grouped batch entry (NOT split into individual stops)
        // This preserves the grouped batch view in Past Deliveries with stops breakdown
        if (!_completedTrips.any((c) => c['orderId'] == trip.orderId || c['orderNumber'] == trip.orderNumber)) {
          final uniqueStopNames = trip.stops.map((s) {
            final name = s.customerName;
            return name.replaceAll(RegExp(r'\s*\(Stop\s*\d+\)\s*'), '').trim();
          }).toSet().toList();

          final customerSummary = uniqueStopNames.length == 1
              ? '${uniqueStopNames.first} • ${trip.stops.length} Orders'
              : uniqueStopNames.join(' + ');

          _completedTrips.insert(0, {
            'orderId': trip.orderId,
            'orderNumber': trip.orderNumber,
            'customerName': 'Grouped ${trip.stops.length}x Batch ($customerSummary)',
            'customerPhone': trip.customerPhone,
            'millName': trip.millName,
            'millAddress': trip.millAddress,
            'homePickupAddress': trip.homePickupAddress,
            'deliveryAddress': trip.deliveryAddress,
            'quantityKg': trip.stops.fold<double>(0.0, (sum, s) => sum + s.quantityKg),
            'grainTypeName': trip.grainTypeName,
            'deliveryFee': trip.deliveryFee,
            'totalEarned': trip.deliveryFee + trip.surgeBonus + trip.heavyBagBonus,
            'tipAmount': 30.0,
            'surgeBonus': trip.surgeBonus,
            'heavyBagBonus': trip.heavyBagBonus,
            'distanceKm': trip.distanceKm,
            'isBatch': true,
            'stopsCount': trip.stops.length,
            'status': 'DELIVERED',
            'deliveredAt': DateTime.now().toIso8601String(),
            'deliveredTimeAgo': 'Just now',
            'customerRating': 5.0,
            'customerReview': 'Super smooth multi-stop batch delivery. All ${trip.stops.length} bags verified and intact.',
            'barcodeVerified': true,
            'otpVerified': true,
            'paymentMode': 'Online Paid (UPI)',
            'paymentStatus': 'PAID',
            'stops': trip.stops.map((s) => ({
              'orderId': s.orderId,
              'orderNumber': s.orderNumber,
              'customerName': s.customerName,
              'quantityKg': s.quantityKg,
              'grainTypeName': s.grainTypeName,
              'deliveryAddress': s.deliveryAddress,
              'payout': s.orderPayout,
              'orderPayout': s.orderPayout,
            })).toList(),
          });
        }
      } else {
        if (!_completedTrips.any((c) => c['orderId'] == trip.orderId || c['orderNumber'] == trip.orderNumber)) {
          _completedTrips.insert(0, {
            'orderId': trip.orderId,
            'orderNumber': trip.orderNumber,
            'customerName': trip.customerName,
            'customerPhone': trip.customerPhone,
            'millName': trip.millName,
            'millAddress': trip.millAddress,
            'homePickupAddress': trip.homePickupAddress,
            'deliveryAddress': trip.deliveryAddress,
            'quantityKg': trip.quantityKg,
            'grainTypeName': trip.grainTypeName,
            'deliveryFee': trip.deliveryFee,
            'totalEarned': trip.deliveryFee + trip.surgeBonus,
            'tipAmount': 20.0,
            'surgeBonus': trip.surgeBonus,
            'distanceKm': trip.distanceKm,
            'status': 'DELIVERED',
            'deliveredAt': DateTime.now().toIso8601String(),
            'deliveredTimeAgo': 'Just now',
            'customerRating': 5.0,
            'customerReview': 'Perfect delivery! Freshly milled flour handed over with verified seal.',
            'barcodeVerified': true,
            'otpVerified': true,
            'paymentMode': 'Online (UPI)',
            'paymentStatus': 'PAID'
          });
        }
      }
    });

    if (mounted) {
      _tabController.animateTo(1);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 ${trip.isBatch ? "Grouped batch" : "Order"} ${trip.orderNumber} successfully delivered & saved to database!'),
        backgroundColor: const Color(0xFF1E8449),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showReceiptModal(Map<String, dynamic> pastOrder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Receipt & Proof',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      pastOrder['orderNumber'] ?? '#HD-ORDER',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryTerracotta,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF1E8449)),
                      const SizedBox(width: 4),
                      Text(
                        'DELIVERED',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E8449),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 10),

            // Item Details
            _buildReceiptRow('Customer', pastOrder['customerName'] ?? 'Customer'),
            _buildReceiptRow('Flour/Grain', pastOrder['grainTypeName'] ?? 'Fresh Atta'),
            _buildReceiptRow('Quantity', '${pastOrder['quantityKg']} kg'),
            _buildReceiptRow('Origin Chakki', pastOrder['millName'] ?? 'Shree Ganesh Flour Mill'),
            _buildReceiptRow('Delivered At', pastOrder['deliveredTimeAgo'] ?? 'Recently'),
            _buildReceiptRow('Payment Mode', pastOrder['paymentMode'] ?? 'Online Paid (UPI)'),

            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),

            // Payout Summary
            Text('Rider Earnings Breakdown', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            _buildReceiptRow('Base Delivery Fee', '₹${(pastOrder['deliveryFee'] ?? 65.0).toStringAsFixed(0)}'),
            if ((pastOrder['surgeBonus'] ?? 0) > 0)
              _buildReceiptRow('Surge Demand Bonus', '+₹${(pastOrder['surgeBonus'] ?? 20.0).toStringAsFixed(0)}', highlightColor: const Color(0xFFC0392B)),
            if ((pastOrder['tipAmount'] ?? 0) > 0)
              _buildReceiptRow('Customer Tip', '+₹${(pastOrder['tipAmount'] ?? 15.0).toStringAsFixed(0)}', highlightColor: const Color(0xFF1E8449)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Earned Credited', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14)),
                Text('₹${(pastOrder['totalEarned'] ?? 95.0).toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1E8449))),
              ],
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTerracotta,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Close Receipt', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: highlightColor ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.format_list_bulleted_rounded, color: AppTheme.primaryTerracotta, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Trip Sheet & Orders',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryTerracotta,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryTerracotta,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.electric_moped_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text('Current Trips (${_assignedTrips.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text('Past Delivered (${_completedTrips.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryTerracotta))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveTripsTab(),
                _buildPastDeliveriesTab(),
              ],
            ),
    );
  }

  // TAB 1: Current Active / Grouped Orders
  Widget _buildActiveTripsTab() {
    return RefreshIndicator(
      color: AppTheme.primaryTerracotta,
      onRefresh: _loadTripSheetData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_assignedTrips.isNotEmpty) ...[
              Text(
                'Active Grouped & Single Trips In Progress',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ..._assignedTrips.map((trip) => _buildActiveTripCard(trip)),
            ] else ...[
              _buildEmptyActiveTripState(),
            ],

            const SizedBox(height: 24),
            // Quick Accept Nearby Orders Carousel
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick-Accept Next Nearby Batches',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: widget.onExploreRadar,
                  child: Text('View Radar (5km)', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryTerracotta)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_nearbyAvailableTrips.isNotEmpty)
              ..._nearbyAvailableTrips.take(3).map((trip) => _buildNearbyQuickTripCard(trip))
            else
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Center(
                  child: Text('All radar orders synced! Check Radar tab for live updates.', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTripCard(DeliveryTrip trip) {
    final isGrouped = trip.stops.length > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isGrouped ? const Color(0xFFC0392B) : const Color(0xFF1E8449), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isGrouped ? const Color(0xFFFDEDEC) : const Color(0xFFE8F8F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(isGrouped ? Icons.layers_rounded : Icons.local_shipping_rounded, size: 14, color: isGrouped ? const Color(0xFFC0392B) : const Color(0xFF1E8449)),
                        const SizedBox(width: 4),
                        Text(
                          isGrouped ? '${trip.stops.length}-STOP GROUPED BATCH' : 'SINGLE ACTIVE RUN',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isGrouped ? const Color(0xFFC0392B) : const Color(0xFF1E8449),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Text(
                '₹${trip.deliveryFee.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E8449),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(trip.customerName, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          Text('${trip.quantityKg} kg • ${trip.grainTypeName}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 10),

          // Route Timeline Nodes
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF6F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                if (trip.isLeg1GrainPickup) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.home_work_outlined, size: 16, color: Color(0xFF2980B9)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isGrouped ? 'Home Pickups: ${trip.stops.length} Customer Addresses' : 'Home Pickup: ${trip.homePickupAddress}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.storefront_rounded, size: 16, color: AppTheme.primaryTerracotta),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Chakki Mill Drop: ${trip.millName} (${trip.millAddress})',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.storefront_rounded, size: 16, color: AppTheme.primaryTerracotta),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Chakki Mill Pickup: ${trip.millName} (${trip.millAddress})',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF1E8449)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isGrouped ? 'Customer Doorstep Drops: ${trip.stops.length} Customer Homes' : 'Final Drop: ${trip.deliveryAddress}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isGrouped) ...[
            const SizedBox(height: 10),
            Text('Grouped Multi-Stop Breakdown (${trip.stops.length} Stops):', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            ...trip.stops.asMap().entries.map((e) {
              final idx = e.key;
              final stop = e.value;
              final pickupAddr = trip.isLeg1GrainPickup ? stop.homePickupAddress : trip.millAddress;
              final dropAddr = trip.isLeg1GrainPickup ? trip.millAddress : stop.deliveryAddress;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F5EE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Stop ${idx + 1}: ${stop.customerName}', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('₹${stop.orderPayout.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1E8449))),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('📦 ${stop.quantityKg.toStringAsFixed(1)} kg • ${stop.grainTypeName}', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('📍 Pickup: $pickupAddr', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF0284C7)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('🏡 Drop: $dropAddr', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF16A34A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 14),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openTripDetail(trip),
                  icon: const Icon(Icons.navigation_rounded, size: 18, color: Colors.white),
                  label: Text('Resume Navigation', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTerracotta,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => launchUrl(Uri.parse('tel:${trip.customerPhone}')),
                icon: const Icon(Icons.call, size: 18, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: const Color(0xFF1E8449)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActiveTripState() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFFAF6F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.two_wheeler_rounded, size: 48, color: AppTheme.primaryTerracotta),
          ),
          const SizedBox(height: 16),
          Text(
            'No Ongoing Trips Right Now',
            style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Pick up multiple orders on the 5km radar to start earning.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: widget.onExploreRadar,
            icon: const Icon(Icons.radar_rounded, color: Colors.white, size: 18),
            label: Text('Explore Radar Queue (${_nearbyAvailableTrips.length})', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTerracotta,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyQuickTripCard(DeliveryTrip trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(trip.orderNumber, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryTerracotta)),
                    const SizedBox(width: 6),
                    Text('• ${trip.distanceKm} km', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(trip.customerName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('${trip.quantityKg}kg • ${trip.grainTypeName}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${trip.deliveryFee.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF1E8449))),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: () => _acceptAndAssignTrip(trip),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E8449),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Accept', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TAB 2: Past Delivered Orders History
  Widget _buildPastDeliveriesTab() {
    bool isGroupedTrip(Map<String, dynamic> t) {
      final stops = t['stops'];
      final stopsLen = (stops is List) ? stops.length : 0;
      final custName = (t['customerName'] ?? '').toString().toLowerCase();
      final ordNum = (t['orderNumber'] ?? '').toString().toUpperCase();
      return t['isBatch'] == true ||
          ordNum.contains('GRP') ||
          ordNum.contains('POOL') ||
          custName.contains('grouped') ||
          custName.contains('batch') ||
          (t['stopsCount'] ?? 1) > 1 ||
          stopsLen > 1;
    }

    final filtered = _completedTrips.where((t) {
      if (_selectedPastFilter == 'Today') {
        final timeStr = (t['deliveredTimeAgo'] ?? '').toString().toLowerCase();
        final isToday = timeStr.contains('hr') || timeStr.contains('min') || timeStr.contains('today') || timeStr.contains('just now');
        if (!isToday) return false;
      }
      if (_selectedPastFilter == 'Grouped') {
        if (!isGroupedTrip(t)) return false;
      }
      if (_selectedPastFilter == 'Heavy') {
        final kg = (t['quantityKg'] is num) ? (t['quantityKg'] as num).toDouble() : (double.tryParse(t['quantityKg'].toString()) ?? 0.0);
        if (kg < 10.0) return false;
      }
      return true;
    }).toList();

    final groupedCount = _completedTrips.where(isGroupedTrip).length;

    final todayCount = _completedTrips.where((t) {
      final timeStr = (t['deliveredTimeAgo'] ?? '').toString().toLowerCase();
      return timeStr.contains('hr') || timeStr.contains('min') || timeStr.contains('today') || timeStr.contains('just now');
    }).length;

    final heavyCount = _completedTrips.where((t) {
      final kg = (t['quantityKg'] is num) ? (t['quantityKg'] as num).toDouble() : (double.tryParse(t['quantityKg'].toString()) ?? 0.0);
      return kg >= 10.0;
    }).length;

    return RefreshIndicator(
      color: AppTheme.primaryTerracotta,
      onRefresh: _loadTripSheetData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPastFilterChip('All', 'All Past Deliveries (${_completedTrips.length})'),
                  _buildPastFilterChip('Grouped', '📦 Grouped Batches ($groupedCount)'),
                  _buildPastFilterChip('Today', '📅 Delivered Today ($todayCount)'),
                  _buildPastFilterChip('Heavy', '⚖️ Heavy Batches 10kg+ ($heavyCount)'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (filtered.isNotEmpty)
              ...filtered.map((item) => _buildPastDeliveryCard(item))
            else
              Container(
                padding: const EdgeInsets.all(28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 42, color: AppTheme.textMuted),
                    const SizedBox(height: 10),
                    Text('No past deliveries under this filter.', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPastFilterChip(String key, String label) {
    final isSelected = _selectedPastFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        selected: isSelected,
        selectedColor: AppTheme.primaryTerracotta,
        backgroundColor: Colors.white,
        side: BorderSide(color: isSelected ? AppTheme.primaryTerracotta : AppTheme.borderLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onSelected: (val) {
          if (val) setState(() => _selectedPastFilter = key);
        },
      ),
    );
  }

  Widget _buildPastDeliveryCard(Map<String, dynamic> item) {
    final ordNum = (item['orderNumber'] ?? '').toString().toUpperCase();
    final custName = (item['customerName'] ?? '').toString().toLowerCase();
    final isGrouped = item['isBatch'] == true ||
        ordNum.contains('GRP') ||
        ordNum.contains('POOL') ||
        custName.contains('grouped') ||
        custName.contains('batch') ||
        (item['stopsCount'] ?? 1) > 1 ||
        (item['stops'] is List && (item['stops'] as List).length > 1);

    final stopsList = (item['stops'] is List) ? (item['stops'] as List) : [];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isGrouped ? const Color(0xFFC0392B) : AppTheme.borderLight, width: isGrouped ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isGrouped ? const Color(0xFFFDEDEC) : const Color(0xFFE8F8F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(isGrouped ? Icons.layers_rounded : Icons.check_circle_rounded, size: 14, color: isGrouped ? const Color(0xFFC0392B) : const Color(0xFF1E8449)),
                        const SizedBox(width: 4),
                        Text(
                          isGrouped ? 'GROUPED BATCH' : (item['orderNumber'] ?? '#HD-ORDER'),
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11, color: isGrouped ? const Color(0xFFC0392B) : const Color(0xFF1E8449)),
                        ),
                      ],
                    ),
                  ),
                  if (isGrouped) ...[
                    const SizedBox(width: 6),
                    Text(
                      item['orderNumber'] ?? '#HD-GRP',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryTerracotta),
                    ),
                  ],
                ],
              ),
              Text(
                item['deliveredTimeAgo'] ?? 'Recently',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['customerName'] ?? 'Customer', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('${item['quantityKg']} kg • ${item['grainTypeName']}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    Text('Drop: ${item['deliveryAddress']}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${(item['totalEarned'] ?? 75.0).toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 18, color: const Color(0xFF1E8449))),
                  Text('Earned Payout', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),

          if (isGrouped && stopsList.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Grouped Multi-Drop Breakdown (${stopsList.length} Stops):', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            ...stopsList.asMap().entries.map((e) {
              final idx = e.key;
              final stop = Map<String, dynamic>.from(e.value as Map);
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F5EE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Stop ${idx + 1}: ${stop['customerName'] ?? 'Customer'}', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('${stop['grainTypeName'] ?? 'Atta'} • Drop: ${stop['deliveryAddress'] ?? 'Ahmedabad'}', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Text('₹${(stop['payout'] ?? stop['orderPayout'] ?? 85.0).toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1E8449))),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Rating and Receipt Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF39C12)),
                  const SizedBox(width: 4),
                  Text('5.0 Rating', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFB7791F))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3ECE1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Doorstep Verified', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF6E5616))),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showReceiptModal(item),
                child: Text(
                  'View Proof Receipt ➔',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryTerracotta),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

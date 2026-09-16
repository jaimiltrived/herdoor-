import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/merchant_models.dart';
import '../../services/delivery_api_service.dart';
import 'active_trip_screen.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  final Function(DeliveryTrip trip)? onTripAccepted;
  final VoidCallback? onOpenDrawer;

  const DeliveryDashboardScreen({
    super.key,
    this.onTripAccepted,
    this.onOpenDrawer,
  });

  @override
  State<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isOnline = true;
  bool _isAutoAccept = false;
  String _selectedFilter = 'All'; // 'All' | 'HomeToMill' | 'MillToHome'
  String _selectedVehicle = 'CAR_VAN'; // 'ALL' | 'CAR_VAN' | 'BIKE_EV'
  final double _selectedRadiusKm = 5.0; // Strict 5.0 km radius
  int? _hoveredMapOrderId;

  RiderProfile? _profile;
  RiderEarnings? _earnings;
  List<DeliveryTrip> _allTrips = [];
  List<DeliveryTrip> _assignedTrips = [];
  bool _hasAutoResumedActiveTrip = false;
  final Set<int> _selectedTripOrderIds = <int>{};
  DeliveryTrip? _incomingAlertTrip;
  int _alertCountdown = 30;
  Timer? _alertTimer;
  Timer? _realtimeSyncTimer;
  late AnimationController _radarPulseController;

  void _toggleTripSelection(int orderId) {
    setState(() {
      if (_selectedTripOrderIds.contains(orderId)) {
        _selectedTripOrderIds.remove(orderId);
      } else {
        _selectedTripOrderIds.add(orderId);
      }
    });
  }

  void _selectAllFilteredTrips() {
    setState(() {
      final currentIds = _filteredTrips.map((t) => t.orderId).toSet();
      if (_selectedTripOrderIds.containsAll(currentIds)) {
        _selectedTripOrderIds.clear();
      } else {
        _selectedTripOrderIds.addAll(currentIds);
      }
    });
  }

  void _clearSelectedTrips() {
    setState(() {
      _selectedTripOrderIds.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _radarPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _loadDashboardData();
    _startRealtimeLiveSync();
  }

  @override
  void dispose() {
    _radarPulseController.dispose();
    _alertTimer?.cancel();
    _realtimeSyncTimer?.cancel();
    super.dispose();
  }

  List<DeliveryTrip> _filterActiveAssignedTrips(List<DeliveryTrip> rawAssigned, Set<dynamic> completedKeys) {
    final List<DeliveryTrip> filtered = [];
    final Set<dynamic> seen = {};

    for (final a in rawAssigned) {
      final statusUpper = a.status.toUpperCase();
      if (completedKeys.contains(a.orderId) ||
          completedKeys.contains(a.orderNumber) ||
          (a.groupCode != null && completedKeys.contains(a.groupCode)) ||
          statusUpper == 'DELIVERED' ||
          statusUpper == 'COMPLETED' ||
          statusUpper == 'CANCELLED') {
        continue;
      }

      if (a.isBatch && a.stops.isNotEmpty) {
        final allStopsDone = a.stops.every((s) => completedKeys.contains(s.orderId) || completedKeys.contains(s.orderNumber));
        if (allStopsDone) continue;
      }

      final key = a.orderNumber.isNotEmpty ? a.orderNumber : '${a.orderId}';
      if (seen.contains(key) || seen.contains(a.orderId)) continue;
      seen.add(key);
      seen.add(a.orderId);
      filtered.add(a);
    }

    return filtered;
  }

  void _startRealtimeLiveSync() {
    _realtimeSyncTimer?.cancel();
    _realtimeSyncTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || !_isOnline) return;
      try {
        final results = await Future.wait([
          DeliveryApiService.instance.getAvailableTrips(
            maxRadiusKm: _selectedRadiusKm,
            vehicleType: _selectedVehicle,
            forceRefresh: true,
          ),
          DeliveryApiService.instance.getEarnings(),
          DeliveryApiService.instance.getAssignedTrips(),
          DeliveryApiService.instance.getCompletedTrips(),
        ]);
        final trips = results[0] as List<DeliveryTrip>;
        final earnings = results[1] as RiderEarnings;
        final assigned = results[2] as List<DeliveryTrip>;
        final completed = results[3] as List<Map<String, dynamic>>;

        final completedKeys = <dynamic>{};
        for (final c in completed) {
          if (c['orderId'] != null) completedKeys.add(c['orderId']);
          if (c['orderNumber'] != null) completedKeys.add(c['orderNumber']);
          if (c['groupCode'] != null) completedKeys.add(c['groupCode']);
          if (c['groupId'] != null) completedKeys.add(c['groupId']);
          if (c['stops'] is List) {
            for (final s in (c['stops'] as List)) {
              if (s is Map) {
                if (s['orderId'] != null) completedKeys.add(s['orderId']);
                if (s['orderNumber'] != null) completedKeys.add(s['orderNumber']);
              }
            }
          }
        }

        final filteredAssigned = _filterActiveAssignedTrips(assigned, completedKeys);

        final assignedIds = filteredAssigned.map((a) => a.orderId).toSet();
        final assignedNums = filteredAssigned.map((a) => a.orderNumber).toSet();
        for (var a in filteredAssigned) {
          assignedIds.addAll(a.stops.map((s) => s.orderId));
          assignedNums.addAll(a.stops.map((s) => s.orderNumber));
        }

        final filteredTrips = trips.where((t) {
          if (completedKeys.contains(t.orderId) ||
              completedKeys.contains(t.orderNumber) ||
              (t.groupCode != null && completedKeys.contains(t.groupCode))) {
            return false;
          }
          if (assignedIds.contains(t.orderId) ||
              assignedNums.contains(t.orderNumber) ||
              (t.groupCode != null && assignedNums.contains(t.groupCode))) {
            return false;
          }
          if (t.isBatch && t.stops.any((s) =>
              completedKeys.contains(s.orderId) ||
              completedKeys.contains(s.orderNumber) ||
              assignedIds.contains(s.orderId) ||
              assignedNums.contains(s.orderNumber))) {
            return false;
          }
          return true;
        }).toList();

        if (mounted) {
          final previousIds = _allTrips.map((t) => t.orderId).toSet();
          final newTrips = filteredTrips.where((t) => !previousIds.contains(t.orderId)).toList();

          if (newTrips.isNotEmpty || filteredTrips.length != _allTrips.length || filteredAssigned.length != _assignedTrips.length) {
            setState(() {
              _allTrips = filteredTrips;
              _assignedTrips = filteredAssigned;
              _earnings = earnings;
              _selectedTripOrderIds.retainAll(filteredTrips.map((t) => t.orderId));
            });

            if (newTrips.isNotEmpty && _incomingAlertTrip == null && _isOnline) {
              _triggerIncomingOrderAlert(newTrips.first);
            }
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        DeliveryApiService.instance.getRiderProfile(forceRefresh: true),
        DeliveryApiService.instance.getEarnings(forceRefresh: true),
        DeliveryApiService.instance.getAvailableTrips(
          maxRadiusKm: _selectedRadiusKm,
          vehicleType: _selectedVehicle,
          forceRefresh: true,
        ),
        DeliveryApiService.instance.getAssignedTrips(),
        DeliveryApiService.instance.getCompletedTrips(),
      ]);

      final trips = results[2] as List<DeliveryTrip>;
      final assigned = results[3] as List<DeliveryTrip>;
      final completed = results[4] as List<Map<String, dynamic>>;

      final completedKeys = <dynamic>{};
      for (final c in completed) {
        if (c['orderId'] != null) completedKeys.add(c['orderId']);
        if (c['orderNumber'] != null) completedKeys.add(c['orderNumber']);
        if (c['groupCode'] != null) completedKeys.add(c['groupCode']);
        if (c['groupId'] != null) completedKeys.add(c['groupId']);
        if (c['stops'] is List) {
          for (final s in (c['stops'] as List)) {
            if (s is Map) {
              if (s['orderId'] != null) completedKeys.add(s['orderId']);
              if (s['orderNumber'] != null) completedKeys.add(s['orderNumber']);
            }
          }
        }
      }

      final filteredAssigned = _filterActiveAssignedTrips(assigned, completedKeys);

      final assignedIds = filteredAssigned.map((a) => a.orderId).toSet();
      final assignedNums = filteredAssigned.map((a) => a.orderNumber).toSet();
      for (var a in filteredAssigned) {
        assignedIds.addAll(a.stops.map((s) => s.orderId));
        assignedNums.addAll(a.stops.map((s) => s.orderNumber));
      }

      final filteredTrips = trips.where((t) {
        if (completedKeys.contains(t.orderId) ||
            completedKeys.contains(t.orderNumber) ||
            (t.groupCode != null && completedKeys.contains(t.groupCode))) {
          return false;
        }
        if (assignedIds.contains(t.orderId) ||
            assignedNums.contains(t.orderNumber) ||
            (t.groupCode != null && assignedNums.contains(t.groupCode))) {
          return false;
        }
        if (t.isBatch && t.stops.any((s) =>
            completedKeys.contains(s.orderId) ||
            completedKeys.contains(s.orderNumber) ||
            assignedIds.contains(s.orderId) ||
            assignedNums.contains(s.orderNumber))) {
          return false;
        }
        return true;
      }).toList();

      if (mounted) {
        setState(() {
          _profile = results[0] as RiderProfile;
          _isOnline = _profile?.isOnline ?? true;
          _earnings = results[1] as RiderEarnings;
          _allTrips = filteredTrips;
          _assignedTrips = filteredAssigned;
          _selectedTripOrderIds.retainAll(filteredTrips.map((t) => t.orderId));
          _isLoading = false;
        });

        if (!_hasAutoResumedActiveTrip && filteredAssigned.isNotEmpty) {
          _hasAutoResumedActiveTrip = true;
          final activeTrip = filteredAssigned.first;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActiveTripScreen(
                    trip: activeTrip,
                    onTripCompleted: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      DeliveryApiService.instance.invalidateCache();
                      _loadDashboardData();
                    },
                  ),
                ),
              ).then((_) {
                DeliveryApiService.instance.invalidateCache();
                _loadDashboardData();
              });
            }
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _triggerIncomingOrderAlert(DeliveryTrip trip) {
    if (_isAutoAccept) {
      _acceptOrder(trip);
      return;
    }

    setState(() {
      _incomingAlertTrip = trip;
      _alertCountdown = 30;
    });

    _alertTimer?.cancel();
    _alertTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_alertCountdown > 1) {
        setState(() => _alertCountdown--);
      } else {
        timer.cancel();
        setState(() => _incomingAlertTrip = null);
      }
    });
  }

  Future<void> _toggleDuty(bool val) async {
    setState(() {
      _isOnline = val;
      if (!val) {
        _incomingAlertTrip = null;
        _alertTimer?.cancel();
      }
    });
    await DeliveryApiService.instance.updateOnlineStatus(val);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(val ? '🟢 YOU ARE NOW ONLINE - Scanning nearby 5km clusters' : '🔴 YOU ARE NOW OFFLINE - Break Mode Active'),
        backgroundColor: val ? const Color(0xFF1E8449) : const Color(0xFF756D69),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _acceptOrder(DeliveryTrip trip) async {
    _alertTimer?.cancel();
    final batchIds = trip.isBatch ? trip.stops.map((s) => s.orderId).toSet() : <int>{};
    final batchNums = trip.isBatch ? trip.stops.map((s) => s.orderNumber).toSet() : <String>{};

    setState(() {
      _incomingAlertTrip = null;
      _selectedTripOrderIds.remove(trip.orderId);
      _allTrips.removeWhere((t) =>
          t.orderId == trip.orderId ||
          t.orderNumber == trip.orderNumber ||
          (trip.isBatch && (batchIds.contains(t.orderId) || batchNums.contains(t.orderNumber))));
    });

    final success = (trip.isBatch && trip.stops.isNotEmpty)
        ? await DeliveryApiService.instance.acceptGroupTrip(
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
          )
        : await DeliveryApiService.instance.acceptTrip(
            trip.orderId,
            deliveryFee: trip.deliveryFee,
            surgeBonus: trip.surgeBonus,
            heavyBagBonus: trip.heavyBagBonus,
            legType: trip.legType,
          );
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Trip #${trip.orderNumber} Accepted! Heading to Mill.'),
          backgroundColor: const Color(0xFF1E8449),
        ),
      );

      if (widget.onTripAccepted != null) {
        widget.onTripAccepted!(trip);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActiveTripScreen(
              trip: trip,
              onTripCompleted: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                _loadDashboardData();
              },
            ),
          ),
        ).then((_) => _loadDashboardData());
      }
    }
  }

  Future<void> _acceptCustomBatch(List<DeliveryTrip> selectedTrips) async {
    if (selectedTrips.isEmpty) return;
    if (selectedTrips.length == 1) {
      return _acceptOrder(selectedTrips.first);
    }

    _alertTimer?.cancel();
    final selectedIds = selectedTrips.map((t) => t.orderId).toSet();
    final selectedNums = selectedTrips.map((t) => t.orderNumber).toSet();

    // Combine stops from all selected trips
    final List<DeliveryTripStop> allStops = [];
    for (final trip in selectedTrips) {
      if (trip.stops.isNotEmpty) {
        allStops.addAll(trip.stops);
      } else {
        allStops.add(DeliveryTripStop(
          orderId: trip.orderId,
          orderNumber: trip.orderNumber,
          customerName: trip.customerName,
          customerPhone: trip.customerPhone,
          deliveryAddress: trip.deliveryAddress,
          homePickupAddress: trip.homePickupAddress,
          homePickupLandmark: trip.homePickupLandmark,
          homePickupInstructions: trip.homePickupInstructions,
          isHomeGrainPickup: trip.isLeg1GrainPickup,
          quantityKg: trip.quantityKg,
          grainTypeName: trip.grainTypeName,
          deliveryOtp: trip.deliveryOtp,
          pickupPin: trip.pickupPin,
          barcodeNumber: trip.barcodeNumber,
          distanceKm: trip.distanceKm,
          customerNotes: trip.customerNotes,
          orderPayout: trip.deliveryFee,
        ));
      }
    }

    final totalPayout = selectedTrips.fold(0.0, (sum, t) => sum + t.deliveryFee);
    final totalQuantity = selectedTrips.fold(0.0, (sum, t) => sum + t.quantityKg);
    final totalSurge = selectedTrips.fold(0.0, (sum, t) => sum + t.surgeBonus);
    final totalHeavy = selectedTrips.fold(0.0, (sum, t) => sum + t.heavyBagBonus);
    final primary = selectedTrips.first;

    final timestampStr = DateTime.now().millisecondsSinceEpoch.toString();
    final groupSuffix = timestampStr.length > 5 ? timestampStr.substring(timestampStr.length - 5) : timestampStr;
    final groupCode = '#HD-GRP-${selectedTrips.length}X-$groupSuffix';

    final groupedTrip = DeliveryTrip(
      orderId: primary.orderId,
      orderNumber: groupCode,
      customerName: selectedTrips.map((t) => t.customerName).toSet().join(' & '),
      customerPhone: primary.customerPhone,
      millName: primary.millName,
      millAddress: primary.millAddress,
      millPhone: primary.millPhone,
      deliveryAddress: selectedTrips.map((t) => t.deliveryAddress).join(' • '),
      homePickupAddress: selectedTrips.map((t) => t.homePickupAddress).join(' • '),
      homePickupLandmark: primary.homePickupLandmark,
      homePickupInstructions: primary.homePickupInstructions,
      isHomeGrainPickup: selectedTrips.any((t) => t.isLeg1GrainPickup),
      legType: selectedTrips.every((t) => t.isLeg1GrainPickup)
          ? 'LEG_1_GRAIN_PICKUP'
          : (selectedTrips.every((t) => t.isLeg2FlourDelivery) ? 'LEG_2_FLOUR_DELIVERY' : 'MULTI_STOP_BATCH'),
      tripBadge: '⚡ ${selectedTrips.length}x Custom Grouped Batch',
      originTitle: 'Multi-Stop Pickup',
      destinationTitle: 'Multi-Stop Drop',
      quantityKg: totalQuantity,
      grainTypeName: selectedTrips.map((t) => t.grainTypeName).join(', '),
      deliveryFee: totalPayout,
      distanceKm: selectedTrips.fold(0.0, (sum, t) => sum + t.distanceKm),
      status: 'ASSIGNED',
      pickupPin: primary.pickupPin,
      deliveryOtp: primary.deliveryOtp,
      barcodeNumber: 'HD-BAG-GRP-$groupSuffix',
      isBatch: true,
      batchOrderCount: selectedTrips.length,
      surgeBonus: totalSurge,
      heavyBagBonus: totalHeavy,
      estimatedMins: 20 + (selectedTrips.length * 8),
      groupCode: groupCode,
      stops: allStops,
    );

    setState(() {
      _incomingAlertTrip = null;
      _allTrips.removeWhere((t) => selectedIds.contains(t.orderId) || selectedNums.contains(t.orderNumber));
      _selectedTripOrderIds.clear();
    });

    final stopsPayload = allStops.map((s) => {
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
    }).toList();

    final success = await DeliveryApiService.instance.acceptGroupTrip(
      groupCode: groupCode,
      orderIds: selectedTrips.map((t) => t.orderId).toList(),
      stops: stopsPayload,
      totalFee: totalPayout,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Grouped Batch $groupCode Accepted (${selectedTrips.length} Stops • ₹${totalPayout.toStringAsFixed(0)})!'),
          backgroundColor: const Color(0xFF1E8449),
          duration: const Duration(seconds: 3),
        ),
      );

      if (widget.onTripAccepted != null) {
        widget.onTripAccepted!(groupedTrip);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActiveTripScreen(
              trip: groupedTrip,
              onTripCompleted: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                _loadDashboardData();
              },
            ),
          ),
        ).then((_) => _loadDashboardData());
      }
    }
  }

  Widget _buildStickyBatchActionBar() {
    final selectedTrips = _allTrips.where((t) => _selectedTripOrderIds.contains(t.orderId)).toList();
    if (selectedTrips.isEmpty) return const SizedBox.shrink();

    final count = selectedTrips.length;
    final totalPayout = selectedTrips.fold(0.0, (sum, t) => sum + t.deliveryFee);
    final totalWeight = selectedTrips.fold(0.0, (sum, t) => sum + t.quantityKg);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC0392B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.layers_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            count > 1 ? '$count Orders Selected (Batch)' : '1 Order Selected',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF334155),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${totalWeight.toStringAsFixed(totalWeight.truncateToDouble() == totalWeight ? 0 : 1)} kg',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFFF1F5F9),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        count > 1
                            ? 'Ready to accept combined multi-stop run'
                            : 'Select 1 more order to bundle into a group run',
                        style: GoogleFonts.plusJakartaSans(
                          color: count > 1 ? const Color(0xFF94A3B8) : const Color(0xFFF59E0B),
                          fontSize: 11,
                          fontWeight: count > 1 ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TOTAL PAY',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF94A3B8),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '₹${totalPayout.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF4ADE80),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _clearSelectedTrips,
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                  tooltip: 'Clear selection',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (count > 1) {
                    _acceptCustomBatch(selectedTrips);
                  } else {
                    _acceptOrder(selectedTrips.first);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: count > 1 ? const Color(0xFFC0392B) : const Color(0xFF1E8449),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
                icon: Icon(count > 1 ? Icons.alt_route_rounded : Icons.navigation_rounded, size: 18, color: Colors.white),
                label: Text(
                  count > 1
                      ? 'ACCEPT GROUPED BATCH ($count ORDERS • ₹${totalPayout.toStringAsFixed(0)})'
                      : 'ACCEPT SINGLE ORDER (₹${totalPayout.toStringAsFixed(0)})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DeliveryTrip> get _baseAvailableTrips {
    return _allTrips.where((t) {
      if (t.distanceKm > _selectedRadiusKm) return false;
      if (_selectedVehicle == 'BIKE_EV' && t.vehicleTypeAllowed == 'CAR_VAN') return false;
      if (_selectedVehicle == 'BIKE_EV' && t.quantityKg > 15.0) return false;
      return true;
    }).toList();
  }

  List<DeliveryTrip> get _filteredTrips {
    final baseTrips = _baseAvailableTrips;
    if (_selectedFilter == 'HomeToMill') {
      return baseTrips.where((t) => t.isLeg1GrainPickup).toList();
    } else if (_selectedFilter == 'MillToHome') {
      return baseTrips.where((t) => t.isLeg2FlourDelivery).toList();
    }
    return baseTrips;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: _selectedTripOrderIds.isEmpty ? null : _buildStickyBatchActionBar(),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryTerracotta))
            : RefreshIndicator(
                color: AppTheme.primaryTerracotta,
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Rider info & SOS support
                      _buildHeader(),
                      const SizedBox(height: 16),

                      // Duty Status Banner with Auto-Accept toggle
                      _buildDutyStatusCard(),
                      const SizedBox(height: 16),

                      // Vehicle Mode & Strict 5.0 km Geo-Fence Radius Selector
                      _buildVehicleAndRadiusSelector(),
                      const SizedBox(height: 16),

                      // Live Interactive 5 km Radar Map & Concentric Distance Canvas
                      _buildInteractive5KmRadarMap(),
                      const SizedBox(height: 16),


                      // Incoming Order Broadcast Alert Modal (if active)
                      if (_incomingAlertTrip != null) ...[
                        _buildIncomingOrderModal(_incomingAlertTrip!),
                        const SizedBox(height: 18),
                      ],

                      // Rider Shift & Vehicle Status HUD
                      _buildRiderShiftHUD(),
                      const SizedBox(height: 20),

                      // Trip Filters Bar
                      _buildFilterChips(),
                      const SizedBox(height: 16),

                      // Available Trips Radar Section (Multi-Order Selectable)
                      _buildAvailableTripsSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (widget.onOpenDrawer != null) ...[
              InkWell(
                onTap: widget.onOpenDrawer,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.menu_rounded, color: AppTheme.textPrimary, size: 22),
                ),
              ),
              const SizedBox(width: 10),
            ],
            InkWell(
              onTap: widget.onOpenDrawer,
              borderRadius: BorderRadius.circular(25),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8C4A3E), Color(0xFF5A2E25)],
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 26),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _profile?.name ?? 'Vikram Delivery Agent',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFF6AD55)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 12, color: Color(0xFFB7791F)),
                          const SizedBox(width: 2),
                          Text(
                            '${_profile?.rating ?? 4.9}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFB7791F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_profile?.vehicleType ?? 'Hero Electric Nyx'} • ${_profile?.vehicleNumber ?? 'GJ-01-AB-4821'}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),

        // 24/7 Rider Helpline SOS
        InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: [
                    const Icon(Icons.headset_mic_rounded, color: AppTheme.primaryTerracotta),
                    const SizedBox(width: 8),
                    Text('Rider Support Hub', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Emergency & Roadside Help:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('📞 Toll-Free Helpline: 1800-437-3667', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                    Text('💬 Instant Dispatcher Chat available 24x7', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 12),
                    Text('📍 Current GPS Ping: Ellisbridge Central Cluster', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF1E8449), fontWeight: FontWeight.w600)),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Close', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🚨 Emergency SOS Dispatched to HerDoor Safety Desk!')),
                      );
                    },
                    icon: const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.white),
                    label: Text('Trigger SOS', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC0392B)),
                  ),
                ],
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 16, color: Color(0xFFC0392B)),
                const SizedBox(width: 4),
                Text(
                  'SOS Help',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFC0392B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDutyStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isOnline ? const Color(0xFF1E8449) : const Color(0xFF3E3A39),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (_isOnline ? const Color(0xFF1E8449) : Colors.black).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isOnline ? const Color(0xFF2ECC71) : Colors.grey,
                      boxShadow: _isOnline
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2ECC71).withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 3,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isOnline ? 'RIDER ON DUTY (ONLINE)' : 'DUTY OFF (BREAK MODE)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _isOnline
                            ? 'Scanning nearby chakki mills & customer drops'
                            : 'Toggle switch to start receiving delivery requests',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              Switch(
                value: _isOnline,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF2ECC71),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey[600],
                onChanged: _toggleDuty,
              ),
            ],
          ),
          if (_isOnline) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flash_auto_rounded, size: 16, color: Color(0xFFF1C40F)),
                      const SizedBox(width: 6),
                      Text(
                        _isOnline
                            ? (_assignedTrips.isNotEmpty ? 'DUTY ACTIVE • ${_assignedTrips.length} RUN IN PROGRESS' : 'DUTY ACTIVE • READY FOR RUNS')
                            : 'OFFLINE • GO ONLINE TO ACCEPT TRIPS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _isAutoAccept,
                    activeThumbColor: const Color(0xFFF1C40F),
                    activeTrackColor: Colors.white.withValues(alpha: 0.4),
                    inactiveThumbColor: Colors.white70,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                    onChanged: (val) {
                      setState(() => _isAutoAccept = val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? '⚡ Auto-Accept Active: Highest paying trips accepted automatically' : 'Hands-free Auto-Accept disabled'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRiderShiftHUD() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Shift Tracker",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.battery_charging_full_rounded, size: 16, color: Color(0xFF1E8449)),
                  const SizedBox(width: 4),
                  Text(
                    'EV 84% (~48 km)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E8449),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  '₹${_earnings?.todayEarnings.toStringAsFixed(0) ?? '525'}',
                  'Earned Today',
                  Icons.account_balance_wallet_outlined,
                  const Color(0xFF1E8449),
                ),
              ),
              Container(width: 1, height: 38, color: AppTheme.borderLight),
              Expanded(
                child: _buildMetricTile(
                  '${_earnings?.todayTrips ?? 7}',
                  'Trips Done',
                  Icons.sports_motorsports_outlined,
                  AppTheme.primaryTerracotta,
                ),
              ),
              Container(width: 1, height: 38, color: AppTheme.borderLight),
              Expanded(
                child: _buildMetricTile(
                  '18.4 km',
                  'Distance',
                  Icons.route_outlined,
                  const Color(0xFF2980B9),
                ),
              ),
              Container(width: 1, height: 38, color: AppTheme.borderLight),
              Expanded(
                child: _buildMetricTile(
                  '4h 15m',
                  'On Road',
                  Icons.timer_outlined,
                  const Color(0xFF6E5616),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Daily Bonus Quest
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, size: 16, color: Color(0xFFD4AC0D)),
                  const SizedBox(width: 6),
                  Text(
                    'Daily Quest: Complete 8 trips for +₹150 Bonus',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF9A7D0A),
                    ),
                  ),
                ],
              ),
              Text(
                '7/8 Done (1 left)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF9A7D0A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: 7 / 8,
            backgroundColor: const Color(0xFFF9E79F).withValues(alpha: 0.4),
            color: const Color(0xFFD4AC0D),
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final baseTrips = _baseAvailableTrips;
    final homeToMillCount = baseTrips.where((t) => t.isLeg1GrainPickup).length;
    final millToHomeCount = baseTrips.where((t) => t.isLeg2FlourDelivery).length;
    final totalCount = baseTrips.length;

    final filters = [
      {'key': 'All', 'label': 'All Orders ($totalCount)'},
      {'key': 'HomeToMill', 'label': '🌾 Home ➔ Mill ($homeToMillCount)'},
      {'key': 'MillToHome', 'label': '🍞 Mill ➔ Home ($millToHomeCount)'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                f['label']!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              selected: isSelected,
              selectedColor: AppTheme.primaryTerracotta,
              backgroundColor: Colors.white,
              side: BorderSide(color: isSelected ? AppTheme.primaryTerracotta : AppTheme.borderLight),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val) setState(() => _selectedFilter = f['key']!);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIncomingOrderModal(DeliveryTrip trip) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF8C4A3E), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8C4A3E).withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 8),
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
                      color: const Color(0xFFFDEDEC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flash_on_rounded, size: 14, color: Color(0xFFC0392B)),
                        const SizedBox(width: 4),
                        Text(
                          trip.isBatch ? 'BATCH DISPATCH ALERT' : 'EXCLUSIVE RIDER BROADCAST',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFC0392B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Countdown Ring
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF8C4A3E),
                ),
                child: Text(
                  '$_alertCountdown',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Payout & Distance Banner
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${trip.deliveryFee.toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1E8449),
                    ),
                  ),
                  Text(
                    trip.isBatch
                        ? 'Stacked 2 Orders Payout (Incl. Surge)'
                        : 'Trip Pay (Incl. +₹${trip.surgeBonus.toStringAsFixed(0)} Surge)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3ECE1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${trip.distanceKm} km • ~${trip.estimatedMins} mins',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6E5616),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Step 1: Pickup Location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                trip.isLeg1GrainPickup ? Icons.home_rounded : Icons.storefront_rounded,
                size: 20,
                color: trip.isLeg1GrainPickup ? const Color(0xFF0369A1) : AppTheme.primaryTerracotta,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.isLeg1GrainPickup ? '1. PICKUP GRAIN: ${trip.customerName}' : '1. PICKUP FLOUR: ${trip.millName}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text(
                      '${trip.effectivePickupLocation} (${trip.productBags.length > 1 ? "${trip.productBags.length} Products" : (trip.productBags.isNotEmpty ? trip.productBags.first.unitText : "${trip.quantityKg} kg")})',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Step 2: Drop Location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                trip.isLeg1GrainPickup ? Icons.storefront_rounded : Icons.location_on_rounded,
                size: 20,
                color: trip.isLeg1GrainPickup ? const Color(0xFF6E5616) : const Color(0xFF1E8449),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.isLeg1GrainPickup ? '2. DROP AT MILL: ${trip.millName}' : '2. DELIVER TO: ${trip.customerName}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text(
                      trip.effectiveDeliveryLocation,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _alertTimer?.cancel();
                    setState(() => _incomingAlertTrip = null);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppTheme.borderLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Decline',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => _acceptOrder(trip),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E8449),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'ACCEPT & NAVIGATE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleAndRadiusSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderLight),
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
                  const Icon(Icons.commute_rounded, color: AppTheme.primaryTerracotta, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Active Transport Vehicle Mode',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2ECC71).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1E8449)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '5.0 km Geo-Fence',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E8449),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Vehicle Type Selector Buttons
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedVehicle = 'CAR_VAN');
                    _loadDashboardData();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: _selectedVehicle == 'CAR_VAN' ? const Color(0xFFFAF3EB) : const Color(0xFFF9F7F5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedVehicle == 'CAR_VAN' ? AppTheme.primaryTerracotta : AppTheme.borderLight,
                        width: _selectedVehicle == 'CAR_VAN' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('🚗', style: TextStyle(fontSize: 20)),
                            if (_selectedVehicle == 'CAR_VAN')
                              const Icon(Icons.check_circle_rounded, color: AppTheme.primaryTerracotta, size: 16),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Car / Delivery Van',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: _selectedVehicle == 'CAR_VAN' ? AppTheme.primaryTerracotta : AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Max 60 kg • Multi-Order Batching',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedVehicle = 'BIKE_EV');
                    _loadDashboardData();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: _selectedVehicle == 'BIKE_EV' ? const Color(0xFFFAF3EB) : const Color(0xFFF9F7F5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedVehicle == 'BIKE_EV' ? AppTheme.primaryTerracotta : AppTheme.borderLight,
                        width: _selectedVehicle == 'BIKE_EV' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('🛵', style: TextStyle(fontSize: 20)),
                            if (_selectedVehicle == 'BIKE_EV')
                              const Icon(Icons.check_circle_rounded, color: AppTheme.primaryTerracotta, size: 16),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Bike / EV Scooter',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: _selectedVehicle == 'BIKE_EV' ? AppTheme.primaryTerracotta : AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Max 15 kg • 1-2 Quick Deliveries',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 5km Strict Radius Info Note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3ECE1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.radar_rounded, color: Color(0xFF6E5616), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '📍 Only showing orders within 5.0 km from your live GPS location. All stops sequenced on 1 map route.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6E5616),
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

  Widget _buildInteractive5KmRadarMap() {
    final trips = _filteredTrips;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E242B),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                  const Icon(Icons.map_rounded, color: Color(0xFF2ECC71), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Live 5.0 km Radar Map View',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${trips.length} Runs Available',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2ECC71),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Custom Radar Canvas
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 190,
              width: double.infinity,
              color: const Color(0xFF14181D),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated Pulsing Concentric Range Rings (1.5km, 3km, 5km)
                  AnimatedBuilder(
                    animation: _radarPulseController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(double.infinity, 190),
                        painter: _RadarGridPainter(pulseValue: _radarPulseController.value),
                      );
                    },
                  ),

                  // Concentric distance tags
                  Positioned(
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Outer Boundary: 5.0 km Max Range',
                        style: GoogleFonts.plusJakartaSans(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // Center Driver Location Node
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1E8449),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2ECC71).withValues(alpha: 0.8),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          _selectedVehicle == 'CAR_VAN' ? '🚗' : '🛵',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'YOU (Ellisbridge)',
                          style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                  // Nearby Trip Cluster Markers on Map
                  ...trips.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final trip = entry.value;
                    // Positions relative to radar center
                    final double radiusNorm = (trip.distanceKm / 5.0).clamp(0.25, 0.90);
                    final double posX = 60 * radiusNorm * (idx % 2 == 0 ? 1.4 : -1.4);
                    final double posY = 55 * radiusNorm * (idx > 1 ? 1 : -1);

                    final isHovered = _hoveredMapOrderId == trip.orderId;

                    return Transform.translate(
                      offset: Offset(posX, posY),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _hoveredMapOrderId = trip.orderId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Selected #${trip.orderNumber} • ${trip.distanceKm} km (${trip.isBatch ? "${trip.stops.length} Stops Grouped" : "Single Drop"})'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: trip.isBatch
                                ? const Color(0xFFC0392B)
                                : isHovered
                                    ? const Color(0xFF2980B9)
                                    : const Color(0xFF1E8449),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: (trip.isBatch ? const Color(0xFFC0392B) : const Color(0xFF1E8449)).withValues(alpha: 0.6),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                trip.isBatch ? Icons.layers_rounded : Icons.store_rounded,
                                size: 11,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${trip.distanceKm} km • ₹${trip.deliveryFee.toStringAsFixed(0)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Map legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFC0392B))),
                  const SizedBox(width: 4),
                  Text('Grouped Multi-Stop Trip', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.white70)),
                ],
              ),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1E8449))),
                  const SizedBox(width: 4),
                  Text('Single Express Drop', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.white70)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.center_focus_strong_rounded, size: 10, color: Color(0xFF2ECC71)),
                  const SizedBox(width: 4),
                  Text('≤ 5 km Radius', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.white70)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTripPersistentBanner() {
    if (_assignedTrips.isEmpty) return const SizedBox.shrink();
    final activeTrip = _assignedTrips.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E8449),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E8449).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RUN IN PROGRESS • ${activeTrip.orderNumber}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activeTrip.resolvedLegBadge,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActiveTripScreen(
                    trip: activeTrip,
                    onTripCompleted: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      _loadDashboardData();
                    },
                  ),
                ),
              ).then((_) => _loadDashboardData());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1E8449),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              'RESUME ➔',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableTripsSection() {
    final trips = _filteredTrips;
    final allSelected = trips.isNotEmpty && _selectedTripOrderIds.containsAll(trips.map((t) => t.orderId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildActiveTripPersistentBanner(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (trips.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Select multiple orders to create a custom batch',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (trips.length > 1)
              InkWell(
                onTap: _selectAllFilteredTrips,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: allSelected ? const Color(0xFFFDEDEC) : const Color(0xFFF3ECE1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: allSelected ? const Color(0xFFE74C3C) : const Color(0xFFD4AF37),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        allSelected ? Icons.deselect_rounded : Icons.checklist_rounded,
                        size: 14,
                        color: allSelected ? const Color(0xFFC0392B) : const Color(0xFF6E5616),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        allSelected ? 'Deselect All' : '⚡ Group All (${trips.length})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: allSelected ? const Color(0xFFC0392B) : const Color(0xFF6E5616),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_isOnline)
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2ECC71)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Live 5km Radar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E8449),
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Custom Grouped Batch Summary Banner if items selected
        if (_selectedTripOrderIds.isNotEmpty) ...[
          Builder(builder: (context) {
            final selectedTrips = _allTrips.where((t) => _selectedTripOrderIds.contains(t.orderId)).toList();
            final count = selectedTrips.length;
            final totalPayout = selectedTrips.fold(0.0, (sum, t) => sum + t.deliveryFee);
            final totalWeight = selectedTrips.fold(0.0, (sum, t) => sum + t.quantityKg);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
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
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.alt_route_rounded, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            count > 1 ? '⚡ Custom Grouped Batch ($count Orders)' : '⚡ 1 Order Selected for Group',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF78350F),
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _clearSelectedTrips,
                        icon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFB45309)),
                        label: Text(
                          'Clear',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Weight: ${totalWeight.toStringAsFixed(totalWeight.truncateToDouble() == totalWeight ? 0 : 1)} kg  •  $count Stops',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                      Text(
                        'Combined: ₹${totalPayout.toStringAsFixed(0)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1E8449),
                        ),
                      ),
                    ],
                  ),
                  if (count > 1) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: () => _acceptCustomBatch(selectedTrips),
                        icon: const Icon(Icons.bolt_rounded, size: 18, color: Colors.white),
                        label: Text(
                          'ACCEPT BATCH ($count ORDERS • ₹${totalPayout.toStringAsFixed(0)})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC0392B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Text(
                      '👉 Select another order below to bundle them together into 1 multi-stop trip!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],

        if (!_isOnline)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              children: [
                const Icon(Icons.bedtime_outlined, size: 36, color: AppTheme.textMuted),
                const SizedBox(height: 8),
                Text(
                  'You are currently Offline',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Turn on duty toggle above to start receiving fresh flour orders within 5km.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else if (trips.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              children: [
                const Icon(Icons.radar_rounded, size: 36, color: AppTheme.textMuted),
                const SizedBox(height: 8),
                Text(
                  _selectedFilter == 'HomeToMill'
                      ? 'No Home ➔ Mill grain pickup orders nearby.'
                      : _selectedFilter == 'MillToHome'
                          ? 'No Mill ➔ Home flour delivery orders nearby.'
                          : 'No orders currently within 5.0 km for $_selectedVehicle.',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedFilter != 'All'
                      ? 'Try switching to "All Orders" or expanding your radius.'
                      : 'Radar is actively searching nearby chakki mills...',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: trips.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final trip = trips[index];
              return _buildTripCard(trip);
            },
          ),
      ],
    );
  }

  Widget _buildTripCard(DeliveryTrip trip) {
    final isGrouped = trip.stops.length > 1;
    final isSelected = _selectedTripOrderIds.contains(trip.orderId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFFBF9) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFC0392B)
              : (isGrouped ? const Color(0xFFC0392B) : AppTheme.borderLight),
          width: isSelected ? 2.2 : (isGrouped ? 1.8 : 1),
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFFC0392B).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isSelected ? 14 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges & Total Pay & Multi-Select Checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox Toggle for custom grouping
              InkWell(
                onTap: () => _toggleTripSelection(trip.orderId),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFC0392B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF962D22) : const Color(0xFFCBD5E1),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        size: 15,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSelected ? 'Selected' : 'Group',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Badges in Wrap so they never overflow
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (isGrouped)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDEDEC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE74C3C)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.layers_rounded, size: 12, color: Color(0xFFC0392B)),
                            const SizedBox(width: 4),
                            Text(
                              '${trip.stops.length}x GROUPED',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFC0392B),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3ECE1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          trip.orderNumber,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF6E5616),
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: trip.isLeg1GrainPickup ? const Color(0xFFE0F2FE) : const Color(0xFFE8F8F5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: trip.isLeg1GrainPickup ? const Color(0xFF7DD3FC) : const Color(0xFFA3E4D7),
                        ),
                      ),
                      child: Text(
                        trip.resolvedLegBadge,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: trip.isLeg1GrainPickup ? const Color(0xFF0369A1) : const Color(0xFF1E8449),
                        ),
                      ),
                    ),
                    if (trip.surgeBonus > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDEDEC),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+₹${trip.surgeBonus.toStringAsFixed(0)} Surge',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFC0392B),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Payout
              Text(
                '₹${trip.deliveryFee.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E8449),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Grain items summary & weight
          Row(
            children: [
              Icon(
                trip.isLeg1GrainPickup ? Icons.grass_rounded : Icons.inventory_2_outlined,
                size: 16,
                color: AppTheme.primaryTerracotta,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  trip.productSummaryHeader,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trip.heavyBagBonus > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8F5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+₹${trip.heavyBagBonus.toStringAsFixed(0)} Heavy Incentive',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF16A085),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (trip.productBags.length > 1) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: trip.productBags.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final bag = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3ECE1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5D5BC)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.qr_code_2_rounded, size: 12, color: Color(0xFF6E5616)),
                        const SizedBox(width: 4),
                        Text(
                          '${idx + 1}. ${bag.productName} • ${bag.unitText}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5C4710),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Step 1 Location (Origin: Customer Home on Leg 1, Flour Mill on Leg 2)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: trip.isLeg1GrainPickup ? const Color(0xFFF0F9FF) : const Color(0xFFFAF6F0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: trip.isLeg1GrainPickup ? const Color(0xFFBAE6FD) : const Color(0xFFECE4D9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            trip.isLeg1GrainPickup ? Icons.home_rounded : Icons.storefront_rounded,
                            size: 16,
                            color: trip.isLeg1GrainPickup ? const Color(0xFF0369A1) : const Color(0xFF6E5616),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              trip.isLeg1GrainPickup
                                  ? '1. PICK UP RAW GRAIN FROM HOME:'
                                  : '1. PICK UP FRESH FLOUR FROM MILL:',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: trip.isLeg1GrainPickup ? const Color(0xFF0369A1) : const Color(0xFF6E5616),
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: trip.isLeg1GrainPickup ? const Color(0xFFE0F2FE) : const Color(0xFFF3ECE1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        trip.isLeg1GrainPickup ? trip.customerName : trip.millName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: trip.isLeg1GrainPickup ? const Color(0xFF0284C7) : const Color(0xFF6E5616),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  trip.isLeg1GrainPickup ? trip.homePickupAddress : trip.millAddress,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                if (trip.homePickupInstructions != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    '📝 Instructions: "${trip.homePickupInstructions}"',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF475569), fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Step 2 Location (Destination: Flour Mill on Leg 1, Customer Doorstep on Leg 2)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: trip.isLeg1GrainPickup ? const Color(0xFFFAF6F0) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: trip.isLeg1GrainPickup ? const Color(0xFFECE4D9) : const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            trip.isLeg1GrainPickup ? Icons.storefront_rounded : Icons.location_on_rounded,
                            size: 16,
                            color: trip.isLeg1GrainPickup ? const Color(0xFF6E5616) : const Color(0xFF1E8449),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              trip.isLeg1GrainPickup
                                  ? '2. DROP RAW GRAIN AT MILL (FOR GRINDING):'
                                  : '2. DELIVER FLOUR TO CUSTOMER HOME:',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: trip.isLeg1GrainPickup ? const Color(0xFF6E5616) : const Color(0xFF1E8449),
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: trip.isLeg1GrainPickup ? const Color(0xFFF3ECE1) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        trip.isLeg1GrainPickup ? trip.millName : trip.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: trip.isLeg1GrainPickup ? const Color(0xFF6E5616) : const Color(0xFF15803D),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  trip.isLeg1GrainPickup ? trip.millAddress : trip.deliveryAddress,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
              ],
            ),
          ),

          // For Grouped Runs: show list of multiple stops
          if (isGrouped && trip.stops.length > 1) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Multi-Stop Route Details (${trip.stops.length} Drops):',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  ...trip.stops.asMap().entries.map((entry) {
                    final stopIdx = entry.key + 1;
                    final stop = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF1E8449),
                            ),
                            child: Text(
                              '$stopIdx',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stop $stopIdx: ${stop.customerName} (${stop.productBags.length > 1 ? "${stop.productBags.length} Products" : (stop.productBags.isNotEmpty ? stop.productBags.first.unitText : "${stop.quantityKg} kg")})',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '📍 Pickup: ${trip.isLeg1GrainPickup ? stop.homePickupAddress : trip.millAddress}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: const Color(0xFF0284C7)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '🏡 Drop: ${trip.isLeg1GrainPickup ? trip.millAddress : stop.deliveryAddress}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: const Color(0xFF16A34A)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Accept Action Button: Full-width direct action or Dual Batch/Solo Actions
          if (isSelected && _selectedTripOrderIds.length >= 2) ...[
            Builder(builder: (context) {
              final selectedTrips = _allTrips.where((t) => _selectedTripOrderIds.contains(t.orderId)).toList();
              final totalBatchPayout = selectedTrips.fold(0.0, (s, t) => s + t.deliveryFee);

              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => _acceptCustomBatch(selectedTrips),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC0392B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.alt_route_rounded, size: 18, color: Colors.white),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'ACCEPT ${_selectedTripOrderIds.length} BATCH (₹${totalBatchPayout.toStringAsFixed(0)})',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => _acceptOrder(trip),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF1E8449), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'RUN SOLO',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E8449),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _acceptOrder(trip),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isGrouped ? const Color(0xFF8C4A3E) : const Color(0xFF1E8449),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isGrouped ? Icons.alt_route_rounded : Icons.navigation_rounded, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      isGrouped ? 'ACCEPT ${trip.stops.length}-STOP RUN' : 'ACCEPT RUN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RadarGridPainter extends CustomPainter {
  final double pulseValue;

  _RadarGridPainter({required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.height * 0.44;

    final gridPaint = Paint()
      ..color = const Color(0xFF2ECC71).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Concentric Range Rings (1.5km, 3.0km, 5.0km)
    canvas.drawCircle(center, maxRadius * 0.35, gridPaint);
    canvas.drawCircle(center, maxRadius * 0.70, gridPaint);
    canvas.drawCircle(center, maxRadius, gridPaint);

    // Crosshairs
    canvas.drawLine(Offset(center.dx - maxRadius, center.dy), Offset(center.dx + maxRadius, center.dy), gridPaint);
    canvas.drawLine(Offset(center.dx, center.dy - maxRadius), Offset(center.dx, center.dy + maxRadius), gridPaint);

    // Animated Pulsing Sweep Wave
    final pulseRadius = maxRadius * pulseValue;
    final pulsePaint = Paint()
      ..color = const Color(0xFF2ECC71).withValues(alpha: (1.0 - pulseValue) * 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, pulseRadius, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant _RadarGridPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}

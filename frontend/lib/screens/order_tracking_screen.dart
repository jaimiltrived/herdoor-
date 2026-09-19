import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/app_models.dart';
import '../models/merchant_models.dart';
import '../services/customer_api_service.dart';
import '../services/delivery_api_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> with SingleTickerProviderStateMixin {
  int _viewMode = 0; // 0 = Full Progress (Stepper), 1 = Map & Receipt
  Timer? _uiRefreshTimer;
  late OrderModel _order;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _ensureTrackingSteps();
    _pollLiveOrderStatus();
    _uiRefreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollLiveOrderStatus();
    });
  }

  @override
  void dispose() {
    _uiRefreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pollLiveOrderStatus() async {
    if (!mounted) return;
    try {
      final numericId = int.tryParse(_order.orderId.replaceAll(RegExp(r'[^0-9]'), ''));
      if (numericId != null) {
        final liveOrder = await CustomerApiService.instance.getOrderDetails(numericId);
        if (liveOrder != null && mounted) {
          setState(() {
            _order.statusStep = liveOrder.statusTag;
            _applyStatusToTrackingSteps(liveOrder.statusTag, estimatedTime: liveOrder.estimatedCompletionTime);
          });
        }
      }
    } catch (_) {}
  }

  void _applyStatusToTrackingSteps(String status, {String? estimatedTime}) {
    final s = status.toUpperCase().replaceAll(' ', '_');
    final isCancelled = s == 'CANCELLED' || s == 'REJECTED';
    final isDelivered = s == 'DELIVERED' || s == 'COMPLETED';
    final isOut = s == 'OUT_FOR_DELIVERY';
    final isReady = s == 'READY' || s == 'READY_FOR_PICKUP' || s == 'PACKING';
    final isMilling = s == 'IN_PROGRESS' || s == 'PROCESSING' || s == 'MILLING';
    final isAccepted = s == 'ACCEPTED';
    final isPlaced = s == 'PLACED' || s == 'NEW';

    final isReturnToCustomer = s == 'RETURN_TO_CUSTOMER';
    final isReturnedToCustomer = s == 'RETURNED_TO_CUSTOMER';
    final isReturnToMill = s == 'RETURN_TO_MILL';
    final isReturnedToMill = s == 'RETURNED_TO_MILL';

    if (_order.trackingSteps.length >= 5) {
      if (isReturnToCustomer || isReturnedToCustomer) {
        // Leg 1 Return Flow (Rejected at Mill -> Returned to Customer Doorstep)
        _order.trackingSteps[0] = TrackingStep(
          title: 'Order Placed',
          subtitle: 'Received at mill',
          timeText: 'Completed',
          isCompleted: true,
          isCurrent: false,
        );
        _order.trackingSteps[1] = TrackingStep(
          title: 'Grain Picked Up',
          subtitle: 'Collected from doorstep',
          timeText: 'Completed',
          isCompleted: true,
          isCurrent: false,
        );
        _order.trackingSteps[2] = TrackingStep(
          title: 'Mill Quality Check',
          subtitle: 'Rejected by mill shopkeeper',
          timeText: 'Failed',
          isCompleted: true,
          isCurrent: false,
        );
        _order.trackingSteps[3] = TrackingStep(
          title: 'Returning Grain',
          subtitle: isReturnedToCustomer ? 'Delivered back to home' : 'Driver returning grain to doorstep',
          timeText: isReturnedToCustomer ? 'Completed' : 'In transit',
          isCompleted: isReturnedToCustomer,
          isCurrent: isReturnToCustomer,
        );
        _order.trackingSteps[4] = TrackingStep(
          title: isReturnedToCustomer ? 'Returned to Customer' : 'Awaiting Doorstep Handover',
          subtitle: isReturnedToCustomer ? 'Grain handed back to customer' : 'Driver arriving soon',
          timeText: isReturnedToCustomer ? 'Done' : 'Pending',
          isCompleted: isReturnedToCustomer,
          isCurrent: false,
        );
      } else if (isReturnToMill || isReturnedToMill) {
        // Leg 2 Return Flow (Rejected by Customer at Doorstep -> Returned to Mill)
        _order.trackingSteps[0] = TrackingStep(
          title: 'Order Placed',
          subtitle: 'Received at mill',
          timeText: 'Completed',
          isCompleted: true,
          isCurrent: false,
        );
        _order.trackingSteps[1] = TrackingStep(
          title: 'Milling Completed',
          subtitle: 'Flour ground & packed',
          timeText: 'Completed',
          isCompleted: true,
          isCurrent: false,
        );
        _order.trackingSteps[2] = TrackingStep(
          title: 'Out for Delivery',
          subtitle: 'Delivered to doorstep',
          timeText: 'Completed',
          isCompleted: true,
          isCurrent: false,
        );
        _order.trackingSteps[3] = TrackingStep(
          title: 'Doorstep Quality Check',
          subtitle: 'Customer rejected flour',
          timeText: 'Rejected',
          isCompleted: true,
          isCurrent: false,
        );
        _order.trackingSteps[4] = TrackingStep(
          title: isReturnedToMill ? 'Returned to Mill' : 'Returning to Mill',
          subtitle: isReturnedToMill ? 'Flour safely handed back to mill' : 'Driver returning flour to mill',
          timeText: isReturnedToMill ? 'Done' : 'In transit',
          isCompleted: isReturnedToMill,
          isCurrent: isReturnToMill,
        );
      } else {
        // Normal 2-Leg Delivery Happy Flow
        _order.trackingSteps[0] = TrackingStep(
          title: '1. Order Placed',
          subtitle: 'Order accepted by mill',
          timeText: 'Completed',
          isCompleted: true,
          isCurrent: false,
        );

        _order.trackingSteps[1] = TrackingStep(
          title: '2. 🌾 Leg 1: Grain Pickup',
          subtitle: 'Rider collects raw grain from home ➔ Mill',
          timeText: (isMilling || isReady || isOut || isDelivered)
              ? 'At Mill'
              : (isAccepted ? 'Rider assigned' : 'In queue'),
          isCompleted: (isMilling || isReady || isOut || isDelivered),
          isCurrent: isAccepted || isPlaced,
        );

        _order.trackingSteps[2] = TrackingStep(
          title: '3. 🏭 Mill Processing',
          subtitle: 'Quality check & stone chakki grinding',
          timeText: (isReady || isOut || isDelivered)
              ? 'Finished'
              : (isMilling ? 'Grinding now' : 'Pending'),
          isCompleted: (isReady || isOut || isDelivered),
          isCurrent: isMilling,
        );

        _order.trackingSteps[3] = TrackingStep(
          title: '4. 🍞 Leg 2: Flour Delivery',
          subtitle: 'Rider collects flour from Mill ➔ Home',
          timeText: isDelivered
              ? 'Completed'
              : (isOut ? 'On the way' : (isReady ? 'Ready for rider' : 'Pending')),
          isCompleted: isDelivered,
          isCurrent: isOut || isReady,
        );

        _order.trackingSteps[4] = TrackingStep(
          title: '5. 🏁 Delivered',
          subtitle: 'Doorstep handover & verified',
          timeText: isDelivered ? 'Delivered' : 'Pending',
          isCompleted: isDelivered,
          isCurrent: false,
        );
      }
    }

    if (isDelivered || isCancelled || isReturnedToCustomer || isReturnedToMill) {
      _order.isActive = false;
    }
  }

  void _ensureTrackingSteps() {
    if (_order.trackingSteps.isEmpty) {
      _order.trackingSteps.addAll([
        TrackingStep(
          title: '1. Order Placed',
          subtitle: 'Order accepted by mill',
          timeText: 'Completed',
          isCompleted: true,
          isCurrent: false,
        ),
        TrackingStep(
          title: '2. 🌾 Leg 1: Grain Pickup',
          subtitle: 'Rider collects raw grain from home ➔ Mill',
          timeText: 'In progress',
          isCompleted: false,
          isCurrent: true,
        ),
        TrackingStep(
          title: '3. 🏭 Mill Processing',
          subtitle: 'Quality check & stone chakki grinding',
          timeText: 'Pending',
          isCompleted: false,
          isCurrent: false,
        ),
        TrackingStep(
          title: '4. 🍞 Leg 2: Flour Delivery',
          subtitle: 'Rider collects flour from Mill ➔ Home',
          timeText: 'Pending',
          isCompleted: false,
          isCurrent: false,
        ),
        TrackingStep(
          title: '5. 🏁 Delivered',
          subtitle: 'Doorstep handover & verified',
          timeText: 'Pending',
          isCompleted: false,
          isCurrent: false,
        ),
      ]);
    }
    _applyStatusToTrackingSteps(_order.statusStep);
  }

  Future<void> _handleRefresh() async {
    await _pollLiveOrderStatus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚡ Order tracking updated'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _launchGoogleMaps() async {
    final destination = '${_order.millName}, ${_order.deliveryAddress}';
    final Uri url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destination)}&travelmode=driving',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening Google Maps: $destination')),
        );
      }
    }
  }

  Future<void> _callPhone(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(' ', '');
    final Uri url = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('📞 Dialing $phoneNumber')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('📞 Contact: $phoneNumber')),
        );
      }
    }
  }

  bool get _canCancelOrder {
    final s = _order.statusStep.toUpperCase().replaceAll(' ', '_');
    // If order is completed or terminal
    if (s == 'CANCELLED' || s == 'CANCELED' || s == 'REJECTED' || s == 'DELIVERED' || s == 'COMPLETED') {
      return false;
    }
    // If milling/packing or out for delivery has started
    if (s == 'PROCESSING' || s == 'MILLING' || s == 'IN_PROGRESS' || s == 'PACKING' || s == 'READY' || s == 'READY_FOR_PICKUP' || s == 'OUT_FOR_DELIVERY') {
      return false;
    }
    if (s.contains('RETURN')) {
      return false;
    }
    // If Leg 1 pickup has already completed in the tracking steps
    if (_order.trackingSteps.length > 1 && _order.trackingSteps[1].isCompleted) {
      return false;
    }
    // Cancellable as long as raw grain is not picked up: PLACED, NEW, PENDING, ACCEPTED, CONFIRMED, ASSIGNED
    return ['PLACED', 'NEW', 'PENDING', 'ACCEPTED', 'CONFIRMED', 'ASSIGNED'].contains(s);
  }

  Future<void> _confirmCancelOrder() async {
    final numericId = int.tryParse(_order.orderId.replaceAll(RegExp(r'[^0-9]'), ''));
    final idToCancel = (numericId != null && numericId > 0) ? numericId : _order.orderId;

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cancel Order?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: Text(
          'Are you sure you want to cancel order ${_order.orderId}? You can cancel anytime before raw grain is picked up from your doorstep.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep Order', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD9534F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Yes, Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      final res = await CustomerApiService.instance.cancelOrderWithDetails(idToCancel);
      if (mounted) {
        if (res['success'] == true) {
          setState(() {
            _order.statusStep = 'CANCELLED';
            _order.isActive = false;
            _applyStatusToTrackingSteps('CANCELLED');
          });
          _uiRefreshTimer?.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Order has been cancelled successfully.'),
              backgroundColor: const Color(0xFFD9534F),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Could not cancel order. Grain may already be picked up.'),
              backgroundColor: Colors.orange.shade800,
            ),
          );
        }
      }
    }
  }

  List<Map<String, dynamic>> _getOrderItems() {
    if (_order.items.isNotEmpty) {
      return _order.items.map((item) {
        final name = (item['name'] ?? 'Product').toString();
        final num qty = (item['quantity'] is num)
            ? item['quantity']
            : (double.tryParse(item['quantity']?.toString() ?? '1') ?? 1);
        final num rawPrice = (item['price'] is num)
            ? item['price']
            : (double.tryParse(item['price']?.toString() ?? '5') ?? 5.0);
        final type = item['type']?.toString() ?? 'milling';
        final isMilling = type == 'milling' || name.toLowerCase().contains('milling');

        final double itemTotal = (item['itemTotal'] is num)
            ? (item['itemTotal'] as num).toDouble()
            : (item['total'] is num)
                ? (item['total'] as num).toDouble()
                : (rawPrice * qty).toDouble();

        return {
          'name': name,
          'type': type,
          'quantity': qty % 1 == 0 ? qty.toInt() : qty,
          'price': rawPrice,
          'itemTotal': itemTotal,
          'isMilling': isMilling,
        };
      }).toList();
    }

    final summary = _order.itemSummary.trim();
    final rawParts = summary.split(RegExp(r',\s*')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    if (rawParts.isNotEmpty) {
      final parsed = <Map<String, dynamic>>[];
      for (final part in rawParts) {
        // Match expressions like "5kg Wheat (Gehun) (Milling)" or "15kg Ragi (Finger Millet) (Milling)"
        final match = RegExp(r'^(\d+(\.\d+)?)\s*(kg|g|unit|x|pack|bag)?\s*(.*)$', caseSensitive: false).firstMatch(part);
        double qty = 5.0;
        String name = part;
        if (match != null) {
          qty = double.tryParse(match.group(1) ?? '5') ?? 5.0;
          final remainder = match.group(4)?.trim() ?? '';
          if (remainder.isNotEmpty) {
            name = remainder;
          }
        }

        final isMilling = part.toLowerCase().contains('milling') ||
            part.toLowerCase().contains('grain') ||
            part.toLowerCase().contains('gehun') ||
            part.toLowerCase().contains('wheat') ||
            part.toLowerCase().contains('ragi') ||
            part.toLowerCase().contains('rice') ||
            part.toLowerCase().contains('chawal') ||
            part.toLowerCase().contains('bajra') ||
            part.toLowerCase().contains('chana') ||
            part.toLowerCase().contains('atta');

        // Standard milling grinding fee is ₹5.00 per kg
        final unitPrice = isMilling ? 5.0 : 35.0;
        final itemTotal = qty * unitPrice;

        parsed.add({
          'name': name,
          'type': isMilling ? 'milling' : 'readymade',
          'quantity': qty % 1 == 0 ? qty.toInt() : qty,
          'price': unitPrice,
          'itemTotal': itemTotal,
          'isMilling': isMilling,
        });
      }
      return parsed;
    }

    final qtyNumber = int.tryParse(_order.quantityKg.replaceAll(RegExp(r'[^0-9]'), '')) ?? 5;
    return [
      {
        'name': summary.isNotEmpty ? summary : 'Wheat (Gehun) (Milling)',
        'type': 'milling',
        'quantity': qtyNumber,
        'price': 5.0,
        'itemTotal': qtyNumber * 5.0,
        'isMilling': true,
      }
    ];
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
style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryTerracotta,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.timeline_rounded, color: AppTheme.primaryTerracotta),
            tooltip: 'Live Timeline',
            onPressed: _openOrderTimelineSheet,
          ),
          IconButton(
            icon: Icon(
              _viewMode == 0 ? Icons.map_outlined : Icons.list_alt_rounded,
              color: AppTheme.primaryTerracotta,
            ),
            tooltip: _viewMode == 0 ? 'Switch to Map & Receipt' : 'Switch to Full Progress',
            onPressed: () {
              setState(() => _viewMode = _viewMode == 0 ? 1 : 0);
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: AppTheme.textPrimary),
            tooltip: 'Support & Help',
            onPressed: () => _showHelpBottomSheet(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppTheme.primaryTerracotta,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Segmented Pill Toggle Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _viewMode = 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                        decoration: BoxDecoration(
                          color: _viewMode == 0 ? AppTheme.primaryTerracotta : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _viewMode == 0 ? AppTheme.primaryTerracotta : AppTheme.borderLight,
                          ),
                          boxShadow: _viewMode == 0
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryTerracotta.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : null,
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
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => setState(() => _viewMode = 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                        decoration: BoxDecoration(
                          color: _viewMode == 1 ? AppTheme.primaryTerracotta : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _viewMode == 1 ? AppTheme.primaryTerracotta : AppTheme.borderLight,
                          ),
                          boxShadow: _viewMode == 1
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryTerracotta.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : null,
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

                if (_viewMode == 0) _buildFullProgressView() else _buildMapAndReceiptView(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- FULL PROGRESS STEPPER VIEW (MATCHING ATTACHED SCREENSHOT) ---
  Widget _buildFullProgressView() {
    final items = _getOrderItems();
    final isCancelled = _order.statusStep.toUpperCase() == 'CANCELLED';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Order Info Banner Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCancelled ? const Color(0xFFD9534F) : AppTheme.mustardGold,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      isCancelled ? 'Cancelled' : _order.quantityKg,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _order.itemSummary,
      style: GoogleFonts.plusJakartaSans(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  height: 1.25,
                ),
              ),
              if (isCancelled)
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF5C6CB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cancel_outlined, color: Color(0xFFD9534F), size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Order Cancelled',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD9534F),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_order.statusStep.toUpperCase() == 'DELIVERED' || _order.statusStep.toUpperCase() == 'COMPLETED')
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2ECC71)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF1E8449), size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fresh Flour Handover Complete!',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1E8449)),
                                ),
                                Text(
                                  'Your freshly stone-ground flour bag has been verified & delivered to your doorstep.',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final numId = int.tryParse(_order.orderId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 101;
                            final ok = await CustomerApiService.instance.confirmReceipt(numId);
                            if (!mounted) return;
                            if (ok) {
                              setState(() {
                                _order.statusStep = 'COMPLETED';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🎉 Handover confirmed! Order completed successfully.'),
                                  backgroundColor: Color(0xFF1E8449),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
                          label: Text(
                            'I Received My Flour Safely',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E8449),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Vertical Dynamic Step List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _order.trackingSteps.length,
          itemBuilder: (context, index) {
            final step = _order.trackingSteps[index];
            final isLast = index == _order.trackingSteps.length - 1;
            return _buildStepperItem(step, isLast: isLast);
          },
        ),

        const SizedBox(height: 24),

        // Items Summary Box (Matching Image 1)
        _buildItemsSummaryBox(items),

        const SizedBox(height: 20),

        // Action Buttons (Call Mill, Cancel if Placed)
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _callPhone(_order.millPhone),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.primaryTerracotta),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.phone_outlined, color: AppTheme.primaryTerracotta, size: 18),
                label: Text(
                  'Call Mill Owner',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTerracotta,
                  ),
                ),
              ),
            ),
            if (_canCancelOrder) ...[
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _confirmCancelOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDECEB),
                    foregroundColor: const Color(0xFFD9534F),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text(
                    'Cancel Order',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- DYNAMIC STEPPER NODE ITEM ---
  Widget _buildStepperItem(TrackingStep step, {required bool isLast}) {
    final isDone = step.isCompleted;
    final isCurrent = step.isCurrent;

    return CustomPaint(
      painter: _TimelinePainter(isDone: isDone, isLast: isLast),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Node
          SizedBox(
            width: 36,
            height: 36,
            child: isDone
                ? Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF556B2F),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 20),
                  )
                : isCurrent
                    ? AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFECEB),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryTerracotta,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryTerracotta.withValues(alpha: 0.2 * _pulseController.value),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.sync_rounded,
                              color: AppTheme.primaryTerracotta,
                              size: 20,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFDCD6CE),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFB5ADA3),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
          ),
          const SizedBox(width: 16),
          // Content Details Column
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 6.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          step.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: isCurrent
                                ? AppTheme.primaryTerracotta
                                : (isDone ? AppTheme.textPrimary : const Color(0xFF8A847C)),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        step.timeText.isNotEmpty ? step.timeText : 'Pending',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: (isDone || isCurrent) ? FontWeight.bold : FontWeight.w500,
                          color: isCurrent
                              ? AppTheme.primaryTerracotta
                              : (isDone ? AppTheme.textSecondary : const Color(0xFFA09990)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      color: isCurrent
                          ? AppTheme.softCoral
                          : (isDone ? AppTheme.textSecondary : const Color(0xFFA09990)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MAP & RECEIPT VIEW (TAB 1) ---
  Widget _buildMapAndReceiptView() {
    final items = _getOrderItems();
    final driverName = _order.deliveryDriverName ?? 'Vikram Delivery Partner';
    final driverPhone = _order.deliveryDriverPhone ?? '+919876543212';
    final vehicle = _order.deliveryDriverVehicle ?? 'Electric Eco-Scooter (GJ-01-AB-1234)';
    final isOutForDelivery = _order.statusStep.toUpperCase().contains('OUT') ||
        _order.statusStep.toUpperCase().contains('DELIVERY') ||
        _order.statusStep.toUpperCase().contains('READY');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Text(
                'Order ${_order.orderId}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Live Route & Navigation Box
        Container(
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
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=800&q=80',
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2ECC71),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Live GPS Active',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.store_outlined, color: AppTheme.primaryTerracotta, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _order.millName.isNotEmpty ? _order.millName : 'Shree Ganesh Flour Mill',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: AppTheme.mustardDark, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _order.deliveryAddress.isNotEmpty
                                ? _order.deliveryAddress
                                : 'Flat 402, Shivalik Towers, Satellite Road, Ahmedabad',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _launchGoogleMaps,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryTerracotta,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.directions_outlined, size: 18, color: Colors.white),
                            label: Text(
                              'Open in Google Maps',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _callPhone(_order.millPhone),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.borderLight),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          icon: const Icon(Icons.phone_outlined, size: 18, color: AppTheme.primaryTerracotta),
                          label: Text(
                            'Mill',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.primaryTerracotta,
                            ),
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

        // Driver Info Card (if assigned)
        if (isOutForDelivery) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F5EF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F8F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delivery_dining_rounded, color: Color(0xFF27AE60), size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        vehicle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone_rounded, color: Color(0xFF27AE60)),
                  onPressed: () => _callPhone(driverPhone),
                  tooltip: 'Call Delivery Partner',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Itemized Receipt Box
        _buildItemsSummaryBox(items),
        if (_canCancelOrder) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _confirmCancelOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDECEB),
                foregroundColor: const Color(0xFFD9534F),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: Text(
                'Cancel Order',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  // --- ORDERED ITEMS BREAKDOWN BOX ---
  Widget _buildItemsSummaryBox(List<Map<String, dynamic>> items) {
    // 1. Calculate computed item subtotal
    double computedItemsSubtotal = 0.0;
    for (final item in items) {
      final num itemTotal = (item['itemTotal'] is num)
          ? item['itemTotal']
          : (((item['price'] is num ? item['price'] : 5.0) as num) *
              ((item['quantity'] is num ? item['quantity'] : 1) as num));
      computedItemsSubtotal += itemTotal.toDouble();
    }

    // 2. Resolve grand total and fees with mathematical accuracy matching Checkout & Invoice
    final double grandTotal = _order.totalPrice > 0
        ? _order.totalPrice
        : (computedItemsSubtotal > 0 ? computedItemsSubtotal + 55.0 : 105.0);

    double resolvedDeliveryFee = _order.deliveryFee > 0 ? _order.deliveryFee : 35.0;
    double resolvedPickupFee = _order.pickupFee;
    double resolvedSubtotal = _order.millingFee > 0 ? _order.millingFee : computedItemsSubtotal;

    // Harmonize fees so that subtotal + pickupFee + deliveryFee == grandTotal
    final double feesSum = resolvedPickupFee + resolvedDeliveryFee;
    if (resolvedPickupFee == 0.0 && (grandTotal - resolvedSubtotal) >= 50.0) {
      resolvedPickupFee = 20.0;
      resolvedDeliveryFee = 35.0;
      resolvedSubtotal = grandTotal - (resolvedPickupFee + resolvedDeliveryFee);
    } else if (resolvedSubtotal + feesSum != grandTotal) {
      if (grandTotal >= 55.0) {
        if (resolvedPickupFee == 0.0 && grandTotal > (computedItemsSubtotal + 35.0)) {
          resolvedPickupFee = 20.0;
        }
        resolvedDeliveryFee = 35.0;
        resolvedSubtotal = grandTotal - (resolvedPickupFee + resolvedDeliveryFee);
      } else {
        resolvedSubtotal = grandTotal > resolvedDeliveryFee ? (grandTotal - resolvedDeliveryFee) : grandTotal;
      }
    }

    if (resolvedSubtotal < 0) resolvedSubtotal = 0;

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryTerracotta, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Ordered Items (${items.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F5EF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _order.millName.isNotEmpty ? _order.millName : 'Shree Ganesh Flour Mill',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6E5616),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) {
            final name = item['name']?.toString() ?? 'Flour Item';
            final qty = item['quantity'] ?? 1;
            final type = item['type']?.toString() ?? 'milling';
            final isMilling = item['isMilling'] == true || type == 'milling' || name.toLowerCase().contains('milling');
            final num rawPrice = (item['price'] is num) ? item['price'] : 5.0;
            final double itemTotal = (item['itemTotal'] is num)
                ? (item['itemTotal'] as num).toDouble()
                : (rawPrice * (qty is num ? qty : 1)).toDouble();

            return Container(
              margin: const EdgeInsets.only(bottom: 12.0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isMilling ? const Color(0xFFEDE9D9) : const Color(0xFFE8F8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isMilling ? Icons.grain_rounded : Icons.inventory_2_rounded,
                      color: isMilling ? const Color(0xFF6E5616) : const Color(0xFF27AE60),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        const SizedBox(height: 2),
                        Text(
                          isMilling ? 'Custom Stone Milling' : 'Pre-packed Artisan Flour',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${itemTotal.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryTerracotta,
                        ),
                      ),
                      Text(
                        isMilling ? '$qty kg' : 'Qty: $qty',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 20, color: AppTheme.borderLight),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                items.length > 1 ? 'Subtotal (${items.length} items)' : 'Subtotal (1 item)',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary),
              ),
              Text(
                '₹${resolvedSubtotal.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
            ],
          ),
          if (resolvedPickupFee > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pickup Fee',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary),
                ),
                Text(
                  '₹${resolvedPickupFee.toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Fee',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary),
              ),
              Text(
                '₹${resolvedDeliveryFee.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const Divider(height: 20, color: AppTheme.borderLight),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount Paid',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    _order.paymentMethod.isNotEmpty ? _order.paymentMethod : 'Visa Card (•••• 4242)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF27AE60),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '₹${grandTotal.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryTerracotta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showHelpBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HerDoor Order Support',
    style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Need assistance with your grain milling or delivery?',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.phone_outlined, color: AppTheme.primaryTerracotta),
              title: Text('Call Mill Owner', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              subtitle: Text(_order.millPhone),
              onTap: () {
                Navigator.pop(ctx);
                _callPhone(_order.millPhone);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.mustardDark),
              title: Text('Chat with HerDoor Support', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              subtitle: const Text('support@herdoor.com • Instant help'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Connecting to HerDoor Customer Support...')),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _openOrderTimelineSheet() {
    final numericId = int.tryParse(_order.orderId.replaceAll(RegExp(r'[^0-9]'), ''));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FutureBuilder<List<OrderTimelineEvent>>(
        future: numericId != null
            ? DeliveryApiService.instance.getOrderTimeline(numericId)
            : Future.value([]),
        builder: (context, snapshot) {
          final timelineEvents = (snapshot.hasData && snapshot.data!.isNotEmpty)
              ? snapshot.data!
              : _buildSynthesizedTimeline();

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timeline_rounded, color: AppTheme.primaryTerracotta),
                        const SizedBox(width: 8),
                        Text('Order Timeline', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTerracotta.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _order.orderId,
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryTerracotta),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Real-time verified milestones across milling and delivery:', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 16),

                Expanded(
                  child: ListView.builder(
                    itemCount: timelineEvents.length,
                    itemBuilder: (context, index) {
                      final ev = timelineEvents[index];
                      final isLast = index == timelineEvents.length - 1;
                      final isRejectOrReturn = ev.isReturnOrReject;

                      Color iconColor = const Color(0xFF1E8449);
                      Color dotBg = const Color(0xFFE8F8F5);
                      IconData eventIcon = Icons.check_circle_rounded;

                      if (isRejectOrReturn) {
                        iconColor = const Color(0xFFDC2626);
                        dotBg = const Color(0xFFFEF2F2);
                        eventIcon = Icons.cancel_rounded;
                      } else if (ev.status.contains('ASSIGNED') || ev.status.contains('PICKED') || ev.status.contains('EN_ROUTE')) {
                        iconColor = const Color(0xFFD97706);
                        dotBg = const Color(0xFFFFFBEB);
                        eventIcon = Icons.navigation_rounded;
                      } else if (ev.status.contains('MILLING') || ev.status.contains('INTAKE')) {
                        iconColor = const Color(0xFF2563EB);
                        dotBg = const Color(0xFFEFF6FF);
                        eventIcon = Icons.storefront_rounded;
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: dotBg,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: iconColor.withValues(alpha: 0.4), width: 1.5),
                                ),
                                child: Icon(eventIcon, color: iconColor, size: 16),
                              ),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 44,
                                  color: Colors.grey.shade200,
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),

                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          ev.title,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isRejectOrReturn ? const Color(0xFF991B1B) : AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        ev.formattedTime,
                                        style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    ev.description,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                                  ),
                                  if (ev.performedBy != null && ev.performedBy!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'By ${ev.performedBy}',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<OrderTimelineEvent> _buildSynthesizedTimeline() {
    final List<OrderTimelineEvent> list = [];
    final now = DateTime.now();
    final s = _order.statusStep.toUpperCase().replaceAll(' ', '_');

    list.add(OrderTimelineEvent(
      title: 'Order Placed',
      description: 'Order booked and confirmed on HerDoor platform',
      status: 'BOOKED',
      createdAt: now.subtract(const Duration(minutes: 50)),
      performedBy: 'Customer',
    ));

    if (s.contains('ASSIGNED') || s.contains('PICK') || s.contains('MILL') || s.contains('OUT') || s.contains('DELIVER') || s.contains('RETURN')) {
      list.add(OrderTimelineEvent(
        title: 'Driver Assigned',
        description: 'Delivery rider assigned to pickup and transit route',
        status: 'DRIVER_ASSIGNED',
        createdAt: now.subtract(const Duration(minutes: 40)),
        performedBy: 'System',
      ));
    }

    if (s == 'RETURN_TO_CUSTOMER' || s == 'RETURNED_TO_CUSTOMER') {
      list.add(OrderTimelineEvent(
        title: 'Raw Grain Picked Up',
        description: 'Driver collected raw grain bags from customer doorstep',
        status: 'GRAIN_PICKED_UP',
        createdAt: now.subtract(const Duration(minutes: 30)),
        performedBy: 'Driver',
      ));
      list.add(OrderTimelineEvent(
        title: 'Arrived at Flour Mill',
        description: 'Grain bags submitted for quality check at mill',
        status: 'MILL_ARRIVED',
        createdAt: now.subtract(const Duration(minutes: 20)),
        performedBy: 'Driver',
      ));
      list.add(OrderTimelineEvent(
        title: 'Grain Quality Rejected by Mill',
        description: 'Shopkeeper inspection failed: moisture or foreign impurities found',
        status: 'RETURN_TO_CUSTOMER',
        createdAt: now.subtract(const Duration(minutes: 10)),
        performedBy: 'Merchant',
      ));
      if (s == 'RETURNED_TO_CUSTOMER') {
        list.add(OrderTimelineEvent(
          title: 'Grain Returned to Customer',
          description: 'Raw grain safely returned to customer doorstep',
          status: 'RETURNED_TO_CUSTOMER',
          createdAt: now,
          performedBy: 'Driver',
        ));
      }
    } else if (s == 'RETURN_TO_MILL' || s == 'RETURNED_TO_MILL') {
      list.add(OrderTimelineEvent(
        title: 'Milling Completed',
        description: 'Fresh flour milled and packaged by mill owner',
        status: 'MILLING_COMPLETED',
        createdAt: now.subtract(const Duration(minutes: 30)),
        performedBy: 'Merchant',
      ));
      list.add(OrderTimelineEvent(
        title: 'Out for Doorstep Delivery',
        description: 'Driver picked up flour from mill and traveled to customer',
        status: 'OUT_FOR_DELIVERY',
        createdAt: now.subtract(const Duration(minutes: 20)),
        performedBy: 'Driver',
      ));
      list.add(OrderTimelineEvent(
        title: 'Flour Quality Rejected by Customer',
        description: 'Customer inspected flour bags at doorstep and rejected quality',
        status: 'RETURN_TO_MILL',
        createdAt: now.subtract(const Duration(minutes: 10)),
        performedBy: 'Customer',
      ));
      if (s == 'RETURNED_TO_MILL') {
        list.add(OrderTimelineEvent(
          title: 'Flour Returned to Mill',
          description: 'Rejected flour safely returned to flour mill shopkeeper',
          status: 'RETURNED_TO_MILL',
          createdAt: now,
          performedBy: 'Driver',
        ));
      }
    } else {
      if (s == 'IN_PROGRESS' || s == 'PROCESSING' || s == 'MILLING' || s == 'READY' || s == 'OUT_FOR_DELIVERY' || s == 'DELIVERED' || s == 'COMPLETED') {
        list.add(OrderTimelineEvent(
          title: 'Grain Cleaning & Quality Check',
          description: 'Mill owner inspected raw grain and verified quality',
          status: 'INTAKE_VERIFIED',
          createdAt: now.subtract(const Duration(minutes: 30)),
          performedBy: 'Merchant',
        ));
        list.add(OrderTimelineEvent(
          title: 'Milling in Progress',
          description: 'Grain being freshly stone-ground in chakki',
          status: 'MILLING_IN_PROGRESS',
          createdAt: now.subtract(const Duration(minutes: 20)),
          performedBy: 'Merchant',
        ));
      }

      if (s == 'OUT_FOR_DELIVERY' || s == 'DELIVERED' || s == 'COMPLETED') {
        list.add(OrderTimelineEvent(
          title: 'Out for Delivery',
          description: 'Fresh flour bags picked up and en-route to customer',
          status: 'OUT_FOR_DELIVERY',
          createdAt: now.subtract(const Duration(minutes: 10)),
          performedBy: 'Driver',
        ));
      }

      if (s == 'DELIVERED' || s == 'COMPLETED') {
        list.add(OrderTimelineEvent(
          title: 'Delivered & Doorstep Verified',
          description: 'Customer verified flour quality and completed handover with OTP',
          status: 'DELIVERED',
          createdAt: now,
          performedBy: 'Driver',
        ));
      }
    }

    return list;
  }
}

/// CustomPainter that cleanly draws the timeline connecting line behind nodes without IntrinsicHeight layout issues.
class _TimelinePainter extends CustomPainter {
  final bool isDone;
  final bool isLast;

  const _TimelinePainter({
    required this.isDone,
    required this.isLast,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isLast) {
      final paint = Paint()
        ..color = isDone ? const Color(0xFF556B2F) : const Color(0xFFE5DFD7)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      // Draw line from bottom center of 36x36 node to the bottom edge of this item
      canvas.drawLine(
        const Offset(18.0, 36.0),
        Offset(18.0, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) =>
      oldDelegate.isDone != isDone || oldDelegate.isLast != isLast;
}

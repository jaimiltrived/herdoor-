import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/merchant_models.dart';
import '../../services/merchant_api_service.dart';
import 'merchant_order_process_detail_screen.dart';
import 'merchant_active_driver_pickup_screen.dart';
import 'mill_owner_qr_scanner_screen.dart';

class MerchantOrdersScreen extends StatefulWidget {
  const MerchantOrdersScreen({super.key});

  @override
  State<MerchantOrdersScreen> createState() => _MerchantOrdersScreenState();
}

class _MerchantOrdersScreenState extends State<MerchantOrdersScreen> {
  int _selectedFilterTab = 0; // 0: NEW, 1: Pending, 2: Completed, 3: Delivered
  bool _isLoading = false;
  Timer? _pollingTimer;

  final List<MerchantOrder> _newOrders = [];
  final List<MerchantOrder> _pendingOrders = [];
  final List<MerchantOrder> _completedMillingOrders = [];
  final List<MerchantOrder> _deliveredOrders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrdersData(showLoading: true);
    // Real-time automatic background polling every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchOrdersData(showLoading: false);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrdersData({bool showLoading = false}) async {
    if (!mounted) return;
    if (showLoading) setState(() => _isLoading = true);

    try {
      final newOrdersFuture = MerchantApiService.instance.getNewOrders();
      final activeOrdersFuture = MerchantApiService.instance.getActiveOrders();
      final readyOrdersFuture = MerchantApiService.instance.getReadyOrders();
      final completedOrdersFuture = MerchantApiService.instance.getCompletedOrders();

      final results = await Future.wait([newOrdersFuture, activeOrdersFuture, readyOrdersFuture, completedOrdersFuture]);

      final fetchedNew = results[0];
      final fetchedActive = results[1];
      final fetchedReady = results[2];
      final fetchedCompleted = results[3];

      if (mounted) {
        setState(() {
          _newOrders.clear();
          if (fetchedNew != null) {
            _newOrders.addAll(fetchedNew.where((o) => o.statusTag == 'NEW' || o.statusTag == 'PLACED' || o.statusTag == 'New Request'));
          }

          _pendingOrders.clear();
          if (fetchedActive != null) {
            _pendingOrders.addAll(fetchedActive.where((o) => o.statusTag == 'IN PROGRESS' || o.statusTag == 'PROCESSING' || o.statusTag == 'ACCEPTED' || o.statusTag == 'MILLING' || o.statusTag == 'PACKING'));
          }

          _completedMillingOrders.clear();
          if (fetchedReady != null) {
            _completedMillingOrders.addAll(fetchedReady);
          }

          _deliveredOrders.clear();
          if (fetchedCompleted != null) {
            _deliveredOrders.addAll(fetchedCompleted);
          }

          if (showLoading) _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && showLoading) setState(() => _isLoading = false);
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedFilterTab = index;
    });
  }

  List<MerchantOrder> get _currentTabOrders {
    switch (_selectedFilterTab) {
      case 0:
        return _newOrders;
      case 1:
        return _pendingOrders;
      case 2:
        return _completedMillingOrders;
      case 3:
        return _deliveredOrders;
      default:
        return _newOrders;
    }
  }

  Future<void> _handleAcceptOrder(MerchantOrder order) async {
    final int resolvedId = order.numericId ??
        int.tryParse(order.orderId.replaceAll(RegExp(r'[^0-9]'), '')) ??
        501;
    final messenger = ScaffoldMessenger.of(context);

    // Update UI state immediately for responsive feel
    setState(() {
      _newOrders.removeWhere((o) => o.orderId == order.orderId);
      order.statusTag = 'IN PROGRESS';
      order.statusColor = const Color(0xFFCBA034);
      _pendingOrders.insert(0, order);
    });

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF2ECC71),
        content: Text('✅ Order ${order.orderId} Accepted! Moved to Pending.'),
      ),
    );

    final success = await MerchantApiService.instance.acceptOrder(resolvedId, estimatedMinutes: 30);
    if (!mounted) return;
    if (success) {
      _fetchOrdersData(showLoading: false);
    }
  }

  Future<void> _executeDeclineWithProof(MerchantOrder order, String reason, String details, int photoCount) async {
    final orderId = order.numericId ?? 501;
    final messenger = ScaffoldMessenger.of(context);
    await MerchantApiService.instance.rejectOrder(orderId, reason: reason);
    if (!mounted) return;

    setState(() {
      _newOrders.removeWhere((o) => o.orderId == order.orderId);
      _pendingOrders.removeWhere((o) => o.orderId == order.orderId);
    });
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade800,
        content: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Order ${order.orderId} Declined: $reason ($photoCount photo${photoCount == 1 ? '' : 's'} proof attached). Customer notified.',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
    _fetchOrdersData();
  }

  void _showDeclineOrderWithProofModal(BuildContext context, MerchantOrder order) {
    String selectedReason = 'Contaminated Grain';
    final textController = TextEditingController();
    List<String> attachedImages = [
      'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&w=400&q=80',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Decline Order ${order.orderId}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Provide reason & photo proof (Max 3)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppTheme.borderLight),
                const SizedBox(height: 14),

                // Predefined Reasons
                Text(
                  'Select Primary Reason *',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    '🌾 Contaminated Grain',
                    '💧 Wet / High Moisture',
                    '⚙️ Machine Breakdown',
                    '📦 Damaged Packaging',
                    '📝 Other Issue',
                  ].map((r) {
                    final cleanName = r.substring(2).trim();
                    final isSelected = selectedReason == cleanName || selectedReason == r;
                    return ChoiceChip(
                      label: Text(r),
                      selected: isSelected,
                      selectedColor: const Color(0xFFFFECEB),
                      backgroundColor: const Color(0xFFF6F0E7),
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.red.shade700 : AppTheme.textPrimary,
                      ),
                      side: BorderSide(
                        color: isSelected ? Colors.red.shade400 : AppTheme.borderLight,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setModalState(() => selectedReason = cleanName);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Detailed Description
                Text(
                  'Detailed Description / Note *',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: textController,
                  maxLines: 3,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Explain why the grain or order cannot be processed...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderLight),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFCFAF7),
                  ),
                ),
                const SizedBox(height: 16),

                // Photo Proof Section (Max 3 images)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attach Photo Proof (${attachedImages.length}/3)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (attachedImages.length < 3)
                      TextButton.icon(
                        onPressed: () {
                          setModalState(() {
                            if (attachedImages.length == 1) {
                              attachedImages.add(
                                'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=400&q=80',
                              );
                            } else if (attachedImages.length == 2) {
                              attachedImages.add(
                                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
                              );
                            }
                          });
                        },
                        icon: const Icon(Icons.add_a_photo_outlined, size: 16, color: AppTheme.primaryTerracotta),
                        label: Text(
                          'Add Photo',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryTerracotta,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Images Preview Row
                Row(
                  children: [
                    ...attachedImages.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final url = entry.value;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderLight),
                              image: DecorationImage(
                                image: NetworkImage(url),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  attachedImages.removeAt(idx);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    if (attachedImages.length < 3)
                      GestureDetector(
                        onTap: () {
                          setModalState(() {
                            attachedImages.add(
                              attachedImages.isEmpty
                                  ? 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&w=400&q=80'
                                  : 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=400&q=80',
                            );
                          });
                        },
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F0E7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt_outlined, color: AppTheme.textSecondary, size: 22),
                              const SizedBox(height: 4),
                              Text(
                                '+ Add',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _executeDeclineWithProof(order, selectedReason, textController.text, attachedImages.length);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.white, size: 18),
                    label: Text(
                      'Confirm Decline & Notify Customer',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCompleteMillingAndMoveToHandover(MerchantOrder order) async {
    final orderId = order.numericId ?? 501;
    setState(() {
      _pendingOrders.removeWhere((o) => o.orderId == order.orderId);
      order.statusTag = 'READY FOR PICKUP';
      order.statusColor = const Color(0xFFFF8A80);
      _completedMillingOrders.insert(0, order);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF2ECC71),
        content: Text('⚙️ Milling Finished! Order ${order.orderId} moved to Handover (Ready).'),
      ),
    );
    await MerchantApiService.instance.transitionOrderStatus(orderId, 'ready');
    if (mounted) _fetchOrdersData();
  }

  @override
  Widget build(BuildContext context) {
    final int totalOrdersCount =
        _newOrders.length + _pendingOrders.length + _completedMillingOrders.length + _deliveredOrders.length;
    final int activeCount = _newOrders.length + _pendingOrders.length;

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
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
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
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.filter_list_rounded, size: 20, color: AppTheme.textPrimary),
                        const SizedBox(width: 8),
                        Text(
                          'Filter',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTerracotta,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.file_download_outlined, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Export',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Today's Overview Stats Card
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
                              '$totalOrdersCount',
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
                              '$activeCount',
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

            // 4 Filter Toggle Bar: NEW, Pending, Completed, Delivered
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F0E7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildFilterTab(0, 'NEW', '${_newOrders.length}', Icons.new_label_outlined),
                  _buildFilterTab(1, 'Pending', '${_pendingOrders.length}', Icons.hourglass_empty_rounded),
                  _buildFilterTab(2, 'Completed', '${_completedMillingOrders.length}', Icons.inventory_2_outlined),
                  _buildFilterTab(3, 'Delivered', '${_deliveredOrders.length}', Icons.home_outlined),
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
            else if (_currentTabOrders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'No orders in this category.',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final order in _currentTabOrders) _buildOrderRequestCard(context, order),
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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFAF2DD) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: const Color(0xFFD4C094)) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected ? const Color(0xFF6E5616) : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6E5616) : const Color(0xFFE2DACF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
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
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MerchantOrderProcessDetailScreen(order: order),
          ),
        );
        if (mounted) _fetchOrdersData();
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
            // Top Section with Order ID & Status Badge
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.orderId,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: order.statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          order.statusTag,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: order.statusColor,
                          ),
                        ),
                      ),
                    ],
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
                  const SizedBox(height: 2),
                  Text(
                    order.itemsSummary,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),

            // Details & Action Controls Section
            Padding(
              padding: const EdgeInsets.all(18.0),
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
                          color: AppTheme.oliveGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
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
                      Expanded(
                        child: Column(
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dynamic Action Controls based on Tab & Status
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
    if (_selectedFilterTab == 0) {
      // 1. NEW: Accept or Decline with proof
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => _showDeclineOrderWithProofModal(context, order),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: Text(
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
    } else if (_selectedFilterTab == 1) {
      final isMilling = order.statusTag == 'MILLING';

      if (isMilling) {
        // State 2 (After scan): Complete Milling & Move to Handover
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => _handleCompleteMillingAndMoveToHandover(order),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTerracotta,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            label: Text(
              'Complete Milling & Move to Handover',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      }

      // State 1: Scan QR & Proceed to Handover
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MillOwnerQrScannerScreen(order: order),
              ),
            );
            if (mounted) {
              _fetchOrdersData();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6E5616),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
          label: Text(
            'Scan QR & Move to Handover',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else if (_selectedFilterTab == 2) {
      // 3. Ready for Handover
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F5EF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8DFC8)),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF6E5616), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Milling Finished • Ready for Handover',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6E5616),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MerchantActiveDriverPickupScreen(),
                  ),
                );
                if (mounted) {
                  _fetchOrdersData();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTerracotta,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.handshake_outlined, color: Colors.white, size: 18),
              label: Text(
                'Handover to Delivery Person',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // 4. Delivered: Delivered to Home
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F8F0),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFA2E4D4)),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_rounded, color: Color(0xFF2ECC71), size: 20),
              const SizedBox(width: 8),
              Text(
                'Delivered Fresh to Customer Doorstep',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E8449),
                  fontSize: 13,
                ),
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
                'Set Completion Time',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select estimated milling & packing time for ${order.orderId}:',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['20 Mins', '30 Mins', '45 Mins', '60 Mins'].map((time) {
                  final isSelected = selectedTime == time;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedTime = time),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF6E5616) : const Color(0xFFF6F0E7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        time,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    order.estimatedCompletionTime = selectedTime;
                    _handleAcceptOrder(order);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6E5616),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Confirm & Start Milling', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

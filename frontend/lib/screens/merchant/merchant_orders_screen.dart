import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/merchant_models.dart';
import '../../services/merchant_api_service.dart';
import '../../widgets/status_light.dart';
import 'merchant_order_process_detail_screen.dart';
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
  final Set<int> _completedIntakeOrderIds = {};

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
            _pendingOrders.addAll(fetchedActive.where((o) => o.statusTag == 'IN PROGRESS' || o.statusTag == 'IN_PROGRESS' || o.statusTag == 'PROCESSING' || o.statusTag == 'ACCEPTED' || o.statusTag == 'CONFIRMED' || o.statusTag == 'MILLING' || o.statusTag == 'PACKING' || o.statusTag == 'GRAIN_DROPPED' || o.statusTag == 'GRAIN DROPPED' || o.statusTag == 'RECEIVED_AT_MILL' || o.statusTag == 'PENDING'));
          }

          _completedMillingOrders.clear();
          if (fetchedReady != null) {
            _completedMillingOrders.addAll(fetchedReady.where((o) => o.statusTag != 'DELIVERED' && o.statusTag != 'COMPLETED' && o.statusTag != 'PICKED_UP'));
          }

          _deliveredOrders.clear();
          if (fetchedCompleted != null) {
            _deliveredOrders.addAll(fetchedCompleted.where((o) => o.statusTag == 'DELIVERED' || o.statusTag == 'COMPLETED' || o.statusTag == 'PICKED_UP'));
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

  void _showAcceptOrderTimeModal(BuildContext context, MerchantOrder order) {
    int selectedMins = 30;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Accept Order #${order.orderId}',
              style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select estimated milling & packing time for customer & driver:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [15, 30, 45, 60].map((mins) {
                      final isSelected = selectedMins == mins;
                      return ChoiceChip(
                        label: Text('$mins Mins'),
                        selected: isSelected,
                        selectedColor: const Color(0xFF6E5616),
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() => selectedMins = mins);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleAcceptOrder(order);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6E5616),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'CONFIRM & START MILLING ($selectedMins MINS)',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {

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
                  child: Material(
                    color: AppTheme.primaryTerracotta,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => _showExportModal(context),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
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
                  ),
                ),
              ],
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
                      StatusBadge(
                        status: order.statusTag,
                        label: order.statusTag,
                        type: 'order',
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        textStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
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
                          Icons.inventory_2_outlined,
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
                              'Products & Quantity',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              order.productBags.length > 1
                                  ? '${order.productBags.length} Products • ${order.quantityText}'
                                  : (order.productBags.isNotEmpty ? order.productBags.first.unitText : order.quantityText),
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
                  if (order.productBags.length > 1) ...[
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: order.productBags.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final bag = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF4EA),
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
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
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
      // 1. NEW: Accept, Decline with proof, or Scan & Inspect Incoming Grain
      return Column(
        children: [
          Row(
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
          ),
          const SizedBox(height: 8),
        ],
      );
    } else if (_selectedFilterTab == 1) {
      final bool isIntakeScanned = order.intakeStatus == 'ACCEPTED' ||
          (order.numericId != null && _completedIntakeOrderIds.contains(order.numericId)) ||
          order.statusTag == 'PROCESSING' ||
          order.statusTag == 'MILLING';

      if (isIntakeScanned) {
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () async {
              final orderId = order.numericId ?? 501;
              final messenger = ScaffoldMessenger.of(context);

              await MerchantApiService.instance.transitionOrderStatus(orderId, 'ready');

              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF1E8449),
                    content: Text('🎉 Milling Completed! Order ${order.orderId} is now ready for Leg 2 Pickup.'),
                  ),
                );
                setState(() {
                  _completedIntakeOrderIds.remove(orderId);
                  order.statusTag = 'READY FOR PICKUP';
                });
                _fetchOrdersData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E8449),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 1,
            ),
            icon: const Icon(Icons.check_circle_rounded, size: 20, color: Colors.white),
            label: Text(
              '⚙️ Complete Milling & Ready for Delivery',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      }

      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () async {
            final res = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => MillOwnerQrScannerScreen(order: order),
              ),
            );
            if (mounted) {
              if (res == true && order.numericId != null) {
                setState(() {
                  _completedIntakeOrderIds.add(order.numericId!);
                });
              }
              _fetchOrdersData();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryTerracotta,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 1,
          ),
          icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: Colors.white),
          label: Text(
            '🌾 Scan & Inspect Grain Bags (Accept / Reject)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else if (_selectedFilterTab == 2) {
      final isOutForDelivery = order.statusTag == 'OUT FOR DELIVERY' || order.statusTag == 'OUT_FOR_DELIVERY';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isOutForDelivery ? const Color(0xFFEBF5FB) : const Color(0xFFF9F5EF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isOutForDelivery ? const Color(0xFF85C1E9) : const Color(0xFFE8DFC8)),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isOutForDelivery ? Icons.two_wheeler_rounded : Icons.check_circle_outline_rounded,
                color: isOutForDelivery ? const Color(0xFF21618C) : const Color(0xFF6E5616),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isOutForDelivery ? 'Out for Delivery • Driver En Route to Customer' : 'Milling Complete • Ready for Pickup',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: isOutForDelivery ? const Color(0xFF21618C) : const Color(0xFF6E5616),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
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

  // --- EXPORT ORDERS FUNCTIONALITY ---

  String _getTabName(int index) {
    switch (index) {
      case 0: return 'NEW';
      case 1: return 'Pending';
      case 2: return 'Completed';
      case 3: return 'Delivered';
      default: return 'Orders';
    }
  }

  void _showExportModal(BuildContext context) {
    int exportScope = 0; // 0: Current Tab, 1: All Orders

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final scopeOrders = exportScope == 0
                ? _currentTabOrders
                : [..._newOrders, ..._pendingOrders, ..._completedMillingOrders, ..._deliveredOrders];
            final tabName = _getTabName(_selectedFilterTab);

            final totalWeight = scopeOrders.fold<double>(0, (sum, o) {
              final w = double.tryParse(o.quantityText.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
              return sum + w;
            });
            final totalPrice = scopeOrders.fold<double>(0, (sum, o) => sum + o.totalPrice);

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTerracotta.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.file_download_outlined, color: AppTheme.primaryTerracotta, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Export Orders Report',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Generate CSV summary for record keeping',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Select Scope',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: Text('$tabName (${scopeOrders.length})'),
                          selected: exportScope == 0,
                          onSelected: (val) {
                            setModalState(() => exportScope = 0);
                          },
                          selectedColor: AppTheme.primaryTerracotta.withValues(alpha: 0.15),
                          labelStyle: GoogleFonts.plusJakartaSans(
                            color: exportScope == 0 ? AppTheme.primaryTerracotta : AppTheme.textSecondary,
                            fontWeight: exportScope == 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: Text('All Orders (${_newOrders.length + _pendingOrders.length + _completedMillingOrders.length + _deliveredOrders.length})'),
                          selected: exportScope == 1,
                          onSelected: (val) {
                            setModalState(() => exportScope = 1);
                          },
                          selectedColor: AppTheme.primaryTerracotta.withValues(alpha: 0.15),
                          labelStyle: GoogleFonts.plusJakartaSans(
                            color: exportScope == 1 ? AppTheme.primaryTerracotta : AppTheme.textSecondary,
                            fontWeight: exportScope == 1 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Summary Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F6F0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildExportSummaryItem('Orders', '${scopeOrders.length}'),
                        _buildExportSummaryItem('Weight', '${totalWeight.toStringAsFixed(1)} kg'),
                        _buildExportSummaryItem('Value', '₹${totalPrice.toStringAsFixed(0)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _copyCSVToClipboard(context, scopeOrders);
                          },
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Copy CSV'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: AppTheme.primaryTerracotta,
                            side: const BorderSide(color: AppTheme.primaryTerracotta),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _exportOrdersToCSV(context, scopeOrders);
                          },
                          icon: const Icon(Icons.file_download_rounded, size: 18),
                          label: const Text('Export CSV'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: AppTheme.primaryTerracotta,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExportSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryTerracotta,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  String _generateCSV(List<MerchantOrder> orders) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('Order ID,Customer Name,Grain Type,Quantity,Total Price (₹),Status,Mill Name,Time');
    for (final o in orders) {
      final id = o.orderId;
      final name = '"${(o.customerName).replaceAll('"', '""')}"';
      final grain = '"${(o.grainType).replaceAll('"', '""')}"';
      final quantity = '"${(o.quantityText).replaceAll('"', '""')}"';
      final price = o.totalPrice;
      final status = '"${(o.statusTag).replaceAll('"', '""')}"';
      final mill = '"${(o.millName).replaceAll('"', '""')}"';
      final time = '"${(o.timeAgo).replaceAll('"', '""')}"';
      buffer.writeln('$id,$name,$grain,$quantity,$price,$status,$mill,$time');
    }
    return buffer.toString();
  }

  void _copyCSVToClipboard(BuildContext context, List<MerchantOrder> orders) {
    final csv = _generateCSV(orders);
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text('Copied CSV for ${orders.length} orders to clipboard!'),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _exportOrdersToCSV(BuildContext context, List<MerchantOrder> orders) {
    final csv = _generateCSV(orders);
    Clipboard.setData(ClipboardData(text: csv));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.file_download_done_rounded, color: AppTheme.primaryTerracotta, size: 28),
            const SizedBox(width: 8),
            Text(
              'Orders Report Exported',
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exported ${orders.length} orders report in CSV format! (Data copied to clipboard)',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              Text(
                'CSV Data Preview:',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F0E7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    csv,
                    style: GoogleFonts.firaCode(fontSize: 11, color: AppTheme.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csv));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('CSV copied to clipboard (${orders.length} orders)'),
                  backgroundColor: AppTheme.primaryTerracotta,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: Text('Copy CSV Data', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTerracotta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
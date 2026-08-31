import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/app_models.dart';
import '../models/merchant_models.dart';
import '../services/customer_api_service.dart';
import '../services/auth_api_service.dart';
import 'mill_detail_screen.dart';
import 'mills_list_screen.dart';
import 'order_tracking_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigateTab;
  final VoidCallback onStartNewOrder;
  final VoidCallback onOpenDrawer;

  const DashboardScreen({
    super.key,
    required this.onNavigateTab,
    required this.onStartNewOrder,
    required this.onOpenDrawer,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _refreshTimer;
  List<FlourMill>? _dynamicMills;
  List<MerchantOrder>? _dynamicOrders;
  int _activeOrderSliderIndex = 0;
  late PageController _activeOrderPageController;

  @override
  void initState() {
    super.initState();
    _activeOrderPageController = PageController();
    _loadDashboardData();
    // Poll updates every 15 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        _loadDashboardData(isBackground: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _activeOrderPageController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData({bool isBackground = false}) async {
    try {
      final millsFuture = CustomerApiService.instance.getNearbyMills();
      final ordersFuture = CustomerApiService.instance.getCustomerOrders();

      final results = await Future.wait([millsFuture, ordersFuture]);

      if (mounted) {
        setState(() {
          _dynamicMills = results[0] as List<FlourMill>?;
          _dynamicOrders = results[1] as List<MerchantOrder>?;
        });
      }
    } catch (_) {
      // Fallbacks will render gracefully
    }
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getUserDisplayName() {
    final user = AuthApiService.instance.currentUser;
    if (user != null && user['name'] != null && user['name'].toString().trim().isNotEmpty) {
      return user['name'].toString().split(' ').first;
    }
    return 'Sarah';
  }

  String _getProductImage(String summary) {
    final lower = summary.toLowerCase();
    if (lower.contains('wheat') || lower.contains('sharbati')) return 'assets/images/cat_wheat.jpg';
    if (lower.contains('rice')) return 'assets/images/cat_rice.jpg';
    if (lower.contains('millet') || lower.contains('bajra') || lower.contains('jowar')) return 'assets/images/cat_millet.jpg';
    if (lower.contains('spice') || lower.contains('masala')) return 'assets/images/cat_spices.jpg';
    return 'assets/images/cat_all.jpg';
  }

  List<Map<String, dynamic>> _createCartItemsFromOrder(dynamic order) {
    if (order is OrderModel && order.items.isNotEmpty) {
      return List<Map<String, dynamic>>.from(
        order.items.map((item) => Map<String, dynamic>.from(item)),
      );
    }
    final summary = order is OrderModel ? order.itemSummary : order.itemsSummary;
    final qtyStr = order is OrderModel ? order.quantityKg : order.quantityText;
    final qty = int.tryParse(qtyStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 5;
    final unitPrice = order is OrderModel ? (order.totalPrice / (qty > 0 ? qty : 1)) : (order.totalAmount / (qty > 0 ? qty : 1));

    List<Map<String, dynamic>> items = [];
    if (summary.contains(',')) {
      final parts = summary.split(',');
      for (final part in parts) {
        final clean = part.trim();
        if (clean.isNotEmpty) {
          items.add({
            'name': clean,
            'type': clean.toLowerCase().contains('pack') || clean.toLowerCase().contains('mix') ? 'product' : 'milling',
            'source': 'Own Grain',
            'quantity': 1,
            'price': 2.50,
          });
        }
      }
    } else {
      items.add({
        'name': summary,
        'type': summary.toLowerCase().contains('pack') || summary.toLowerCase().contains('mix') ? 'product' : 'milling',
        'source': 'Own Grain',
        'quantity': qty,
        'price': unitPrice > 0 ? unitPrice : 0.50,
      });
    }
    if (items.isEmpty) {
      items.add({
        'name': 'Wheat (Gehun) (Milling)',
        'type': 'milling',
        'source': 'Own Grain',
        'quantity': 5,
        'price': 0.50,
      });
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    // Resolve all active orders for the carousel slider
    final activeOrdersList = <OrderModel>[];
    if (_dynamicOrders != null && _dynamicOrders!.isNotEmpty) {
      for (final o in _dynamicOrders!) {
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

        if (isActive) {
          activeOrdersList.add(
            OrderModel(
              orderId: o.orderId,
              date: o.timeAgo,
              millName: o.millName.isNotEmpty ? o.millName : 'Artisan Mill Co.',
              itemSummary: o.itemsSummary,
              selectedGrain: o.grainType,
              quantityKg: o.quantityText,
              totalPrice: o.totalPrice,
              isActive: true,
              estimatedDelivery: 'Within 20 minutes',
              statusStep: o.statusTag,
              trackingSteps: [
                TrackingStep(title: 'Order Placed', subtitle: 'Received at mill', timeText: '10:00 AM', isCompleted: true),
                TrackingStep(title: 'Grain Cleaning', subtitle: 'Moisture checked', timeText: '10:15 AM', isCompleted: true),
                TrackingStep(title: 'Milling in Progress', subtitle: 'Stone chakki grinding', timeText: '10:30 AM', isCurrent: true),
                TrackingStep(title: 'Out for Delivery', subtitle: 'Assigned to driver', timeText: 'Pending'),
                TrackingStep(title: 'Delivered', subtitle: 'Doorstep handover', timeText: 'Pending'),
              ],
            ),
          );
        }
      }
    }

    if (activeOrdersList.isEmpty) {
      final fallbackActives = MockData.orders.where((o) => o.isActive).toList();
      activeOrdersList.addAll(fallbackActives);
    }

    // Resolve past orders
    final dynamicPastOrders = _dynamicOrders?.where((o) =>
        ['COMPLETED', 'DELIVERED'].contains(o.statusTag.toUpperCase())
    ).toList();

    final pastOrders = (dynamicPastOrders != null && dynamicPastOrders.isNotEmpty)
        ? dynamicPastOrders
        : MockData.orders.where((o) => !o.isActive).toList();

    // Resolve mills
    final millsList = (_dynamicMills != null && _dynamicMills!.isNotEmpty)
        ? _dynamicMills!
        : MockData.mills;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadDashboardData(),
          color: AppTheme.primaryTerracotta,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: AppTheme.textPrimary, size: 26),
                          onPressed: widget.onOpenDrawer,
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppTheme.mustardDark,
                          size: 24,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'HerDoor',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryTerracotta,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(
                              onNavigateTab: widget.onNavigateTab,
                              onOpenDrawer: widget.onOpenDrawer,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 44,
                        height: 44,
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
                  ],
                ),
                const SizedBox(height: 24),

                // Dynamic Greeting Section
                Text(
                  '${_getTimeGreeting()}, ${_getUserDisplayName()}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready for fresh flour today?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Active Orders Carousel Slider (Dynamic)
                _buildActiveOrdersSlider(activeOrdersList),
                const SizedBox(height: 20),

                // Quick Action Tiles: Start New Order & Recent Order
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.onStartNewOrder,
                        child: Container(
                          height: 110,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTerracotta,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.white,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start New Order',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onNavigateTab(2),
                        child: Container(
                          height: 110,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.history_rounded,
                                color: AppTheme.textPrimary,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Recent Order',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Recent Orders Section
                if (pastOrders.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Orders',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          widget.onNavigateTab(2); // Go to Orders tab
                        },
                        child: Text(
                          'See all',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryTerracotta,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pastOrders.length > 2 ? 2 : pastOrders.length,
                    itemBuilder: (context, index) {
                      final dynamic rawOrder = pastOrders[index];
                      final millTitle = rawOrder is MerchantOrder ? 'Artisan Mill Co.' : (rawOrder as OrderModel).millName;
                      final summaryText = rawOrder is MerchantOrder ? rawOrder.itemsSummary : (rawOrder as OrderModel).itemSummary;
                      final dateText = rawOrder is MerchantOrder ? rawOrder.timeAgo : (rawOrder as OrderModel).date;

                      return GestureDetector(
                        onTap: () {
                          final cartItems = _createCartItemsFromOrder(rawOrder);
                          int resolvedMillId = 101;
                          if (millTitle.toLowerCase().contains('navrang')) {
                            resolvedMillId = 102;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CartScreen(
                                cartItems: cartItems,
                                millName: millTitle,
                                millId: resolvedMillId,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderLight),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  _getProductImage(summaryText),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    width: 50,
                                    height: 50,
                                    color: AppTheme.surfaceWarm,
                                    child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryTerracotta, size: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            millTitle,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          dateText,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      summaryText,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // Flour Mills Near You Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Flour Mills Near You',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MillsListScreen(
                              onStartOrder: widget.onStartNewOrder,
                              showBackButton: true,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'See all',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryTerracotta,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // List of Flour Mills (Dynamic from Backend API)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: millsList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final mill = millsList[index];
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MillDetailScreen(
                                mill: mill,
                                onStartOrder: widget.onStartNewOrder,
                                heroTag: 'dashboard_mill_${mill.id}_$index',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCream,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Hero(
                                tag: 'dashboard_mill_${mill.id}_$index',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    mill.imageUrl,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 72,
                                      height: 72,
                                      color: AppTheme.surfaceWarm,
                                      child: const Icon(Icons.storefront, color: AppTheme.primaryTerracotta),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            mill.name,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: mill.isOpen
                                                ? AppTheme.mustardGold.withValues(alpha: 0.2)
                                                : Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            mill.statusText,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: mill.isOpen ? AppTheme.mustardDark : Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_outline_rounded, size: 16, color: AppTheme.mustardDark),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${mill.rating} (${mill.distanceKm} km)',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      mill.specialty,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveOrdersSlider(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return _buildNoActiveOrderCard();
    }

    return Column(
      children: [
        SizedBox(
          height: 185,
          child: PageView.builder(
            controller: _activeOrderPageController,
            physics: const PageScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            itemCount: orders.length,
            onPageChanged: (index) {
              setState(() => _activeOrderSliderIndex = index);
            },
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildActiveOrderCard(order);
            },
          ),
        ),
        if (orders.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(orders.length, (i) {
              final isCurrent = i == _activeOrderSliderIndex;
              return GestureDetector(
                onTap: () {
                  _activeOrderPageController.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isCurrent ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isCurrent ? AppTheme.primaryTerracotta : AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildActiveOrderCard(OrderModel order) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderTrackingScreen(order: order),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.mustardGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ACTIVE ORDER',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.mustardDark,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Text(
                  order.orderId,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTerracotta,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order.itemSummary} • ${order.quantityKg}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    height: 1.25,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${order.millName} — ${order.statusStep}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.mustardDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Delivery: ${order.estimatedDelivery}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tap to track live order',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTerracotta,
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.primaryTerracotta),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoActiveOrderCard() {
    return GestureDetector(
      onTap: widget.onStartNewOrder,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
          children: [
            const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryTerracotta, size: 36),
            const SizedBox(height: 10),
            Text(
              'No Active Orders',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Order fresh stone-milled flour delivered directly to your home.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


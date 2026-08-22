import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/app_models.dart';
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


  String _getProductImage(String summary) {
    final lower = summary.toLowerCase();
    if (lower.contains('wheat') || lower.contains('sharbati')) return 'assets/images/cat_wheat.jpg';
    if (lower.contains('rice')) return 'assets/images/cat_rice.jpg';
    if (lower.contains('millet')) return 'assets/images/cat_millet.jpg';
    if (lower.contains('spice')) return 'assets/images/cat_spices.jpg';
    return 'assets/images/cat_all.jpg';
  }

  List<Map<String, dynamic>> _createCartItemsFromOrder(OrderModel order) {
    if (order.items.isNotEmpty) {
      return List<Map<String, dynamic>>.from(
        order.items.map((item) => Map<String, dynamic>.from(item)),
      );
    }
    List<Map<String, dynamic>> items = [];
    final names = order.itemSummary.split(', ');
    for (var name in names) {
      final cleanName = name.trim();
      if (cleanName.isEmpty) continue;
      if (cleanName.toLowerCase().contains('milling')) {
        items.add({
          'name': cleanName,
          'type': 'milling',
          'source': 'Own Grain',
          'quantity': 5,
          'price': 0.50,
        });
      } else {
        items.add({
          'name': cleanName,
          'type': 'readymade',
          'quantity': 1,
          'price': cleanName.toLowerCase().contains('masala') ? 3.00 : 2.50,
        });
      }
    }
    if (items.isEmpty) {
      items.add({
        'name': order.selectedGrain.isNotEmpty ? order.selectedGrain : 'Whole Wheat (Milling)',
        'type': 'milling',
        'source': 'Own Grain',
        'quantity': 5,
        'price': 0.50,
      });
    }
    return items;
  }

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pastOrders = MockData.orders.where((o) => !o.isActive).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
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

              // Greeting Section
              Text(
                'Good morning, Sarah',
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

              // Active Order Banner Card (Dynamic from MockData)
              Builder(
                builder: (context) {
                  final activeOrders = MockData.orders.where((o) => o.isActive).toList();
                  final hasActive = activeOrders.isNotEmpty;
                  final activeOrder = hasActive ? activeOrders.first : null;

                  return GestureDetector(
                    onTap: () {
                      if (hasActive && activeOrder != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderTrackingScreen(order: activeOrder),
                          ),
                        );
                      } else {
                        widget.onStartNewOrder();
                      }
                    },
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
                      child: hasActive && activeOrder != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                      activeOrder.orderId,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryTerracotta,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${activeOrder.itemSummary} • ${activeOrder.quantityKg}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${activeOrder.millName} — ${activeOrder.statusStep}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.mustardDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Delivery: ${activeOrder.estimatedDelivery}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
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
                            )
                          : Column(
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
                },
              ),
              const SizedBox(height: 20),

              // Quick Action Tiles: Start New Order & Repeat Last Order
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
                        widget.onNavigateTab(2); // Go to Track/Orders tab
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
                    final order = pastOrders[index];
                    return GestureDetector(
                      onTap: () {
                        final cartItems = _createCartItemsFromOrder(order);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CartScreen(
                              cartItems: cartItems,
                              millName: order.millName,
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
                                _getProductImage(order.itemSummary),
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
                                          order.millName,
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
                                        order.date,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${order.itemSummary} • ${order.quantityKg}',
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

              // List of Flour Mills
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: MockData.mills.length,
                separatorBuilder: (context, index) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final mill = MockData.mills[index];
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
                              heroTag: 'dashboard_mill_${mill.id}',
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
                              tag: 'dashboard_mill_${mill.id}',
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
    );
  }
}

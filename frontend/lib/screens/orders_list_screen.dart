import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/app_models.dart';
import 'order_tracking_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class OrdersListScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  const OrdersListScreen({super.key, this.onOpenDrawer});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  bool _showActiveOrders = true;

  @override
  Widget build(BuildContext context) {
    final activeOrders = MockData.orders.where((o) => o.isActive).toList();
    final pastOrders = MockData.orders.where((o) => !o.isActive).toList();
    
    final displayOrders = _showActiveOrders ? activeOrders : pastOrders;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppTheme.textPrimary),
          onPressed: widget.onOpenDrawer,
        ),
        title: Text(
          'HerDoor Flour Mill',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryTerracotta,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
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
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order History',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Toggle Switch
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showActiveOrders = true),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _showActiveOrders ? AppTheme.primaryTerracotta : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          'Current',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            color: _showActiveOrders ? Colors.white : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showActiveOrders = false),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: !_showActiveOrders ? AppTheme.primaryTerracotta : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          'Previous',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            color: !_showActiveOrders ? Colors.white : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            if (displayOrders.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: Text(
                    'No ${_showActiveOrders ? 'current' : 'previous'} orders.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              )
            else
              ...displayOrders.asMap().entries.map((entry) => _buildOrderCard(context, entry.value, entry.key)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order, int index) {
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
          if (order.isActive) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderTrackingScreen(order: order),
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
                  Text(
                    order.orderId,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTerracotta,
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
              const SizedBox(height: 12),
              Text(
                order.millName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${order.itemSummary} • ${order.quantityKg}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: order.isActive 
                          ? AppTheme.mustardGold.withValues(alpha: 0.2)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.statusStep,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: order.isActive 
                            ? AppTheme.mustardDark 
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  Text(
                    '\$${order.totalPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              if (order.isActive) ...[
                const SizedBox(height: 16),
                const Divider(color: AppTheme.borderLight, height: 1),
                const SizedBox(height: 14),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Tap to Track Order',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryTerracotta,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppTheme.primaryTerracotta),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                const Divider(color: AppTheme.borderLight, height: 1),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTerracotta,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
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
                    icon: const Icon(Icons.repeat_rounded, size: 18),
                    label: Text(
                      'Repeat Order',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
}

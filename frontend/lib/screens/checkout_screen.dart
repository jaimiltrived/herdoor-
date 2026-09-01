import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'payment_methods_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final String millName;
  final int millId;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.millName,
    this.millId = 101,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int get effectiveMillId {
    if (widget.millId != 101) return widget.millId;
    if (widget.millName.toLowerCase().contains('navrang')) return 102;
    return widget.millId;
  }
  Map<String, String> _selectedAddress = {
    'title': 'Home',
    'address': '456 Heritage Block, District 9, NY',
    'icon': 'home',
  };

  final List<Map<String, String>> _mockAddresses = [
    {'title': 'Home', 'address': '456 Heritage Block, District 9, NY', 'icon': 'home'},
    {'title': 'Work', 'address': '123 Tech Park, Silicon Ave, NY', 'icon': 'work'},
    {'title': 'Parents', 'address': '789 Old Town Road, NY', 'icon': 'location_on'},
  ];

  void _showAddressPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Delivery Address',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ..._mockAddresses.map((addr) {
                bool isSelected = _selectedAddress['title'] == addr['title'];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    addr['icon'] == 'home' ? Icons.home_work_outlined : (addr['icon'] == 'work' ? Icons.work_outline : Icons.location_on_outlined),
                    color: isSelected ? AppTheme.primaryTerracotta : AppTheme.textSecondary,
                  ),
                  title: Text(addr['title']!, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                  subtitle: Text(addr['address']!, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryTerracotta) : null,
                  onTap: () {
                    setState(() {
                      _selectedAddress = addr;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppTheme.primaryTerracotta),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add, color: AppTheme.primaryTerracotta),
                  label: Text('Add New Address', style: GoogleFonts.plusJakartaSans(color: AppTheme.primaryTerracotta, fontWeight: FontWeight.bold)),
                  onPressed: () {
                     Navigator.pop(context);
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add address flow coming soon.')));
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    },
    );
  }

  bool get _requiresPickup {
    return widget.cartItems.any((item) => item['type'] == 'milling' && item['source'] == 'Own Grain');
  }

  double get _subtotal {
    return widget.cartItems.fold(0.0, (total, item) => total + (item['price'] * item['quantity']));
  }

  double get _deliveryFee => 2.00;
  double get _pickupFee => _requiresPickup ? 1.50 : 0.0;
  double get _total => _subtotal + _deliveryFee + _pickupFee;

  Widget _buildInvoiceRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? AppTheme.primaryTerracotta : AppTheme.textPrimary,
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
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(
          'Checkout',
          style: GoogleFonts.playfairDisplay(color: AppTheme.primaryTerracotta, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address Section
            Text('Delivery Address', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedAddress['icon'] == 'home' ? Icons.home_work_outlined : (_selectedAddress['icon'] == 'work' ? Icons.work_outline : Icons.location_on_outlined), 
                    color: AppTheme.primaryTerracotta
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedAddress['title']!, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                        Text(_selectedAddress['address']!, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  TextButton(onPressed: _showAddressPicker, child: const Text('Change')),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Invoice Section
            Text('Invoice Summary', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                children: [
                  _buildInvoiceRow('Subtotal (${widget.cartItems.length} items)', '\$${_subtotal.toStringAsFixed(2)}'),
                  if (_requiresPickup) _buildInvoiceRow('Pickup Fee', '\$${_pickupFee.toStringAsFixed(2)}'),
                  _buildInvoiceRow('Delivery Fee', '\$${_deliveryFee.toStringAsFixed(2)}'),
                  const Divider(height: 24),
                  _buildInvoiceRow('Grand Total', '\$${_total.toStringAsFixed(2)}', isTotal: true),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Notice after Invoice Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWarm,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryTerracotta.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTerracotta.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.access_time_filled_rounded,
                      color: AppTheme.primaryTerracotta,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pickup & Processing Notice',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryTerracotta,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'It will be picked up within 24 hours. Our representative will contact you prior to arrival.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTerracotta,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PaymentMethodsScreen(
                    cartItems: widget.cartItems,
                    millName: widget.millName,
                    millId: effectiveMillId,
                    subtotal: _subtotal,
                    pickupFee: _pickupFee,
                    deliveryFee: _deliveryFee,
                    total: _total,
                    pickupTime: 'Within 24 Hours',
                    address: _selectedAddress['address'] ?? 'Home',
                  )),
                );
              },
              child: Text(
                'Proceed to Payment (\$${_total.toStringAsFixed(2)})',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

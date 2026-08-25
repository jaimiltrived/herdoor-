import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/customer_api_service.dart';
import 'invoice_screen.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final String millName;
  final double subtotal;
  final double pickupFee;
  final double deliveryFee;
  final double total;
  final String pickupTime;
  final String address;

  const PaymentMethodsScreen({
    super.key,
    this.cartItems = const [],
    this.millName = 'Shree Ganesh Flour Mill',
    this.subtotal = 0.0,
    this.pickupFee = 0.0,
    this.deliveryFee = 0.0,
    this.total = 0.0,
    this.pickupTime = 'Within 24 Hours',
    this.address = '456 Heritage Block, District 9, NY',
  });

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  int _selectedMethod = 0;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _methods = [
    {
      'icon': Icons.credit_card,
      'title': 'Visa Card',
      'subtitle': '•••• •••• •••• 4242',
      'type': 'card',
    },
    {
      'icon': Icons.account_balance_wallet,
      'title': 'Apple Pay',
      'subtitle': 'applepay@icloud.com',
      'type': 'wallet',
    },
    {
      'icon': Icons.money,
      'title': 'Cash on Delivery',
      'subtitle': 'Pay when you receive',
      'type': 'cash',
    },
  ];

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
          'Payment',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryTerracotta,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Amount',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${widget.total.toStringAsFixed(2)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Select Payment Method',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(_methods.length, (index) {
              final method = _methods[index];
              final isSelected = _selectedMethod == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedMethod = index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryTerracotta : AppTheme.borderLight,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryTerracotta.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.surfaceWarm : AppTheme.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          method['icon'],
                          color: isSelected ? AppTheme.primaryTerracotta : AppTheme.textSecondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method['title'],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              method['subtitle'],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryTerracotta,
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, color: AppTheme.primaryTerracotta),
              label: Text(
                'Add New Card',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryTerracotta,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                side: const BorderSide(color: AppTheme.primaryTerracotta),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: _isProcessing
                ? null
                : () async {
                    final navigator = Navigator.of(context);
                    setState(() => _isProcessing = true);
                    String paymentStr = _methods[_selectedMethod]['title'] == 'Visa Card'
                        ? 'Visa Card (•••• 4242)'
                        : _methods[_selectedMethod]['title'];

                    // Call backend place order endpoint
                    final placedOrder = await CustomerApiService.instance.placeOrder(
                      millId: 101,
                      items: widget.cartItems,
                      grainTypeName: widget.cartItems.isNotEmpty ? widget.cartItems[0]['name'] : 'Wheat',
                      totalAmount: widget.total,
                      pickupFee: widget.pickupFee,
                      deliveryFee: widget.deliveryFee,
                      paymentMethod: paymentStr,
                      address: widget.address,
                    );

                    if (!mounted) return;
                    setState(() => _isProcessing = false);
                    navigator.push(
                      MaterialPageRoute(
                        builder: (context) => InvoiceScreen(
                          orderNumber: placedOrder?.orderId,
                          cartItems: widget.cartItems,
                          millName: widget.millName,
                          subtotal: widget.subtotal,
                          pickupFee: widget.pickupFee,
                          deliveryFee: widget.deliveryFee,
                          total: widget.total,
                          pickupTime: widget.pickupTime,
                          address: widget.address,
                          paymentMethod: paymentStr,
                        ),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTerracotta,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    'Pay \$${widget.total.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

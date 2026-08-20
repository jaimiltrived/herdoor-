import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/app_models.dart';
import 'order_tracking_screen.dart';

class InvoiceScreen extends StatelessWidget {
  final int grainSource;
  final String selectedGrain;
  final int quantityKg;
  final String millName;
  final String pickupLocation;
  final String dropLocation;
  final String paymentMethod;

  const InvoiceScreen({
    super.key,
    this.grainSource = 1,
    this.selectedGrain = 'Premium Wheat',
    this.quantityKg = 5,
    this.millName = 'Artisan Mill Co.',
    this.pickupLocation = 'Home - 124 Heritage Way',
    this.dropLocation = 'Home - 124 Heritage Way',
    this.paymentMethod = 'Visa Card (•••• 4242)',
  });

  @override
  Widget build(BuildContext context) {
    final double millingRate = 1.50; // per kg
    final double grainRatePerKg = grainSource == 2 ? 2.50 : 0.0;
    
    final double grainSubtotal = grainRatePerKg * quantityKg;
    final double millingSubtotal = millingRate * quantityKg;
    final double deliveryFee = grainSource == 1 ? 3.00 : 2.50;
    final double tax = (grainSubtotal + millingSubtotal) * 0.05;
    final double grandTotal = grainSubtotal + millingSubtotal + deliveryFee + tax;

    final String receiptId = '#HD-${1000 + Random().nextInt(8999)}';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Order Invoice',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryTerracotta,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        millName,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryTerracotta,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Receipt $receiptId',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(color: AppTheme.borderLight, height: 1),
                    ),
                    _buildInvoiceRow('Service Type', grainSource == 1 ? 'Home Pickup & Milling' : 'Mill Purchase & Milling'),
                    const SizedBox(height: 12),
                    _buildInvoiceRow('Grain', selectedGrain),
                    const SizedBox(height: 12),
                    _buildInvoiceRow('Quantity', '$quantityKg kg'),
                    const SizedBox(height: 12),
                    _buildInvoiceRow('Drop Address', dropLocation),
                    const SizedBox(height: 12),
                    _buildInvoiceRow('Payment Method', paymentMethod),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(color: AppTheme.borderLight, height: 1),
                    ),
                    if (grainSource == 2) ...[
                      _buildInvoiceRow('Grain Price ($quantityKg kg @ \$2.50/kg)', '\$${grainSubtotal.toStringAsFixed(2)}'),
                      const SizedBox(height: 12),
                    ],
                    _buildInvoiceRow('Milling Charge ($quantityKg kg @ \$1.50/kg)', '\$${millingSubtotal.toStringAsFixed(2)}'),
                    const SizedBox(height: 12),
                    _buildInvoiceRow(grainSource == 1 ? 'Pickup & Delivery Fee' : 'Delivery Fee', '\$${deliveryFee.toStringAsFixed(2)}'),
                    const SizedBox(height: 12),
                    _buildInvoiceRow('Tax (5%)', '\$${tax.toStringAsFixed(2)}'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(color: AppTheme.borderLight, height: 1, thickness: 1.5),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '\$${grandTotal.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryTerracotta,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Place Order Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    final newOrder = OrderModel(
                      orderId: receiptId,
                      millName: millName,
                      itemSummary: selectedGrain,
                      quantityKg: '$quantityKg kg',
                      estimatedDelivery: 'Today, by 6:00 PM',
                      statusStep: 'Order Confirmed',
                      totalPrice: grandTotal,
                      isActive: true,
                      date: 'Just Now',
                      selectedGrain: selectedGrain,
                      grainSource: grainSource,
                      pickupAddress: pickupLocation,
                      deliveryAddress: dropLocation,
                      paymentMethod: paymentMethod,
                      millingFee: millingSubtotal,
                      deliveryFee: deliveryFee,
                      trackingSteps: [
                        TrackingStep(
                          title: 'Order Confirmed',
                          subtitle: 'We have received your order request.',
                          timeText: 'Just Now',
                          isCompleted: true,
                          isCurrent: true,
                        ),
                        if (grainSource == 1)
                          TrackingStep(
                            title: 'Collection from Home',
                            subtitle: 'Empty container pickup scheduled.',
                            timeText: '',
                            isCompleted: false,
                          ),
                        TrackingStep(
                          title: 'Arrival at Shop',
                          subtitle: 'Container ready for cold-milling.',
                          timeText: '',
                          isCompleted: false,
                        ),
                        TrackingStep(
                          title: 'Milling in Progress',
                          subtitle: 'Fresh stone cold-pressed milling.',
                          timeText: '',
                          isCompleted: false,
                        ),
                        TrackingStep(
                          title: 'Packaging',
                          subtitle: 'Filling your container securely.',
                          timeText: '',
                          isCompleted: false,
                        ),
                        TrackingStep(
                          title: 'Dispatched',
                          subtitle: 'Order leaves the mill.',
                          timeText: '',
                          isCompleted: false,
                        ),
                        TrackingStep(
                          title: 'Delivered',
                          subtitle: 'Fresh flour arrives home.',
                          timeText: '',
                          isCompleted: false,
                        ),
                      ],
                    );
                    
                    // Insert into MockData.orders
                    MockData.orders.insert(0, newOrder);

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderTrackingScreen(order: newOrder),
                      ),
                      (Route<dynamic> route) => route.isFirst,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.mustardDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  child: Text(
                    'Place Order',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            color: AppTheme.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

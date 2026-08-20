import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/app_models.dart';
import 'invoice_screen.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final int grainSource;
  final String selectedGrain;
  final int quantityKg;
  final String millName;
  final String pickupLocation;
  final String dropLocation;

  const PaymentMethodsScreen({
    super.key,
    this.grainSource = 1,
    this.selectedGrain = 'Premium Wheat',
    this.quantityKg = 5,
    this.millName = 'Artisan Mill Co.',
    this.pickupLocation = 'Home - 124 Heritage Way',
    this.dropLocation = 'Home - 124 Heritage Way',
  });

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  int _selectedMethod = 0;

  void _showAddCardDialog() {
    final titleController = TextEditingController();
    final numberController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add New Payment Card',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Cardholder Name / Bank',
                hintText: 'e.g. Chase Visa',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: numberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Card Number (Last 4 digits)',
                hintText: 'e.g. 5521',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (numberController.text.trim().isNotEmpty) {
                final cardName = titleController.text.trim().isEmpty ? 'Debit Card' : titleController.text.trim();
                final last4 = numberController.text.trim();
                setState(() {
                  MockData.paymentMethods.add({
                    'title': cardName,
                    'subtitle': '•••• •••• •••• $last4 (Expires 12/29)',
                    'icon': 'credit_card',
                  });
                  _selectedMethod = MockData.paymentMethods.length - 1;
                });
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTerracotta),
            child: const Text('Save Card', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final methods = MockData.paymentMethods;
    if (_selectedMethod >= methods.length) _selectedMethod = 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Payment Methods',
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
              Text(
                'Select Default Payment',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose how you would like to pay for milling and grain purchases.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: methods.length,
                separatorBuilder: (context, index) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = methods[index];
                  final isSelected = index == _selectedMethod;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMethod = index),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.surfaceWarm : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryTerracotta : AppTheme.borderLight,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryTerracotta : AppTheme.surfaceCream,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item['icon'] == 'payments'
                                  ? Icons.payments_outlined
                                  : (item['icon'] == 'account_balance_wallet'
                                      ? Icons.account_balance_wallet_outlined
                                      : Icons.credit_card_rounded),
                              color: isSelected ? Colors.white : AppTheme.primaryTerracotta,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['subtitle']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.mustardGold,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, size: 16, color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _showAddCardDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryTerracotta,
                    side: const BorderSide(color: AppTheme.primaryTerracotta, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  icon: const Icon(Icons.add_card_rounded),
                  label: Text(
                    'Add New Payment Card',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Review Order Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    final selectedPayment = methods[_selectedMethod];
                    final paymentStr = '${selectedPayment['title']} (${selectedPayment['subtitle']})';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InvoiceScreen(
                          grainSource: widget.grainSource,
                          selectedGrain: widget.selectedGrain,
                          quantityKg: widget.quantityKg,
                          millName: widget.millName,
                          pickupLocation: widget.pickupLocation,
                          dropLocation: widget.dropLocation,
                          paymentMethod: paymentStr,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTerracotta,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  child: Text(
                    'Review Order (Invoice)',
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
}

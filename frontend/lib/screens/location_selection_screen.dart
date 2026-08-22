import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/app_models.dart';
import 'payment_methods_screen.dart';

class LocationSelectionScreen extends StatefulWidget {
  final int grainSource; // 1 = Own grain, 2 = Buy from mill
  final String selectedGrain;
  final int quantityKg;
  final String millName;

  const LocationSelectionScreen({
    super.key,
    required this.grainSource,
    this.selectedGrain = 'Premium Wheat',
    this.quantityKg = 5,
    this.millName = 'Artisan Mill Co.',
  });

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  late String _pickupLocation;
  late String _dropLocation;

  @override
  void initState() {
    super.initState();
    final addresses = MockData.savedAddresses;
    _pickupLocation = addresses.first;
    _dropLocation = addresses.first;
  }

  @override
  Widget build(BuildContext context) {
    final addresses = MockData.savedAddresses;
    if (!addresses.contains(_pickupLocation)) _pickupLocation = addresses.first;
    if (!addresses.contains(_dropLocation)) _dropLocation = addresses.first;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Location',
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
                'Where should we go?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.grainSource == 1
                    ? 'Please provide locations for collecting your grains and delivering your fresh flour.'
                    : 'Please provide the location for delivering your fresh flour.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 30),

              // PICKUP LOCATION (Only if Grain Source is 1 - Own grain)
              if (widget.grainSource == 1) ...[
                _buildSectionHeader('Pickup Location', Icons.unarchive_outlined),
                const SizedBox(height: 12),
                _buildAddressDropdown(
                  value: _pickupLocation,
                  addresses: addresses,
                  onChanged: (val) => setState(() => _pickupLocation = val!),
                ),
                const SizedBox(height: 30),
              ],

              // DROP LOCATION (Always shown)
              _buildSectionHeader('Drop Location', Icons.archive_outlined),
              const SizedBox(height: 12),
              _buildAddressDropdown(
                value: _dropLocation,
                addresses: addresses,
                onChanged: (val) => setState(() => _dropLocation = val!),
              ),
              const SizedBox(height: 40),

              // Proceed to Payment Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PaymentMethodsScreen(),
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
                    'Proceed to Payment',
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryTerracotta, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressDropdown({
    required String value,
    required List<String> addresses,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: addresses.contains(value) ? value : addresses.first,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
          items: addresses.map((String address) {
            return DropdownMenuItem<String>(
              value: address,
              child: Text(
                address,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

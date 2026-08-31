import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/app_models.dart';
import '../services/customer_api_service.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  int _defaultIndex = 0;
  bool _isLoading = true;

  List<Map<String, String>> _addresses = [
    {
      'type': 'Home',
      'address': 'Flat 402, Shivalik Towers, Satellite Road',
      'city': 'Ahmedabad, Gujarat - 380015',
      'phone': '+91 98765 43210',
    },
    {
      'type': 'Office',
      'address': 'Office 301, Pinnacle Business Park, Prahlad Nagar',
      'city': 'Ahmedabad, Gujarat - 380015',
      'phone': '+91 98765 43210',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final fetched = await CustomerApiService.instance.getAddresses();
    if (fetched != null && fetched.isNotEmpty) {
      final List<Map<String, String>> parsed = [];
      int defIdx = 0;
      for (int i = 0; i < fetched.length; i++) {
        final item = fetched[i];
        final type = (item['addressLine2']?.toString().isNotEmpty == true)
            ? item['addressLine2'].toString()
            : (i == 0 ? 'Home' : 'Office');
        final line1 = item['addressLine1']?.toString() ?? '';
        final city = '${item['city'] ?? ''}, ${item['state'] ?? 'Gujarat'} ${item['pincode'] ?? ''}'.trim();
        if (item['isDefault'] == true) defIdx = i;

        parsed.add({
          'type': type,
          'address': line1,
          'city': city,
          'phone': '+91 98765 43210',
        });
      }

      if (mounted) {
        setState(() {
          _addresses = parsed;
          _defaultIndex = defIdx;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddAddressDialog() {
    final titleController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final pincodeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Address',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryTerracotta,
              ),
            ),
            const SizedBox(height: 16),
            _buildDialogInput(titleController, 'Address Label (e.g. Home, Office)', Icons.label_outline),
            const SizedBox(height: 12),
            _buildDialogInput(addressController, 'Street Address & Apt Number', Icons.location_on_outlined),
            const SizedBox(height: 12),
            _buildDialogInput(cityController, 'City (e.g. Ahmedabad)', Icons.map_outlined),
            const SizedBox(height: 12),
            _buildDialogInput(pincodeController, 'Pincode (e.g. 380015)', Icons.pin_drop_outlined, keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final nav = Navigator.of(context);
                  if (addressController.text.isNotEmpty) {
                    final type = titleController.text.isEmpty ? 'Other' : titleController.text;
                    final addrText = addressController.text;
                    final cityText = cityController.text.isEmpty ? 'Ahmedabad' : cityController.text;
                    final pinText = pincodeController.text.isEmpty ? '380015' : pincodeController.text;

                    await CustomerApiService.instance.addAddress(
                      addressLine1: addrText,
                      addressLine2: type,
                      city: cityText,
                      pincode: pinText,
                    );

                    if (mounted) {
                      setState(() {
                        _addresses.add({
                          'type': type,
                          'address': addrText,
                          'city': '$cityText, Gujarat $pinText',
                          'phone': '+91 98765 43210',
                        });
                        MockData.savedAddresses.add('$type - $addrText');
                      });
                    }
                  }
                  nav.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTerracotta,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                ),
                child: Text(
                  'Save Address',
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
    );
  }

  Widget _buildDialogInput(TextEditingController controller, String hint, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppTheme.primaryTerracotta),
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primaryTerracotta, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Saved Addresses',
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
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(color: AppTheme.primaryTerracotta, minHeight: 2),
                ),
              Text(
                'Delivery Locations',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select your default delivery address for fresh flour collection & dropoff.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _addresses.length,
                separatorBuilder: (context, index) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = _addresses[index];
                  final isDefault = index == _defaultIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _defaultIndex = index),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDefault ? AppTheme.surfaceWarm : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDefault ? AppTheme.primaryTerracotta : AppTheme.borderLight,
                          width: isDefault ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDefault ? AppTheme.primaryTerracotta : AppTheme.surfaceCream,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item['type'] == 'Home'
                                  ? Icons.home_outlined
                                  : (item['type'] == 'Office' ? Icons.business_outlined : Icons.location_on_outlined),
                              color: isDefault ? Colors.white : AppTheme.primaryTerracotta,
                              size: 22,
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
                                    Text(
                                      item['type']!,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    if (isDefault)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppTheme.mustardGold,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'Default',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item['address']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  item['city']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['phone']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                  ),
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
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _showAddAddressDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTerracotta,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(
                    'Add New Address',
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/merchant_api_service.dart';

class MerchantStoreDetailsScreen extends StatefulWidget {
  const MerchantStoreDetailsScreen({super.key});

  @override
  State<MerchantStoreDetailsScreen> createState() => _MerchantStoreDetailsScreenState();
}

class _MerchantStoreDetailsScreenState extends State<MerchantStoreDetailsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers
  final _nameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _capacityController = TextEditingController();
  final _radiusController = TextEditingController();
  final _hoursController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _storeImageController = TextEditingController();
  final _chakkiImageController = TextEditingController();

  bool _isOpen = true;
  bool _expressDelivery = true;
  bool _selfPickup = true;

  final List<String> _allServices = [
    'Flour Grinding',
    'Packing',
    'Home Delivery',
    'Cleaning',
    'Grain Sorting',
    'Custom Spice Grinding'
  ];
  List<String> _selectedServices = ['Flour Grinding', 'Packing', 'Home Delivery'];

  @override
  void initState() {
    super.initState();
    _loadStoreDetails();
  }

  Future<void> _loadStoreDetails() async {
    setState(() => _isLoading = true);
    final data = await MerchantApiService.instance.getStoreDetails();
    if (data != null && mounted) {
      final mill = data['mill'] ?? {};
      final user = data['user'] ?? {};

      _nameController.text = mill['name']?.toString() ?? 'Shree Ganesh Flour Mill';
      _ownerNameController.text = user['name']?.toString() ?? 'Suresh Mill Owner';
      _phoneController.text = mill['phone']?.toString() ?? user['phone']?.toString() ?? '+919876543211';
      _emailController.text = user['email']?.toString() ?? 'shop@shreeganesh.com';
      _addressController.text = mill['address']?.toString() ?? '12 Market Yard, Ellisbridge, Ahmedabad';
      _cityController.text = mill['city']?.toString() ?? 'Ahmedabad';
      _pincodeController.text = mill['pincode']?.toString() ?? '380006';
      _capacityController.text = (mill['capacityKgPerDay'] ?? 600).toString();
      _radiusController.text = (mill['deliveryRadiusKm'] ?? 5.0).toString();
      _hoursController.text = mill['workingHours']?.toString() ?? '08:00 AM - 08:00 PM';
      _specialtyController.text = mill['specialty']?.toString() ?? 'Fresh Stone Ground Flour & Custom Milling';
      _storeImageController.text = mill['storeImage']?.toString() ?? 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80';
      _chakkiImageController.text = mill['chakkiImage']?.toString() ?? 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&w=600&q=80';

      _isOpen = mill['isOpen'] != false;
      _expressDelivery = mill['expressDeliveryEnabled'] != false;
      _selfPickup = mill['selfPickupEnabled'] != false;

      if (mill['services'] is List) {
        _selectedServices = List<String>.from(mill['services']);
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    if (name.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store Name and Address cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final success = await MerchantApiService.instance.updateStoreDetails(
      storeName: name,
      ownerName: _ownerNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: address,
      city: _cityController.text.trim(),
      pincode: _pincodeController.text.trim(),
      capacityKgPerDay: double.tryParse(_capacityController.text.trim()) ?? 500,
      deliveryRadiusKm: double.tryParse(_radiusController.text.trim()) ?? 5.0,
      workingHours: _hoursController.text.trim(),
      services: _selectedServices,
      specialty: _specialtyController.text.trim(),
      storeImage: _storeImageController.text.trim(),
      chakkiImage: _chakkiImageController.text.trim(),
      isOpen: _isOpen,
      expressDeliveryEnabled: _expressDelivery,
      selfPickupEnabled: _selfPickup,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Store details saved and updated successfully!'),
          backgroundColor: Color(0xFF2ECC71),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update store details')),
      );
    }
  }

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
          'Store Details & Profile',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryTerracotta,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _handleSave,
            icon: const Icon(Icons.check_rounded, color: AppTheme.primaryTerracotta, size: 18),
            label: Text(
              'Save',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryTerracotta,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryTerracotta))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store Hero Preview Card
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderLight),
                      image: DecorationImage(
                        image: NetworkImage(
                          _storeImageController.text.isNotEmpty
                              ? _storeImageController.text
                              : 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.75),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.bottomLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameController.text.isNotEmpty ? _nameController.text : 'Store Name',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _specialtyController.text,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isOpen ? const Color(0xFF2ECC71) : Colors.grey[700],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _isOpen ? 'OPEN' : 'CLOSED',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Store Status Toggles
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: _isOpen,
                          activeTrackColor: const Color(0xFF2ECC71),
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Store Open for Orders',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Toggle online store accepting customer milling orders',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          onChanged: (val) => setState(() => _isOpen = val),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          value: _expressDelivery,
                          activeTrackColor: AppTheme.primaryTerracotta,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Express Home Delivery',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Enable door-to-door rider pickup and delivery',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          onChanged: (val) => setState(() => _expressDelivery = val),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          value: _selfPickup,
                          activeTrackColor: const Color(0xFF6E5616),
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Counter Self-Pickup',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Allow customers to collect fresh flour directly from store bins',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          onChanged: (val) => setState(() => _selfPickup = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Store Identity
                  _buildSectionHeader('Store Identity & Contacts', Icons.storefront_rounded),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _nameController, label: 'Store / Mill Name *', hint: 'Shree Ganesh Flour Mill'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(controller: _ownerNameController, label: 'Owner Name', hint: 'Suresh Patel')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(controller: _phoneController, label: 'Store Phone', hint: '+91 98765 43211', keyboardType: TextInputType.phone)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _emailController, label: 'Store Email', hint: 'shop@shreeganesh.com', keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 24),

                  // Location & Address
                  _buildSectionHeader('Location & Pincode', Icons.location_on_rounded),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _addressController, label: 'Full Street Address *', hint: '12 Market Yard, Ellisbridge', maxLines: 2),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(controller: _cityController, label: 'City', hint: 'Ahmedabad')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(controller: _pincodeController, label: 'Pincode', hint: '380006', keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Capacity & Operations
                  _buildSectionHeader('Milling Operations & Logistics', Icons.speed_rounded),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(controller: _capacityController, label: 'Daily Capacity (Kg)', hint: '600', keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(controller: _radiusController, label: 'Delivery Radius (Km)', hint: '5.0', keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _hoursController, label: 'Working Hours', hint: '08:00 AM - 08:00 PM'),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _specialtyController, label: 'Store Specialty', hint: 'Fresh Stone Ground Flour & Spices'),
                  const SizedBox(height: 24),

                  // Services Offered
                  Text(
                    'Services Offered',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allServices.map((service) {
                      final isSelected = _selectedServices.contains(service);
                      return FilterChip(
                        label: Text(service),
                        selected: isSelected,
                        selectedColor: const Color(0xFFEDE9D9),
                        checkmarkColor: const Color(0xFF6E5616),
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFF6E5616) : AppTheme.textSecondary,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: isSelected ? const Color(0xFF6E5616) : AppTheme.borderLight),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedServices.add(service);
                            } else {
                              _selectedServices.remove(service);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Store Photo URLs
                  _buildSectionHeader('Storefront & Chakki Photos', Icons.photo_camera_rounded),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _storeImageController,
                    label: 'Storefront Image URL',
                    hint: 'https://...',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _chakkiImageController,
                    label: 'Chakki Machine Photo URL',
                    hint: 'https://...',
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6E5616),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(
                              'Save Store Details',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryTerracotta),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryTerracotta, width: 1.5)),
      ),
    );
  }
}

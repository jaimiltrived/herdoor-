import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/customer_api_service.dart';
import '../services/auth_api_service.dart';

class MerchantApplicationScreen extends StatefulWidget {
  final VoidCallback? onApplicationApproved;

  const MerchantApplicationScreen({
    super.key,
    this.onApplicationApproved,
  });

  @override
  State<MerchantApplicationScreen> createState() => _MerchantApplicationScreenState();
}

class _MerchantApplicationScreenState extends State<MerchantApplicationScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _existingApplication;

  // Controllers
  final _storeNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(text: 'Ahmedabad');
  final _pincodeController = TextEditingController(text: '380015');
  final _capacityController = TextEditingController(text: '500');
  final _radiusController = TextEditingController(text: '5.0');
  final _hoursController = TextEditingController(text: '08:00 AM - 08:00 PM');
  final _specialtyController = TextEditingController(text: 'Fresh Stone Ground Flour & Custom Milling');
  final _storeImageController = TextEditingController(text: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80');
  final _licenseController = TextEditingController(text: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=600&q=80');
  final _licenseNumberController = TextEditingController(text: 'FSSAI-2026-881290');

  // Services selection
  final List<String> _availableServices = ['Flour Grinding', 'Packing', 'Home Delivery', 'Cleaning', 'Grain Sorting'];
  final List<String> _selectedServices = ['Flour Grinding', 'Packing', 'Home Delivery'];

  @override
  void initState() {
    super.initState();
    _fetchApplicationStatus();
  }

  Future<void> _fetchApplicationStatus() async {
    setState(() => _isLoading = true);
    final user = AuthApiService.instance.currentUser;
    if (user != null) {
      _phoneController.text = user['phone'] ?? '+919876543210';
      _emailController.text = user['email'] ?? 'ramesh@example.com';
    }

    final data = await CustomerApiService.instance.getMyMerchantApplication();
    if (mounted) {
      setState(() {
        _existingApplication = data?['application'];
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSubmit() async {
    final storeName = _storeNameController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();

    if (storeName.isEmpty || address.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields: Store Name, Address, and Phone'),
          backgroundColor: AppTheme.primaryTerracotta,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await CustomerApiService.instance.applyForMerchant(
      storeName: storeName,
      phone: phone,
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
      licenseDocument: _licenseController.text.trim(),
      licenseNumber: _licenseNumberController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Application submitted!'),
          backgroundColor: const Color(0xFF2ECC71),
        ),
      );
      _fetchApplicationStatus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to submit application'),
          backgroundColor: AppTheme.primaryTerracotta,
        ),
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
          'Become a Shopkeeper',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryTerracotta,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryTerracotta))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Banner if already applied
                  if (_existingApplication != null) ...[
                    _buildApplicationStatusCard(_existingApplication!),
                    const SizedBox(height: 24),
                  ],

                  if (_existingApplication == null || _existingApplication!['status'] == 'REJECTED') ...[
                    // Introduction Banner
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8C4A3E), Color(0xFF5A2E25)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Partner with HerDoor',
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Grow your flour mill & chakki business',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Receive customer orders directly, manage stone ground flour production, and connect with verified delivery riders.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Store Details Form Section
                    _buildSectionHeader('Store Identity & Contact', Icons.store_rounded),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _storeNameController,
                      label: 'Store / Mill Name *',
                      hint: 'e.g. Shree Ganesh Flour Mill',
                      icon: Icons.storefront_outlined,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _phoneController,
                            label: 'Contact Phone *',
                            hint: '+91 98765 43210',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _emailController,
                            label: 'Contact Email',
                            hint: 'store@example.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Location Section
                    _buildSectionHeader('Store Address & Location', Icons.location_on_rounded),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Complete Store Address *',
                      hint: 'e.g. Shop 12, Sunrise Arcade, Ellisbridge',
                      icon: Icons.map_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _cityController,
                            label: 'City',
                            hint: 'Ahmedabad',
                            icon: Icons.location_city_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _pincodeController,
                            label: 'Pincode',
                            hint: '380015',
                            icon: Icons.pin_drop_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Operations & Capacity
                    _buildSectionHeader('Milling Operations & Capacity', Icons.speed_rounded),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _capacityController,
                            label: 'Daily Capacity (Kg) *',
                            hint: '500',
                            icon: Icons.scale_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _radiusController,
                            label: 'Delivery Radius (Km)',
                            hint: '5.0',
                            icon: Icons.radar_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _hoursController,
                      label: 'Working Hours',
                      hint: '08:00 AM - 08:00 PM',
                      icon: Icons.access_time_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _specialtyController,
                      label: 'Milling Specialty',
                      hint: 'e.g. Pure Sharbati Gehun, Bajra & Multigrain Flour',
                      icon: Icons.stars_rounded,
                    ),
                    const SizedBox(height: 20),

                    // Services Checkboxes
                    Text(
                      'Services Offered by Store',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableServices.map((service) {
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
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF6E5616) : AppTheme.borderLight,
                            ),
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

                    // Store Image & FSSAI License
                    _buildSectionHeader('Store Photo & License Proof', Icons.verified_outlined),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _storeImageController,
                      label: 'Storefront Image URL / Photo',
                      hint: 'https://...',
                      icon: Icons.camera_alt_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _licenseNumberController,
                      label: 'FSSAI / Business Registration Number',
                      hint: 'FSSAI-2026-XXXXXX',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _licenseController,
                      label: 'License Document Proof URL',
                      hint: 'https://...',
                      icon: Icons.document_scanner_outlined,
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6E5616),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                          elevation: 2,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                'Submit Merchant Application',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildApplicationStatusCard(Map<String, dynamic> app) {
    final status = (app['status'] ?? 'PENDING').toString().toUpperCase();
    final isPending = status == 'PENDING';
    final isApproved = status == 'APPROVED';

    Color cardBg;
    Color iconColor;
    IconData icon;
    String title;
    String message;

    if (isApproved) {
      cardBg = const Color(0xFFE8F8F0);
      iconColor = const Color(0xFF1E8449);
      icon = Icons.check_circle_rounded;
      title = 'Application Approved!';
      message = 'Your store "${app['storeName']}" is verified and active. You can now login as a Merchant.';
    } else if (isPending) {
      cardBg = const Color(0xFFFFF8E7);
      iconColor = const Color(0xFFB7791F);
      icon = Icons.hourglass_top_rounded;
      title = 'Application Under Review';
      message = 'Our admin team is reviewing your store details and hygiene certification. Estimated review: within 24 hours.';
    } else {
      cardBg = const Color(0xFFFDEDEC);
      iconColor = const Color(0xFFC0392B);
      icon = Icons.cancel_rounded;
      title = 'Application Needs Attention';
      message = app['adminNotes'] ?? 'Your application was rejected. Please review feedback and resubmit.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Store: ${app['storeName'] ?? ''}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Status: $status',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),

          // Render Merchant Credentials and Email Notification Details if Approved
          if (isApproved) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2ECC71).withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.key_rounded, size: 18, color: Color(0xFF1E8449)),
                      const SizedBox(width: 6),
                      Text(
                        'Your Shopkeeper Login Credentials',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E8449),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Login ID / Email:',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      Text(
                        app['credentials']?['loginId'] ?? app['email'] ?? 'ramesh@example.com',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Initial Password:',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          app['credentials']?['temporaryPassword'] ?? 'Password123!',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E8449)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 14, color: Color(0xFF1E8449)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Onboarding welcome email dispatched with login guide.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF1E8449), fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
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
    required IconData icon,
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
        prefixIcon: Icon(icon, color: AppTheme.primaryTerracotta, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.borderLight),
        ),
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
}

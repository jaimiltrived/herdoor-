import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _orderAlerts = true;
  bool _promoAlerts = false;
  bool _darkTheme = false;
  String _selectedLanguage = 'English (US)';

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
          'Settings',
style: GoogleFonts.plusJakartaSans(
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
                'Notifications & Alerts',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _buildSettingCard([
                _buildSwitchTile(
                  'Push Notifications',
                  'Receive instant order progress updates',
                  _pushNotifications,
                  (val) => setState(() => _pushNotifications = val),
                ),
                const Divider(height: 1, color: AppTheme.borderLight),
                _buildSwitchTile(
                  'Milling & Delivery Sound Alerts',
                  'Play sound when step changes',
                  _orderAlerts,
                  (val) => setState(() => _orderAlerts = val),
                ),
                const Divider(height: 1, color: AppTheme.borderLight),
                _buildSwitchTile(
                  'Promotional Offers & Discounts',
                  'Receive local flour mill deals',
                  _promoAlerts,
                  (val) => setState(() => _promoAlerts = val),
                ),
              ]),
              const SizedBox(height: 24),

              Text(
                'App Preferences',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _buildSettingCard([
                ListTile(
                  title: Text(
                    'App Language',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    _selectedLanguage,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: Text('Select Language', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
                        children: ['English (US)', 'Spanish', 'Hindi', 'French'].map((lang) {
                          return SimpleDialogOption(
                            onPressed: () {
                              setState(() => _selectedLanguage = lang);
                              Navigator.pop(context);
                            },
                            child: Text(lang, style: GoogleFonts.plusJakartaSans(fontSize: 15)),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, color: AppTheme.borderLight),
                _buildSwitchTile(
                  'Dark Theme Preview',
                  'Use dark mode colors across screens',
                  _darkTheme,
                  (val) => setState(() => _darkTheme = val),
                ),
              ]),
              const SizedBox(height: 24),

              Text(
                'Data & Storage',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _buildSettingCard([
                ListTile(
                  title: Text(
                    'Clear Local Cache',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Frees up 12.4 MB of temporary storage',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  trailing: const Icon(Icons.cleaning_services_outlined, color: AppTheme.primaryTerracotta),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache cleared successfully!')),
                    );
                  },
                ),
              ]),
              Text(
                'Legal & Privacy',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _buildSettingCard([
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppTheme.primaryTerracotta),
                  title: Text(
                    'Privacy Policy',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Data collection, GPS usage & safety disclosure',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                  onTap: () => _showPrivacyPolicyDialog(),
                ),
                const Divider(height: 1, color: AppTheme.borderLight),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: AppTheme.primaryTerracotta),
                  title: Text(
                    'Terms of Service',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Order milling terms & doorstep delivery rules',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                  onTap: () => _showTermsDialog(),
                ),
              ]),
              const SizedBox(height: 32),

              Center(
                child: Column(
                  children: [
                    Text(
                      'HerDoor Flour Mill & Delivery',
            style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryTerracotta,
                      ),
                    ),
                    Text(
                      'Version 1.0.0 (Build 100)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.primaryTerracotta,
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('HerDoor Privacy Policy', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Updated: September 2026\n\n'
                  '1. Information We Collect:\n'
                  '• Account Info: Name, email address, phone number.\n'
                  '• Location Data: Fine & coarse location used solely for mill discovery, grain pickup, and live delivery tracking.\n'
                  '• Order History: Grains milled, quantities, and delivery receipts.\n\n'
                  '2. How We Use Information:\n'
                  '• To process grain milling orders and route delivery partners to your doorstep.\n'
                  '• To send OTP verifications and order timeline notifications.\n\n'
                  '3. Data Safety & Security:\n'
                  '• All authentication tokens are stored locally via encrypted hardware storage.\n'
                  '• We do not sell user data to third parties.\n\n'
                  '4. Contact Us:\n'
                  'support@herdoor.com | Ahmedabad, Gujarat',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.primaryTerracotta)),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Terms of Service', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              '1. Service Overview:\n'
              'HerDoor connects customers with local artisanal flour chakkis/mills for grain pickup, fresh milling, and doorstep delivery.\n\n'
              '2. Order Pickup & Delivery:\n'
              '• For customer-provided grains (Leg 1), please ensure grains are dry, clean, and placed in a sealed container.\n'
              '• For mill-purchased flour (Leg 2), delivery partner will deliver sealed packages verified with OTP/QR scan.\n\n'
              '3. Payments & Cancellations:\n'
              '• Payment can be made online via UPI/Card or Cash on Delivery.\n'
              '• Orders can be cancelled prior to milling commencement.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5, color: AppTheme.textSecondary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Understood', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.primaryTerracotta)),
          ),
        ],
      ),
    );
  }
}

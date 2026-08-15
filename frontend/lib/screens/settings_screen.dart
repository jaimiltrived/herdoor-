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
              const SizedBox(height: 32),

              Center(
                child: Column(
                  children: [
                    Text(
                      'HerDoor Flour Mill',
                      style: GoogleFonts.playfairDisplay(
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(children: children),
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
}

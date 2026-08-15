import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Order Milling Started!',
      'description': 'Artisan Mill Co. has started cold-pressing your Premium Sharbati Wheat (#HD-8472).',
      'time': '10 mins ago',
      'isUnread': true,
      'icon': Icons.agriculture_rounded,
    },
    {
      'title': 'Container Picked Up',
      'description': 'Our delivery partner picked up your empty grain container from your home.',
      'time': '1 hour ago',
      'isUnread': true,
      'icon': Icons.local_shipping_outlined,
    },
    {
      'title': 'Fresh Harvest Discount!',
      'description': 'Get 20% off ancient grains & Pearl Millet milling this weekend at Heritage Grains.',
      'time': 'Yesterday',
      'isUnread': false,
      'icon': Icons.local_offer_outlined,
    },
    {
      'title': 'Order #HD-8120 Delivered',
      'description': 'Your 5kg Multigrain flour was delivered successfully. Enjoy fresh rotis!',
      'time': '3 days ago',
      'isUnread': false,
      'icon': Icons.check_circle_outline_rounded,
    },
  ];

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
          'Notifications',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryTerracotta,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var item in _notifications) {
                  item['isUnread'] = false;
                }
              });
            },
            child: Text(
              'Mark all as read',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryTerracotta,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _notifications.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _notifications[index];
                  final isUnread = item['isUnread'] as bool;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isUnread ? AppTheme.surfaceWarm : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isUnread ? AppTheme.mustardGold : AppTheme.borderLight,
                        width: isUnread ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isUnread ? AppTheme.primaryTerracotta : AppTheme.surfaceCream,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: isUnread ? Colors.white : AppTheme.primaryTerracotta,
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
                                  Expanded(
                                    child: Text(
                                      item['title'] as String,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    item['time'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['description'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

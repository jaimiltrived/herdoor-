import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/merchant_models.dart';
import '../../services/merchant_api_service.dart';

class MerchantNotificationsScreen extends StatefulWidget {
  const MerchantNotificationsScreen({super.key});

  @override
  State<MerchantNotificationsScreen> createState() => _MerchantNotificationsScreenState();
}

class _MerchantNotificationsScreenState extends State<MerchantNotificationsScreen> {
  bool _isLoading = true;
  int _selectedFilterTab = 0; // 0: All, 1: Unread
  List<AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final list = await MerchantApiService.instance.getNotifications();
    if (list != null) {
      _notifications = list;
    } else {
      // Fallback sample notifications
      _notifications = [
        AppNotification(
          id: 1,
          title: '🚨 New Order Received #ORD-2026-1002',
          message: 'Elena Rodriguez placed a new order for 5kg Multigrain Mix (₹175.00).',
          read: false,
          createdAt: '11:00 AM',
        ),
        AppNotification(
          id: 2,
          title: '🛵 Driver Arrived for Pickup',
          message: 'Rajesh Kumar (Electric Bike #EB-4821) arrived at store for order #ORD-2026-1001.',
          read: false,
          createdAt: '10:30 AM',
        ),
        AppNotification(
          id: 3,
          title: '⚠️ Low Stock Alert: Dark Rye Blend',
          message: 'Stock has fallen below threshold (15kg remaining). Restock soon.',
          read: false,
          createdAt: '09:15 AM',
        ),
        AppNotification(
          id: 4,
          title: '🛡️ Food Safety Audit Status',
          message: 'Daily chakki stone sanitization and grain moisture test verified (Score 99%).',
          read: true,
          createdAt: '08:00 AM',
        ),
      ];
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleMarkAllRead() async {
    final success = await MerchantApiService.instance.markAllNotificationsRead();
    setState(() {
      for (final n in _notifications) {
        n.read = true;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2ECC71),
          content: Text(
            success ? 'All notifications marked read on Backend!' : 'Notifications marked read.',
          ),
        ),
      );
    }
  }

  Future<void> _handleNotificationTap(AppNotification notification) async {
    if (!notification.read) {
      await MerchantApiService.instance.markNotificationRead(notification.id);
      setState(() {
        notification.read = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _selectedFilterTab == 1
        ? _notifications.where((n) => !n.read).toList()
        : _notifications;

    final int unreadCount = _notifications.where((n) => !n.read).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _handleMarkAllRead,
              child: Text(
                'Mark All Read',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryTerracotta,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        color: AppTheme.primaryTerracotta,
        child: Column(
          children: [
            // Filter Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  _buildFilterTab(0, 'All (${_notifications.length})'),
                  const SizedBox(width: 10),
                  _buildFilterTab(1, 'Unread ($unreadCount)'),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),

            // Notification List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryTerracotta))
                  : filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'No notifications found.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredList.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final notification = filteredList[index];
                            return _buildNotificationCard(context, notification);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(int index, String title) {
    final isSelected = _selectedFilterTab == index;

    return ChoiceChip(
      label: Text(title),
      selected: isSelected,
      selectedColor: AppTheme.primaryTerracotta,
      backgroundColor: const Color(0xFFF6F0E7),
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.white : AppTheme.textPrimary,
      ),
      onSelected: (val) {
        setState(() {
          _selectedFilterTab = index;
        });
      },
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification notification) {
    IconData iconData = Icons.notifications_active_rounded;
    Color iconBgColor = const Color(0xFFF6F0E7);
    Color iconColor = AppTheme.primaryTerracotta;

    if (notification.title.contains('Order')) {
      iconData = Icons.receipt_long_rounded;
      iconBgColor = const Color(0xFFE8F8F0);
      iconColor = const Color(0xFF2ECC71);
    } else if (notification.title.contains('Driver') || notification.title.contains('Pickup')) {
      iconData = Icons.local_shipping_rounded;
      iconBgColor = const Color(0xFFEDE9D9);
      iconColor = const Color(0xFF6E5616);
    } else if (notification.title.contains('Stock')) {
      iconData = Icons.warning_amber_rounded;
      iconBgColor = const Color(0xFFFFECEB);
      iconColor = AppTheme.primaryTerracotta;
    } else if (notification.title.contains('Safety') || notification.title.contains('Audit')) {
      iconData = Icons.verified_user_rounded;
      iconBgColor = const Color(0xFFFEF3D6);
      iconColor = const Color(0xFFD4AC0D);
    }

    return InkWell(
      onTap: () => _handleNotificationTap(notification),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.read ? Colors.white : const Color(0xFFFFFBF6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.read ? AppTheme.borderLight : const Color(0xFFF5E6D3),
            width: notification.read ? 1 : 1.5,
          ),
          boxShadow: [
            if (!notification.read)
              BoxShadow(
                color: AppTheme.primaryTerracotta.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: iconColor, size: 22),
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
                          notification.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: notification.read ? FontWeight.w600 : FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        notification.createdAt,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.read) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryTerracotta,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

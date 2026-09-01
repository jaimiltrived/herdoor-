import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/merchant_models.dart';

class MerchantApiService {
  static final MerchantApiService instance = MerchantApiService._internal();
  factory MerchantApiService() => instance;
  MerchantApiService._internal();

  // Dynamic host determination (10.0.2.2 for Android emulator, localhost elsewhere).
  String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api/v1';
    }
    return 'http://localhost:5000/api/v1';
  }

  String? _authToken;
  bool _isOfflineMode = false;
  DateTime? _lastOfflineCheck;
  static const Duration _timeout = Duration(seconds: 4);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  bool get shouldSkipNetwork {
    if (_isOfflineMode) {
      // Re-test network after 60 seconds
      if (_lastOfflineCheck != null &&
          DateTime.now().difference(_lastOfflineCheck!).inSeconds > 60) {
        _isOfflineMode = false;
        return false;
      }
      return true;
    }
    return false;
  }

  void _markOffline() {
    _isOfflineMode = true;
    _lastOfflineCheck = DateTime.now();
  }

  /// Ensure shopkeeper authentication token is acquired
  Future<bool> ensureAuthenticated() async {
    if (_authToken != null) return true;
    if (shouldSkipNetwork) return false;

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': 'shop@shreeganesh.com',
              'password': 'Password123!',
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['data']?['token'];
        _isOfflineMode = false;
        return _authToken != null;
      }
    } catch (_) {
      _markOffline();
    }
    return false;
  }

  /// Get Logged-in Merchant Profile Details
  Future<Map<String, dynamic>?> getMerchantUserProfile() async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .get(
                Uri.parse('$baseUrl/auth/me'),
                headers: _headers,
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            final body = jsonDecode(response.body);
            return body['data']?['user'] as Map<String, dynamic>?;
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    return {
      'name': 'Shree Ganesh Flour Mill',
      'email': 'shop@shreeganesh.com',
      'phone': '+91 98765 43210',
    };
  }

  /// Update Merchant User Profile
  Future<bool> updateMerchantUserProfile({required String name, required String phone}) async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .put(
                Uri.parse('$baseUrl/users/me'),
                headers: _headers,
                body: jsonEncode({'name': name, 'phone': phone}),
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            return true;
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    return true; // Fallback mock success
  }

  /// Get Shopkeeper Dashboard Metrics
  Future<MerchantDashboardMetrics?> getDashboardMetrics() async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .get(
                Uri.parse('$baseUrl/shopkeeper/dashboard'),
                headers: _headers,
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            final body = jsonDecode(response.body);
            if (body['data']?['metrics'] != null) {
              return MerchantDashboardMetrics.fromJson(body['data']['metrics']);
            }
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    return MerchantDashboardMetrics(
      pendingOrders: MerchantMockData.pendingRequests.length,
      activeOrders: MerchantMockData.activeOrders.length,
      completedOrders: 4,
      totalRevenue: 1250.0,
    );
  }

  /// Get Shop Operating Availability
  Future<bool?> getShopAvailability() async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .get(
                Uri.parse('$baseUrl/shopkeeper/availability'),
                headers: _headers,
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            final body = jsonDecode(response.body);
            return body['data']?['isOpen'] as bool?;
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    return true;
  }

  /// Update Shop Operating Availability State
  Future<bool> updateShopAvailability(bool isOpen) async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .put(
                Uri.parse('$baseUrl/shopkeeper/availability'),
                headers: _headers,
                body: jsonEncode({'isOpen': isOpen}),
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            final body = jsonDecode(response.body);
            return body['status'] == 'success';
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    return true;
  }

  /// Get New Pending Orders
  Future<List<MerchantOrder>?> getNewOrders() async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .get(
                Uri.parse('$baseUrl/shopkeeper/orders/pending'),
                headers: _headers,
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            final body = jsonDecode(response.body);
            final list = body['data']?['orders'] as List?;
            if (list != null) {
              return list.map((json) => MerchantOrder.fromJson(json as Map<String, dynamic>)).toList();
            }
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    return [];
  }

  /// Get Active Processing Orders
  Future<List<MerchantOrder>?> getActiveOrders() async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .get(
                Uri.parse('$baseUrl/shopkeeper/orders/active'),
                headers: _headers,
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            final body = jsonDecode(response.body);
            final list = body['data']?['orders'] as List?;
            if (list != null) {
              return list.map((json) => MerchantOrder.fromJson(json as Map<String, dynamic>)).toList();
            }
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    return [];
  }

  /// Get Ready for Handover / Dispatch Orders
  Future<List<MerchantOrder>?> getReadyOrders() async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .get(
                Uri.parse('$baseUrl/shopkeeper/orders/ready'),
                headers: _headers,
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            final body = jsonDecode(response.body);
            final list = body['data']?['orders'] as List?;
            if (list != null) {
              return list.map((json) => MerchantOrder.fromJson(json as Map<String, dynamic>)).toList();
            }
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    return [];
  }

  /// Get Completed Orders
  Future<List<MerchantOrder>?> getCompletedOrders() async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .get(
                Uri.parse('$baseUrl/shopkeeper/orders/completed'),
                headers: _headers,
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            final body = jsonDecode(response.body);
            final list = body['data']?['orders'] as List?;
            if (list != null) {
              return list.map((json) => MerchantOrder.fromJson(json as Map<String, dynamic>)).toList();
            }
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    return [];
  }

  /// Accept Order and set completion time ETA
  Future<bool> acceptOrder(int orderId, {int estimatedMinutes = 30}) async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .post(
                Uri.parse('$baseUrl/shopkeeper/orders/$orderId/accept'),
                headers: _headers,
                body: jsonEncode({'estimatedCompletionMinutes': estimatedMinutes}),
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            return true;
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    // Update local state
    final index = MerchantMockData.pendingRequests.indexWhere((o) => o.numericId == orderId);
    if (index != -1) {
      final order = MerchantMockData.pendingRequests.removeAt(index);
      order.statusTag = 'IN PROGRESS';
      order.statusColor = const Color(0xFFCBA034);
      MerchantMockData.activeOrders.insert(0, order);
    } else {
      final actIndex = MerchantMockData.activeOrders.indexWhere((o) => o.numericId == orderId);
      if (actIndex != -1) {
        MerchantMockData.activeOrders[actIndex].statusTag = 'IN PROGRESS';
        MerchantMockData.activeOrders[actIndex].statusColor = const Color(0xFFCBA034);
      }
    }
    return true;
  }

  /// Reject / Decline Order
  Future<bool> rejectOrder(int orderId, {String reason = 'Capacity exceeded'}) async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .post(
                Uri.parse('$baseUrl/shopkeeper/orders/$orderId/reject'),
                headers: _headers,
                body: jsonEncode({'reason': reason}),
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            return true;
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    // Remove locally
    MerchantMockData.pendingRequests.removeWhere((o) => o.numericId == orderId);
    MerchantMockData.activeOrders.removeWhere((o) => o.numericId == orderId);
    return true;
  }

  /// Order Processing State Transitions ('start', 'processing', 'packing', 'ready', 'handover', 'complete')
  Future<bool> transitionOrderStatus(int orderId, String transition) async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .post(
                Uri.parse('$baseUrl/shopkeeper/orders/$orderId/$transition'),
                headers: _headers,
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            return true;
          }
        } catch (_) {
          _markOffline();
        }
      }
    }

    // Update in-memory mock order tag instantly
    final allOrders = [
      ...MerchantMockData.activeOrders,
      ...MerchantMockData.pendingRequests,
      MerchantMockData.sampleOrderHD8829,
    ];
    for (final order in allOrders) {
      if (order.numericId == orderId) {
        if (transition == 'start' || transition == 'processing') {
          order.statusTag = 'IN PROGRESS';
          order.statusColor = const Color(0xFFCBA034);
        } else if (transition == 'packing') {
          order.statusTag = 'PACKING';
          order.statusColor = const Color(0xFFCBA034);
        } else if (transition == 'ready') {
          order.statusTag = 'READY FOR PICKUP';
          order.statusColor = const Color(0xFFFF8A80);
        } else if (transition == 'handover') {
          order.statusTag = 'OUT FOR DELIVERY';
          order.statusColor = const Color(0xFF3498DB);
        } else if (transition == 'complete') {
          order.statusTag = 'COMPLETED';
          order.statusColor = const Color(0xFF2ECC71);
        }
        break;
      }
    }
    return true;
  }

  /// Get Flour & Grain Inventory Items
  Future<List<MerchantInventoryItem>?> getInventory() async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .get(
                Uri.parse('$baseUrl/shopkeeper/inventory'),
                headers: _headers,
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            final body = jsonDecode(response.body);
            final list = body['data']?['inventory'] as List?;
            if (list != null) {
              return list.map((json) => MerchantInventoryItem.fromJson(json as Map<String, dynamic>)).toList();
            }
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    return [];
  }

  /// Get Low Stock Items
  Future<List<MerchantInventoryItem>?> getLowStockInventory() async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .get(
                Uri.parse('$baseUrl/shopkeeper/inventory/low-stock'),
                headers: _headers,
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            final body = jsonDecode(response.body);
            final list = body['data']?['inventory'] as List?;
            if (list != null) {
              return list.map((json) => MerchantInventoryItem.fromJson(json as Map<String, dynamic>)).toList();
            }
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    return [];
  }

  /// Create New Inventory Item
  Future<MerchantInventoryItem?> createInventoryItem({
    required String name,
    required String productType,
    required double stockKg,
    required double minimumStockKg,
    required double pricePerKg,
  }) async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .post(
                Uri.parse('$baseUrl/shopkeeper/inventory'),
                headers: _headers,
                body: jsonEncode({
                  'name': name,
                  'productType': productType,
                  'stockKg': stockKg,
                  'minimumStockKg': minimumStockKg,
                  'pricePerKg': pricePerKg,
                }),
              )
              .timeout(_timeout);

          if (response.statusCode == 201 || response.statusCode == 200) {
            final body = jsonDecode(response.body);
            if (body['data']?['item'] != null) {
              return MerchantInventoryItem.fromJson(body['data']['item']);
            }
          }
        } catch (_) {
          _markOffline();
        }
      }
    }

    final newItem = MerchantInventoryItem(
      id: 'inv-${DateTime.now().millisecondsSinceEpoch}',
      numericId: 999,
      name: name,
      description: 'Fresh quality $name',
      grind: productType == 'GRAIN' ? 'Raw Grain' : 'Fine',
      weightOptions: '$stockKg kg stock',
      price: pricePerKg,
      inStock: stockKg > minimumStockKg,
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
      stockKg: stockKg,
      minimumStockKg: minimumStockKg,
      productType: productType,
    );
    MerchantMockData.inventoryItems.add(newItem);
    return newItem;
  }

  /// Update Inventory Item
  Future<bool> updateInventoryItem(int id, Map<String, dynamic> updateData) async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .put(
                Uri.parse('$baseUrl/shopkeeper/inventory/$id'),
                headers: _headers,
                body: jsonEncode(updateData),
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            return true;
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    return true;
  }

  /// Delete Inventory Item
  Future<bool> deleteInventoryItem(int id) async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .delete(
                Uri.parse('$baseUrl/shopkeeper/inventory/$id'),
                headers: _headers,
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            return true;
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    MerchantMockData.inventoryItems.removeWhere((item) => item.numericId == id);
    return true;
  }

  /// Adjust Inventory Stock (Stock-In / Stock-Out)
  Future<bool> adjustStock(int inventoryId, double kg, bool isStockIn) async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        final action = isStockIn ? 'stock-in' : 'stock-out';
        try {
          final response = await http
              .post(
                Uri.parse('$baseUrl/shopkeeper/inventory/$inventoryId/$action'),
                headers: _headers,
                body: jsonEncode({'kg': kg}),
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            return true;
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    return true;
  }

  /// Get All Notifications
  Future<List<AppNotification>?> getNotifications() async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .get(
                Uri.parse('$baseUrl/notifications'),
                headers: _headers,
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            final body = jsonDecode(response.body);
            final list = body['data']?['notifications'] as List?;
            if (list != null && list.isNotEmpty) {
              return list.map((json) => AppNotification.fromJson(json as Map<String, dynamic>)).toList();
            }
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    return [
      AppNotification(
        id: 1,
        title: 'New Order Received',
        message: 'Order #ORD-9921-A received from Elena Rodriguez.',
        read: false,
        createdAt: '10:30 AM',
      ),
      AppNotification(
        id: 2,
        title: 'Low Stock Alert',
        message: 'Dark Rye Blend is running below minimum stock limit (15 kg remaining).',
        read: false,
        createdAt: '09:15 AM',
      ),
    ];
  }

  /// Get Unread Notification Count
  Future<int> getUnreadCount() async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .get(
                Uri.parse('$baseUrl/notifications/unread'),
                headers: _headers,
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            final body = jsonDecode(response.body);
            final count = body['count'] as int?;
            if (count != null) return count;
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    return 2;
  }

  /// Mark Notification as Read
  Future<bool> markNotificationRead(int id) async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .put(
                Uri.parse('$baseUrl/notifications/$id/read'),
                headers: _headers,
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            return true;
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    return true;
  }

  /// Mark All Notifications Read
  Future<bool> markAllNotificationsRead() async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .put(
                Uri.parse('$baseUrl/notifications/read-all'),
                headers: _headers,
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            return true;
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    return true;
  }

  /// Delete Notification
  Future<bool> deleteNotification(int id) async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .delete(
                Uri.parse('$baseUrl/notifications/$id'),
                headers: _headers,
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            return true;
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    return true;
  }

  /// Get Detailed Shop Availability & Settings
  Future<Map<String, dynamic>?> getShopAvailabilityDetails() async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .get(
                Uri.parse('$baseUrl/shopkeeper/availability'),
                headers: _headers,
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            final body = jsonDecode(response.body);
            return body['data'] as Map<String, dynamic>?;
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    return {
      'isOpen': true,
      'statusMode': 0,
      'deliveryRadiusKm': 5.0,
      'expressDeliveryEnabled': true,
      'selfPickupEnabled': true,
      'workingHours': '08:00 AM - 08:00 PM',
      'services': ['Flour Grinding', 'Packing', 'Home Delivery', 'Cleaning'],
    };
  }

  /// Update Detailed Shop Availability & Settings
  Future<bool> updateShopAvailabilityDetails({
    required bool isOpen,
    required int statusMode,
    required double deliveryRadiusKm,
    required bool expressDeliveryEnabled,
    required bool selfPickupEnabled,
    String? workingHours,
    List<String>? services,
  }) async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .put(
                Uri.parse('$baseUrl/shopkeeper/availability'),
                headers: _headers,
                body: jsonEncode({
                  'isOpen': isOpen,
                  'statusMode': statusMode,
                  'deliveryRadiusKm': deliveryRadiusKm,
                  'expressDeliveryEnabled': expressDeliveryEnabled,
                  'selfPickupEnabled': selfPickupEnabled,
                  ...?workingHours != null ? {'workingHours': workingHours} : null,
                  ...?services != null ? {'services': services} : null,
                }),
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            return true;
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    return true;
  }

  /// Get Food Safety & Hygiene Audit
  Future<Map<String, dynamic>?> getSafetyAudit() async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .get(
                Uri.parse('$baseUrl/shopkeeper/safety-audit'),
                headers: _headers,
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            final body = jsonDecode(response.body);
            return body['data']?['safetyAudit'] as Map<String, dynamic>?;
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    return {
      'chakkiSanitized': true,
      'moistureCheckPassed': true,
      'dustExtractorActive': true,
      'ecoPackagingVerified': true,
      'pestControlCertified': true,
      'safetyScore': 99,
      'lastAuditDate': DateTime.now().toIso8601String(),
      'grade': 'A+'
    };
  }

  /// Update Food Safety & Hygiene Audit
  Future<Map<String, dynamic>?> updateSafetyAudit({
    required bool chakkiSanitized,
    required bool moistureCheckPassed,
    required bool dustExtractorActive,
    required bool ecoPackagingVerified,
    required bool pestControlCertified,
  }) async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .put(
                Uri.parse('$baseUrl/shopkeeper/safety-audit'),
                headers: _headers,
                body: jsonEncode({
                  'chakkiSanitized': chakkiSanitized,
                  'moistureCheckPassed': moistureCheckPassed,
                  'dustExtractorActive': dustExtractorActive,
                  'ecoPackagingVerified': ecoPackagingVerified,
                  'pestControlCertified': pestControlCertified,
                }),
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            final body = jsonDecode(response.body);
            return body['data']?['safetyAudit'] as Map<String, dynamic>?;
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    final checks = [chakkiSanitized, moistureCheckPassed, dustExtractorActive, ecoPackagingVerified, pestControlCertified];
    final score = ((checks.where((c) => c).length / checks.length) * 100).round();
    return {
      'chakkiSanitized': chakkiSanitized,
      'moistureCheckPassed': moistureCheckPassed,
      'dustExtractorActive': dustExtractorActive,
      'ecoPackagingVerified': ecoPackagingVerified,
      'pestControlCertified': pestControlCertified,
      'safetyScore': score,
      'lastAuditDate': DateTime.now().toIso8601String(),
      'grade': score >= 90 ? 'A+' : 'A',
    };
  }

  /// Get Comprehensive Store / Mill Details
  Future<Map<String, dynamic>?> getStoreDetails() async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .get(
                Uri.parse('$baseUrl/shopkeeper/profile'),
                headers: _headers,
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            final body = jsonDecode(response.body);
            return body['data'] as Map<String, dynamic>?;
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    return {
      'user': {
        'id': 2,
        'name': 'Suresh Mill Owner',
        'email': 'shop@shreeganesh.com',
        'phone': '+919876543211',
      },
      'mill': {
        'id': 101,
        'name': 'Shree Ganesh Flour Mill',
        'address': '12 Market Yard, Ellisbridge, Ahmedabad',
        'phone': '+919876543211',
        'isOpen': true,
        'capacityKgPerDay': 600,
        'deliveryRadiusKm': 5.0,
        'services': ['Flour Grinding', 'Packing', 'Home Delivery', 'Cleaning'],
        'workingHours': '08:00 AM - 08:00 PM',
        'specialty': 'Fresh Stone Ground Flour',
        'storeImage': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
      }
    };
  }

  /// Update Comprehensive Store / Mill Details
  Future<bool> updateStoreDetails({
    required String storeName,
    String? ownerName,
    String? phone,
    String? email,
    required String address,
    String? city,
    String? state,
    String? pincode,
    double? capacityKgPerDay,
    double? deliveryRadiusKm,
    String? workingHours,
    List<String>? services,
    String? specialty,
    String? storeImage,
    String? chakkiImage,
    bool? isOpen,
    bool? expressDeliveryEnabled,
    bool? selfPickupEnabled,
  }) async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .put(
                Uri.parse('$baseUrl/shopkeeper/profile'),
                headers: _headers,
                body: jsonEncode({
                  'name': storeName,
                  'ownerName': ?ownerName,
                  'phone': ?phone,
                  'email': ?email,
                  'address': address,
                  'city': ?city,
                  'state': ?state,
                  'pincode': ?pincode,
                  'capacityKgPerDay': ?capacityKgPerDay,
                  'deliveryRadiusKm': ?deliveryRadiusKm,
                  'workingHours': ?workingHours,
                  'services': ?services,
                  'specialty': ?specialty,
                  'storeImage': ?storeImage,
                  'chakkiImage': ?chakkiImage,
                  'isOpen': ?isOpen,
                  'expressDeliveryEnabled': ?expressDeliveryEnabled,
                  'selfPickupEnabled': ?selfPickupEnabled,
                }),
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            return true;
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    return true;
  }

  /// Upload / Update Store Images
  Future<bool> uploadStoreImages({
    String? storeImage,
    String? chakkiImage,
    String? bannerImage,
  }) async {
    if (!shouldSkipNetwork) {
      final authOk = await ensureAuthenticated();
      if (authOk) {
        try {
          final response = await http
              .post(
                Uri.parse('$baseUrl/shopkeeper/store-images'),
                headers: _headers,
                body: jsonEncode({
                  'storeImage': ?storeImage,
                  'chakkiImage': ?chakkiImage,
                  'bannerImage': ?bannerImage,
                }),
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            return true;
          }
        } catch (_) {
          _markOffline();
        }
      }
    }
    return true;
  }
}



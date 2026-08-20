import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/merchant_models.dart';

class MerchantApiService {
  static final MerchantApiService instance = MerchantApiService._internal();
  factory MerchantApiService() => instance;
  MerchantApiService._internal();

  // Dynamic host determination (10.0.2.2 for Android emulator, localhost for Web/Windows/iOS)
  String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api/v1';
    }
    return 'http://localhost:5000/api/v1';
  }

  String? _authToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  /// Ensure shopkeeper authentication token is acquired
  Future<bool> ensureAuthenticated() async {
    if (_authToken != null) return true;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'shop@shreeganesh.com',
          'password': 'Password123!',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['data']?['token'];
        return _authToken != null;
      }
    } catch (e) {
      debugPrint('Merchant API Auth Error: $e');
    }
    return false;
  }

  /// Get Logged-in Merchant Profile Details
  Future<Map<String, dynamic>?> getMerchantUserProfile() async {
    await ensureAuthenticated();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['data']?['user'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('Get Merchant User Profile Error: $e');
    }
    return null;
  }

  /// Update Merchant User Profile
  Future<bool> updateMerchantUserProfile({required String name, required String phone}) async {
    await ensureAuthenticated();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/me'),
        headers: _headers,
        body: jsonEncode({'name': name, 'phone': phone}),
      );

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint('Update Merchant User Profile Error: $e');
    }
    return false;
  }

  /// Get Shopkeeper Dashboard Metrics
  Future<MerchantDashboardMetrics?> getDashboardMetrics() async {
    await ensureAuthenticated();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/shopkeeper/dashboard'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['data']?['metrics'] != null) {
          return MerchantDashboardMetrics.fromJson(body['data']['metrics']);
        }
      }
    } catch (e) {
      debugPrint('Get Dashboard Metrics Error: $e');
    }
    return null;
  }

  /// Get Shop Operating Availability
  Future<bool?> getShopAvailability() async {
    await ensureAuthenticated();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/shopkeeper/availability'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['data']?['isOpen'] as bool?;
      }
    } catch (e) {
      debugPrint('Get Shop Availability Error: $e');
    }
    return null;
  }

  /// Update Shop Operating Availability State
  Future<bool> updateShopAvailability(bool isOpen) async {
    await ensureAuthenticated();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/shopkeeper/availability'),
        headers: _headers,
        body: jsonEncode({'isOpen': isOpen}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      }
    } catch (e) {
      debugPrint('Update Shop Availability Error: $e');
    }
    return false;
  }

  /// Get New Pending Orders
  Future<List<MerchantOrder>?> getNewOrders() async {
    await ensureAuthenticated();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/shopkeeper/orders/pending'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body['data']?['orders'] as List?;
        if (list != null) {
          return list.map((json) => MerchantOrder.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('Get New Orders Error: $e');
    }
    return null;
  }

  /// Get Active Processing Orders
  Future<List<MerchantOrder>?> getActiveOrders() async {
    await ensureAuthenticated();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/shopkeeper/orders/active'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body['data']?['orders'] as List?;
        if (list != null) {
          return list.map((json) => MerchantOrder.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('Get Active Orders Error: $e');
    }
    return null;
  }

  /// Get Completed Orders
  Future<List<MerchantOrder>?> getCompletedOrders() async {
    await ensureAuthenticated();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/shopkeeper/orders/completed'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body['data']?['orders'] as List?;
        if (list != null) {
          return list.map((json) => MerchantOrder.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('Get Completed Orders Error: $e');
    }
    return null;
  }

  /// Accept Order and set completion time ETA
  Future<bool> acceptOrder(int orderId, {int estimatedMinutes = 30}) async {
    await ensureAuthenticated();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shopkeeper/orders/$orderId/accept'),
        headers: _headers,
        body: jsonEncode({'estimatedCompletionMinutes': estimatedMinutes}),
      );

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint('Accept Order Error: $e');
    }
    return false;
  }

  /// Reject / Decline Order
  Future<bool> rejectOrder(int orderId, {String reason = 'Capacity exceeded'}) async {
    await ensureAuthenticated();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shopkeeper/orders/$orderId/reject'),
        headers: _headers,
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint('Reject Order Error: $e');
    }
    return false;
  }

  /// Order Processing State Transitions ('start', 'packing', 'ready', 'handover', 'complete')
  Future<bool> transitionOrderStatus(int orderId, String transition) async {
    await ensureAuthenticated();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shopkeeper/orders/$orderId/$transition'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint('Transition Order Status Error: $e');
    }
    return false;
  }

  /// Get Flour & Grain Inventory Items
  Future<List<MerchantInventoryItem>?> getInventory() async {
    await ensureAuthenticated();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/shopkeeper/inventory'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body['data']?['inventory'] as List?;
        if (list != null) {
          return list.map((json) => MerchantInventoryItem.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('Get Inventory Error: $e');
    }
    return null;
  }

  /// Get Low Stock Items
  Future<List<MerchantInventoryItem>?> getLowStockInventory() async {
    await ensureAuthenticated();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/shopkeeper/inventory/low-stock'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body['data']?['inventory'] as List?;
        if (list != null) {
          return list.map((json) => MerchantInventoryItem.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('Get Low Stock Inventory Error: $e');
    }
    return null;
  }

  /// Create New Inventory Item
  Future<MerchantInventoryItem?> createInventoryItem({
    required String name,
    required String productType,
    required double stockKg,
    required double minimumStockKg,
    required double pricePerKg,
  }) async {
    await ensureAuthenticated();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shopkeeper/inventory'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'productType': productType,
          'stockKg': stockKg,
          'minimumStockKg': minimumStockKg,
          'pricePerKg': pricePerKg,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['data']?['item'] != null) {
          return MerchantInventoryItem.fromJson(body['data']['item']);
        }
      }
    } catch (e) {
      debugPrint('Create Inventory Item Error: $e');
    }
    return null;
  }

  /// Update Inventory Item
  Future<bool> updateInventoryItem(int id, Map<String, dynamic> updateData) async {
    await ensureAuthenticated();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/shopkeeper/inventory/$id'),
        headers: _headers,
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint('Update Inventory Item Error: $e');
    }
    return false;
  }

  /// Delete Inventory Item
  Future<bool> deleteInventoryItem(int id) async {
    await ensureAuthenticated();
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/shopkeeper/inventory/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint('Delete Inventory Item Error: $e');
    }
    return false;
  }

  /// Adjust Inventory Stock (Stock-In / Stock-Out)
  Future<bool> adjustStock(int inventoryId, double kg, bool isStockIn) async {
    await ensureAuthenticated();
    final action = isStockIn ? 'stock-in' : 'stock-out';
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shopkeeper/inventory/$inventoryId/$action'),
        headers: _headers,
        body: jsonEncode({'kg': kg}),
      );

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint('Adjust Stock Error: $e');
    }
    return false;
  }

  /// Get All Notifications
  Future<List<AppNotification>?> getNotifications() async {
    await ensureAuthenticated();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body['data']?['notifications'] as List?;
        if (list != null) {
          return list.map((json) => AppNotification.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('Get Notifications Error: $e');
    }
    return null;
  }

  /// Get Unread Notification Count
  Future<int> getUnreadCount() async {
    await ensureAuthenticated();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final count = body['count'] as int?;
        if (count != null) return count;
      }
    } catch (e) {
      debugPrint('Get Unread Count Error: $e');
    }
    return 0;
  }

  /// Mark Notification as Read
  Future<bool> markNotificationRead(int id) async {
    await ensureAuthenticated();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$id/read'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint('Mark Notification Read Error: $e');
    }
    return false;
  }

  /// Mark All Notifications Read
  Future<bool> markAllNotificationsRead() async {
    await ensureAuthenticated();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint('Mark All Notifications Read Error: $e');
    }
    return false;
  }
}

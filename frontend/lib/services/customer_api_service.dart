import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/app_models.dart';
import '../models/merchant_models.dart';

class CustomerApiService {
  static final CustomerApiService instance = CustomerApiService._internal();
  factory CustomerApiService() => instance;
  CustomerApiService._internal();

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

  /// Ensure customer authentication token is acquired
  Future<bool> ensureAuthenticated() async {
    if (_authToken != null) return true;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'ramesh@example.com',
          'password': 'Password123!',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['data']?['token'];
        return _authToken != null;
      }
    } catch (e) {
      debugPrint('Customer API Auth Error: $e');
    }
    return false;
  }

  /// Get Nearby Flour Mills from backend geospatial locator
  Future<List<FlourMill>?> getNearbyMills({
    double latitude = 23.0225,
    double longitude = 72.5714,
    double radius = 10,
  }) async {
    await ensureAuthenticated();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mills/nearby?latitude=$latitude&longitude=$longitude&radius=$radius'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body['data']?['mills'] as List?;
        if (list != null) {
          return list.map((json) {
            final m = json as Map<String, dynamic>;
            final num dist = m['distanceKm'] ?? 1.2;
            return FlourMill(
              id: m['id']?.toString() ?? '101',
              name: m['name'] ?? 'Shree Ganesh Flour Mill',
              rating: (m['rating'] ?? 4.8).toDouble(),
              reviewCount: m['totalRatings'] ?? 128,
              distanceKm: dist.toDouble(),
              specialty: m['specialty'] ?? 'Fresh Stone Ground Flour',
              statusText: m['isOpen'] == true ? 'OPEN' : 'CLOSED',
              isOpen: m['isOpen'] ?? true,
              imageUrl: m['imageUrl'] ?? 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
              address: m['address'] ?? '12 Market Yard, Ellisbridge, Ahmedabad',
              story: m['description'] ?? 'Artisan mill grinding fresh grain daily.',
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Get Nearby Mills Error: $e');
    }
    return null;
  }

  /// Get Customer's Orders List
  Future<List<MerchantOrder>?> getCustomerOrders() async {
    await ensureAuthenticated();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders'),
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
      debugPrint('Get Customer Orders Error: $e');
    }
    return null;
  }

  /// Get Order Details and Live Tracking Timeline
  Future<MerchantOrder?> getOrderDetails(int orderId) async {
    await ensureAuthenticated();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['data']?['order'] != null) {
          return MerchantOrder.fromJson(body['data']['order']);
        }
      }
    } catch (e) {
      debugPrint('Get Order Details Error: $e');
    }
    return null;
  }

  /// Place New Order on Backend
  Future<MerchantOrder?> placeOrder({
    required int millId,
    required String grainTypeName,
    required double quantityKg,
    String serviceType = 'GRINDING',
    String fulfillmentType = 'DELIVERY',
    double totalAmount = 105.0,
  }) async {
    await ensureAuthenticated();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: _headers,
        body: jsonEncode({
          'millId': millId,
          'grainTypeName': grainTypeName,
          'quantityKg': quantityKg,
          'serviceType': serviceType,
          'fulfillmentType': fulfillmentType,
          'addressId': 25,
          'paymentMethod': 'UPI',
          'totalAmount': totalAmount,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['data']?['order'] != null) {
          return MerchantOrder.fromJson(body['data']['order']);
        }
      }
    } catch (e) {
      debugPrint('Place Order Error: $e');
    }
    return null;
  }

  /// Submit Order Review & 5-Star Rating
  Future<bool> submitReview({
    required int orderId,
    required int rating,
    required String review,
  }) async {
    await ensureAuthenticated();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/review'),
        headers: _headers,
        body: jsonEncode({
          'rating': rating,
          'review': review,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint('Submit Review Error: $e');
    }
    return false;
  }

  /// Get Customer Notifications
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
      debugPrint('Get Customer Notifications Error: $e');
    }
    return null;
  }
}

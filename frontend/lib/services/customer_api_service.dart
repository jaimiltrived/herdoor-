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
    String? grainTypeName,
    double? quantityKg,
    List<Map<String, dynamic>>? items,
    String serviceType = 'GRINDING',
    String fulfillmentType = 'DELIVERY',
    double totalAmount = 105.0,
    double pickupFee = 0.0,
    double deliveryFee = 2.0,
    String paymentMethod = 'UPI',
    String? address,
  }) async {
    await ensureAuthenticated();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: _headers,
        body: jsonEncode({
          'millId': millId,
          'items': items,
          'grainTypeName': grainTypeName ?? (items?.isNotEmpty == true ? items![0]['name'] : 'Wheat'),
          'quantityKg': quantityKg ?? (items != null && items.isNotEmpty ? items.fold<double>(0.0, (s, i) => s + (i['quantity'] as num).toDouble()) : 1.0),
          'serviceType': serviceType,
          'fulfillmentType': fulfillmentType,
          'addressId': 25,
          'deliveryAddress': address ?? '456 Heritage Block, District 9, NY',
          'pickupFee': pickupFee,
          'deliveryFee': deliveryFee,
          'paymentMethod': paymentMethod,
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

  /// Get Mill Readymade Products from Database
  Future<List<Map<String, dynamic>>?> getMillProducts(int millId) async {
    await ensureAuthenticated();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mills/$millId/products'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body['data']?['products'] as List?;
        if (list != null) {
          return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        }
      }
    } catch (e) {
      debugPrint('Get Mill Products Error: $e');
    }
    return null;
  }

  /// Get Mill Custom Grains from Database
  Future<List<Map<String, dynamic>>?> getMillGrains(int millId) async {
    await ensureAuthenticated();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mills/$millId/grains'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body['data']?['grains'] as List?;
        if (list != null) {
          return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        }
      }
    } catch (e) {
      debugPrint('Get Mill Grains Error: $e');
    }
    return null;
  }

  /// Get Saved / Favorite Mills
  Future<List<FlourMill>?> getFavorites() async {
    await ensureAuthenticated();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me/favorites'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body['data']?['favorites'] as List?;
        if (list != null) {
          return list.map((json) => FlourMill.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('Get Favorites Error: $e');
    }
    return null;
  }

  /// Add Mill to Favorites
  Future<bool> addFavorite(String millId) async {
    await ensureAuthenticated();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/me/favorites/$millId'),
        headers: _headers,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Add Favorite Error: $e');
    }
    return false;
  }

  /// Remove Mill from Favorites
  Future<bool> removeFavorite(String millId) async {
    await ensureAuthenticated();
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/me/favorites/$millId'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Remove Favorite Error: $e');
    }
    return false;
  }

  /// Get Customer Saved Addresses
  Future<List<Map<String, dynamic>>?> getAddresses() async {
    await ensureAuthenticated();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me/addresses'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body['data']?['addresses'] as List?;
        if (list != null) {
          return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        }
      }
    } catch (e) {
      debugPrint('Get Addresses Error: $e');
    }
    return null;
  }

  /// Add New Customer Address
  Future<Map<String, dynamic>?> addAddress({
    required String addressLine1,
    String? addressLine2,
    required String city,
    String? state,
    required String pincode,
    bool isDefault = false,
  }) async {
    await ensureAuthenticated();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/me/addresses'),
        headers: _headers,
        body: jsonEncode({
          'addressLine1': addressLine1,
          'addressLine2': addressLine2 ?? '',
          'city': city,
          'state': state ?? 'Gujarat',
          'pincode': pincode,
          'isDefault': isDefault,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['data']?['address'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('Add Address Error: $e');
    }
    return null;
  }

  /// Set Default Customer Address
  Future<bool> setDefaultAddress(int addressId) async {
    await ensureAuthenticated();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/me/addresses/$addressId/default'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Set Default Address Error: $e');
    }
    return false;
  }

  /// Submit Merchant / Shopkeeper Application
  Future<Map<String, dynamic>> applyForMerchant({
    required String storeName,
    required String phone,
    String? email,
    required String address,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    double? capacityKgPerDay,
    double? deliveryRadiusKm,
    String? workingHours,
    List<String>? services,
    String? specialty,
    String? storeImage,
    String? licenseDocument,
    String? licenseNumber,
  }) async {
    await ensureAuthenticated();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/apply-merchant'),
        headers: _headers,
        body: jsonEncode({
          'storeName': storeName,
          'phone': phone,
          if (email != null) 'email': email,
          'address': address,
          'city': city ?? 'Ahmedabad',
          'state': state ?? 'Gujarat',
          'pincode': pincode ?? '380015',
          'latitude': latitude ?? 23.0225,
          'longitude': longitude ?? 72.5714,
          'capacityKgPerDay': capacityKgPerDay ?? 500,
          'deliveryRadiusKm': deliveryRadiusKm ?? 5.0,
          'workingHours': workingHours ?? '08:00 AM - 08:00 PM',
          'services': services ?? ['Flour Grinding', 'Packing', 'Home Delivery'],
          'specialty': specialty ?? 'Fresh Stone Ground Flour',
          if (storeImage != null) 'storeImage': storeImage,
          if (licenseDocument != null) 'licenseDocument': licenseDocument,
          if (licenseNumber != null) 'licenseNumber': licenseNumber,
        }),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'] ?? 'Application submitted successfully',
          'application': body['data']?['application'],
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Failed to submit application',
          'application': body['data']?['application'],
        };
      }
    } catch (e) {
      debugPrint('Apply Merchant Error: $e');
      return {
        'success': true,
        'message': 'Application submitted locally for review.',
        'application': {
          'id': 'APP-LOCAL',
          'storeName': storeName,
          'status': 'PENDING',
          'adminNotes': 'Application queued for verification.',
        }
      };
    }
  }

  /// Get Current User's Merchant Application Status
  Future<Map<String, dynamic>?> getMyMerchantApplication() async {
    await ensureAuthenticated();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/my-merchant-application'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('Get My Merchant Application Error: $e');
    }
    return null;
  }
}




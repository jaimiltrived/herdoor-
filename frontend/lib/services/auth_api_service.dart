import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/merchant_models.dart';

class AuthApiService {
  static final AuthApiService instance = AuthApiService._internal();
  factory AuthApiService() => instance;
  AuthApiService._internal();

  static const _storage = FlutterSecureStorage();

  String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api/v1';
    }
    return 'http://localhost:5000/api/v1';
  }

  static const Duration _timeout = Duration(seconds: 5);
  String? _token;
  Map<String, dynamic>? _currentUser;
  UserRole? _savedRole;

  String? get token => _token;
  Map<String, dynamic>? get currentUser => _currentUser;
  UserRole? get savedRole => _savedRole;

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Initialize session from secure storage on app launch
  Future<void> init() async {
    if (kIsWeb) return;
    try {
      _token = await _storage.read(key: 'jwt_token');
      final userStr = await _storage.read(key: 'current_user');
      final roleStr = await _storage.read(key: 'current_role');

      if (userStr != null && userStr.isNotEmpty) {
        _currentUser = jsonDecode(userStr);
      }
      if (roleStr != null) {
        if (roleStr == 'merchant' || roleStr == 'SHOPKEEPER') {
          _savedRole = UserRole.merchant;
        } else if (roleStr == 'delivery' || roleStr == 'DELIVERY') {
          _savedRole = UserRole.delivery;
        } else {
          _savedRole = UserRole.customer;
        }
      }
    } catch (e) {
      debugPrint('Auth storage load error: $e');
    }
  }

  /// Logout but preserve last active stage & stage preferences for seamless recovery upon re-login
  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _savedRole = null;
    if (!kIsWeb) {
      try {
        await _storage.delete(key: 'jwt_token');
        await _storage.delete(key: 'current_user');
      } catch (_) {}
    }
  }

  /// Save active navigation tab index for a specific user role
  Future<void> saveActiveTab(UserRole role, int index) async {
    if (kIsWeb) return;
    try {
      final key = 'last_tab_${role.name}';
      await _storage.write(key: key, value: index.toString());
    } catch (e) {
      debugPrint('Error saving active tab: $e');
    }
  }

  /// Get saved navigation tab index for a specific user role
  Future<int> getSavedTab(UserRole role) async {
    if (kIsWeb) return 0;
    try {
      final key = 'last_tab_${role.name}';
      final val = await _storage.read(key: key);
      if (val != null) {
        return int.tryParse(val) ?? 0;
      }
    } catch (e) {
      debugPrint('Error loading saved tab: $e');
    }
    return 0;
  }

  /// Save active delivery trip JSON payload to survive restarts & app closures
  Future<void> saveActiveTripData(Map<String, dynamic> tripJson) async {
    if (kIsWeb) return;
    try {
      await _storage.write(key: 'active_delivery_trip', value: jsonEncode(tripJson));
    } catch (e) {
      debugPrint('Error saving active trip: $e');
    }
  }

  /// Retrieve active delivery trip JSON payload
  Future<Map<String, dynamic>?> getSavedActiveTripData() async {
    if (kIsWeb) return null;
    try {
      final str = await _storage.read(key: 'active_delivery_trip');
      if (str != null && str.isNotEmpty) {
        return jsonDecode(str) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error reading saved trip data: $e');
    }
    return null;
  }

  /// Clear active delivery trip payload on completion
  Future<void> clearActiveTripData() async {
    if (kIsWeb) return;
    try {
      await _storage.delete(key: 'active_delivery_trip');
    } catch (_) {}
  }

  /// Save active order ID or tracking state
  Future<void> saveActiveOrderData(Map<String, dynamic> orderJson) async {
    if (kIsWeb) return;
    try {
      await _storage.write(key: 'active_customer_order', value: jsonEncode(orderJson));
    } catch (e) {
      debugPrint('Error saving active order: $e');
    }
  }

  /// Retrieve active order JSON payload
  Future<Map<String, dynamic>?> getSavedActiveOrderData() async {
    if (kIsWeb) return null;
    try {
      final str = await _storage.read(key: 'active_customer_order');
      if (str != null && str.isNotEmpty) {
        return jsonDecode(str) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error reading saved order data: $e');
    }
    return null;
  }

  /// Clear active order payload
  Future<void> clearActiveOrderData() async {
    if (kIsWeb) return;
    try {
      await _storage.delete(key: 'active_customer_order');
    } catch (_) {}
  }

  /// User / Merchant / Rider / Admin Login
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
    UserRole? role,
  }) async {
    try {
      String roleString = 'CUSTOMER';
      if (role == UserRole.merchant) {
        roleString = 'SHOPKEEPER';
      } else if (role == UserRole.delivery) {
        roleString = 'DELIVERY';
      }
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              if (identifier.contains('@')) 'email': identifier else 'phone': identifier,
              'password': password,
              'role': roleString,
            }),
          )
          .timeout(_timeout);

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      if (response.statusCode == 200) {
        _token = data['data']?['token'];
        _currentUser = data['data']?['user'];
        _savedRole = role ?? UserRole.customer;

        if (!kIsWeb) {
          try {
            if (_token != null) {
              await _storage.write(key: 'jwt_token', value: _token);
            }
            if (_currentUser != null) {
              await _storage.write(key: 'current_user', value: jsonEncode(_currentUser));
            }
            await _storage.write(key: 'current_role', value: roleString);
          } catch (_) {}
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Logged in successfully',
          'token': _token,
          'user': _currentUser,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Invalid credentials',
        };
      }
    } catch (e) {
      debugPrint('Auth Login Error: $e');
      return {
        'success': false,
        'message': 'Unable to connect to HerDoor server. Please check your internet connection.',
      };
    }
  }

  /// User Registration
  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    String? email,
    required String password,
    String role = 'CUSTOMER',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'phone': phone,
              if (email != null && email.isNotEmpty) 'email': email,
              'password': password,
              'role': role,
            }),
          )
          .timeout(_timeout);

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      if (response.statusCode == 201 || response.statusCode == 200) {
        _token = data['data']?['token'];
        _currentUser = data['data']?['user'];

        if (!kIsWeb) {
          try {
            if (_token != null) {
              await _storage.write(key: 'jwt_token', value: _token);
            }
            if (_currentUser != null) {
              await _storage.write(key: 'current_user', value: jsonEncode(_currentUser));
            }
            await _storage.write(key: 'current_role', value: role);
          } catch (_) {}
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Registered successfully',
          'token': _token,
          'user': _currentUser,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      debugPrint('Auth Register Error: $e');
      return {
        'success': false,
        'message': 'Registration server error. Please try again.',
      };
    }
  }

  /// Request Forgot Password OTP
  Future<Map<String, dynamic>> forgotPassword(String identifier) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              if (identifier.contains('@')) 'email': identifier else 'phone': identifier,
            }),
          )
          .timeout(_timeout);

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? (response.statusCode == 200 ? 'OTP sent successfully' : 'Unable to send OTP'),
        'data': data['data'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to server to send OTP. Please check your internet connection.',
      };
    }
  }

  /// Verify OTP Code
  Future<Map<String, dynamic>> verifyOtp(String identifier, String otp) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              if (identifier.contains('@')) 'email': identifier else 'phone': identifier,
              'otp': otp,
            }),
          )
          .timeout(_timeout);

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'OTP verification result',
        'verified': data['data']?['verified'] ?? (response.statusCode == 200),
      };
    } catch (e) {
      return {
        'success': false,
        'verified': false,
        'message': 'Failed to verify OTP with server.',
      };
    }
  }

  /// Resend OTP Code
  Future<Map<String, dynamic>> resendOtp(String identifier) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/resend-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              if (identifier.contains('@')) 'email': identifier else 'phone': identifier,
            }),
          )
          .timeout(_timeout);

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? (response.statusCode == 200 ? 'OTP code resent' : 'Unable to resend OTP'),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error while resending OTP.',
      };
    }
  }

  /// Reset Password with OTP
  Future<Map<String, dynamic>> resetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              if (identifier.contains('@')) 'email': identifier else 'phone': identifier,
              'otp': otp,
              'newPassword': newPassword,
            }),
          )
          .timeout(_timeout);

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? (response.statusCode == 200 ? 'Password reset completed' : 'Password reset failed'),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to reach server to reset password.',
      };
    }
  }

  /// Get Current User Profile
  Future<Map<String, dynamic>?> getMe() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/users/me'),
            headers: headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = data['data']?['user'];
        return _currentUser;
      }
    } catch (e) {
      debugPrint('GetMe Error: $e');
    }
    return _currentUser;
  }

  /// Update User Profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? profileImage,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/users/me'),
            headers: headers,
            body: jsonEncode({
              'name': ?name,
              'phone': ?phone,
              'email': ?email,
              'profileImage': ?profileImage,
            }),
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data['data']?['user'] != null) {
          _currentUser = data['data']['user'];
        } else {
          _currentUser ??= {};
          if (name != null) _currentUser!['name'] = name;
          if (phone != null) _currentUser!['phone'] = phone;
          if (email != null) _currentUser!['email'] = email;
          if (profileImage != null) _currentUser!['profile_image'] = profileImage;
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Profile updated',
          'user': _currentUser,
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to update profile',
      };
    } catch (e) {
      _currentUser ??= {};
      if (name != null) _currentUser!['name'] = name;
      if (phone != null) _currentUser!['phone'] = phone;
      if (email != null) _currentUser!['email'] = email;
      if (profileImage != null) _currentUser!['profile_image'] = profileImage;
      return {
        'success': true,
        'message': 'Profile updated',
        'user': _currentUser,
      };
    }
  }
}

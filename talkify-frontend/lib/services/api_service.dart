import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config.dart';

/// API Service for backend communication
/// Handles all HTTP requests with JWT authentication
class ApiService {
  static const String _baseUrl = AppConfig.apiBaseUrl;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  // JWT token key for secure storage
  static const String _jwtTokenKey = 'jwt_token';
  static const String _userInfoKey = 'user_info';
  
  /// Get stored JWT token
  static Future<String?> getJwtToken() async {
    try {
      return await _storage.read(key: _jwtTokenKey);
    } catch (e) {
      print('❌ Error reading JWT token: $e');
      return null;
    }
  }
  
  /// Store JWT token securely
  static Future<void> storeJwtToken(String token) async {
    try {
      await _storage.write(key: _jwtTokenKey, value: token);
      print('✅ JWT token stored successfully');
    } catch (e) {
      print('❌ Error storing JWT token: $e');
    }
  }
  
  /// Store user info securely
  static Future<void> storeUserInfo(Map<String, dynamic> userInfo) async {
    try {
      await _storage.write(key: _userInfoKey, value: jsonEncode(userInfo));
      print('✅ User info stored successfully');
    } catch (e) {
      print('❌ Error storing user info: $e');
    }
  }
  
  /// Get stored user info
  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final userInfoString = await _storage.read(key: _userInfoKey);
      if (userInfoString != null) {
        return jsonDecode(userInfoString);
      }
      return null;
    } catch (e) {
      print('❌ Error reading user info: $e');
      return null;
    }
  }
  
  /// Clear stored authentication data
  static Future<void> clearAuthData() async {
    try {
      await _storage.delete(key: _jwtTokenKey);
      await _storage.delete(key: _userInfoKey);
      print('✅ Authentication data cleared');
    } catch (e) {
      print('❌ Error clearing auth data: $e');
    }
  }
  
  /// Get headers with JWT token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await getJwtToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    if (token != null) {
      print('🔑 JWT token found: ${token.substring(0, 20)}...');
    } else {
      print('⚠️ No JWT token found - request will be unauthenticated');
    }
    
    return headers;
  }
  
  /// Handle API response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    print('📡 API Response: ${response.statusCode} - ${response.body}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = jsonDecode(response.body);
        print('📥 Parsed response: $data');
        return data;
      } catch (e) {
        print('⚠️ Failed to parse JSON response: $e');
        return {'success': true, 'data': response.body, 'rawResponse': response.body};
      }
    } else if (response.statusCode == 401) {
      // Handle JWT token expiration
      print('🔒 Unauthorized - JWT token may be expired');
      throw Exception('Authentication failed. Please login again.');
    } else {
      try {
        final errorData = jsonDecode(response.body);
        print('❌ API Error: $errorData');
        throw Exception(errorData['message'] ?? errorData['error'] ?? 'API request failed');
      } catch (e) {
        print('❌ HTTP Error: ${response.statusCode} - ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    }
  }
  
  /// Login user with Firebase ID token, UID, FCM token, phone number, and name
  static Future<Map<String, dynamic>> loginUser({
    required String idToken,
    required String uid,
    required String fcmToken,
    required String phoneNumber,
    String? name,
  }) async {
    try {
      print('🔐 Logging in user: $phoneNumber');
      
      final requestBody = {
        'idToken': idToken, // Firebase ID token for backend verification
        'uid': uid,
        'fcmToken': fcmToken,
        'phone': phoneNumber, // Changed from 'phoneNumber' to 'phone' to match your API
        'name': name ?? 'User', // Added name field as required by your API
      };
      
      print('📤 Sending login request to: $_baseUrl${AppConfig.loginEndpoint}');
      print(jsonEncode(requestBody));
      
      final response = await http.post(
        Uri.parse('$_baseUrl${AppConfig.loginEndpoint}'),
        headers: await _getHeaders(),
        body: jsonEncode(requestBody),
      );
      
      final respData = _handleResponse(response);
      final data = respData['data'];

      // Store JWT token and user info
      if (data['accessToken'] != null) {
        await storeJwtToken(data['accessToken']);
        print('✅ JWT token stored');
      } else {
        print('⚠️ No JWT token in response');
      }
      
      if (data['user'] != null) {
        await storeUserInfo(data['user']);
        print('✅ User info stored');
      } else {
        print('⚠️ No user info in response');
      }
      
      print('✅ Login successful');
      print('📥 Response data: $data');
      return data;
      
    } catch (e) {
      print('❌ Login failed: $e');
      rethrow;
    }
  }
  
  /// Get users list from backend database
  static Future<List<Map<String, dynamic>>> getUsersList({
    int page = 1,
    int limit = 20,
    String search = '',
    bool onlineOnly = false,
  }) async {
    try {
      print('👥 Fetching users list from backend database');
      
      // Check if user is authenticated
      final isAuth = await isAuthenticated();
      if (!isAuth) {
        throw Exception('User not authenticated. Please login first.');
      }
      
      // Get JWT token for debugging
      final token = await getJwtToken();
      print('🔑 Using JWT token: ${token?.substring(0, 20)}...');
      
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (search.isNotEmpty) 'search': search,
        if (onlineOnly) 'onlineOnly': 'true',
      };
      
      final uri = Uri.parse('$_baseUrl${AppConfig.usersEndpoint}').replace(
        queryParameters: queryParams,
      );
      
      print('📤 Requesting: $uri');
      
      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );
      
      final data = _handleResponse(response);
      
      // Handle backend response structure
      List<Map<String, dynamic>> users = [];
      if (data['success'] == true && data['data'] != null) {
        final responseData = data['data'];
        if (responseData['users'] != null) {
          users = List<Map<String, dynamic>>.from(responseData['users']);
          
          // Log pagination info
          if (responseData['pagination'] != null) {
            final pagination = responseData['pagination'];
            print('📊 Pagination: Page ${pagination['currentPage']}/${pagination['totalPages']} (${pagination['totalUsers']} total users)');
          }
        } else {
          print('⚠️ No users array in response data: $responseData');
        }
      } else {
        print('⚠️ Unexpected response structure: $data');
        throw Exception('Invalid response format from server');
      }
      
      print('✅ Successfully fetched ${users.length} users from database');
      
      // Log user details for debugging
      for (final user in users) {
        print('👤 User: ${user['name']} (${user['uid']}) - Online: ${user['isOnline']}');
      }
      
      return users;
      
    } catch (e) {
      print('❌ Failed to fetch users from database: $e');
      rethrow;
    }
  }
  
  /// Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? avatar,
    String? status,
  }) async {
    try {
      print('👤 Updating profile');
      
      final response = await http.put(
        Uri.parse('$_baseUrl${AppConfig.profileEndpoint}'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'name': name,
          if (avatar != null) 'avatar': avatar,
          if (status != null) 'status': status,
        }),
      );
      
      final data = _handleResponse(response);
      
      // Update stored user info
      if (data['user'] != null) {
        await storeUserInfo(data['user']);
      }
      
      print('✅ Profile updated successfully');
      return data;
      
    } catch (e) {
      print('❌ Profile update failed: $e');
      rethrow;
    }
  }
  
  /// Send FCM token to backend
  static Future<void> sendFcmToken(String fcmToken) async {
    try {
      print('📱 Sending FCM token to backend');
      
      final response = await http.post(
        Uri.parse('$_baseUrl${AppConfig.fcmTokenEndpoint}'),
        headers: await _getHeaders(),
        body: jsonEncode({'fcmToken': fcmToken}),
      );
      
      _handleResponse(response);
      print('✅ FCM token sent successfully');
      
    } catch (e) {
      print('❌ Failed to send FCM token: $e');
      // Don't rethrow - this is not critical
    }
  }
  
  /// Logout user
  static Future<void> logout() async {
    try {
      print('🚪 Logging out user');
      
      final response = await http.post(
        Uri.parse('$_baseUrl${AppConfig.logoutEndpoint}'),
        headers: await _getHeaders(),
      );
      
      _handleResponse(response);
      await clearAuthData();
      print('✅ Logout successful');
      
    } catch (e) {
      print('❌ Logout failed: $e');
      // Clear local data even if API call fails
      await clearAuthData();
    }
  }
  
  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getJwtToken();
    return token != null && token.isNotEmpty;
  }
  
  /// Refresh JWT token
  static Future<String?> refreshToken() async {
    try {
      print('🔄 Refreshing JWT token');
      
      final response = await http.post(
        Uri.parse('$_baseUrl${AppConfig.refreshTokenEndpoint}'),
        headers: await _getHeaders(),
      );
      
      final data = _handleResponse(response);
      
      if (data['token'] != null) {
        await storeJwtToken(data['token']);
        print('✅ Token refreshed successfully');
        return data['token'];
      }
      
      return null;
      
    } catch (e) {
      print('❌ Token refresh failed: $e');
      return null;
    }
  }
}

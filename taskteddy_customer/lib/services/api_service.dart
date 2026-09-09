import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';

/// Thrown when the backend rejects the token (HTTP 401). Callers/refresh logic
/// use this to trigger an automatic logout.
class UnauthorizedException implements Exception {
  const UnauthorizedException([this.message = 'Session expired']);
  final String message;
  @override
  String toString() => message;
}

// HTTP client with timeout
final _client = http.Client();

http.Client get httpClient => _client;

// Backend base URL.
//
// Production/staging builds MUST pass the URL at compile time, e.g.:
//   flutter build apk --dart-define=API_BASE_URL=https://api.taskteddy.com
//   flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8000   (physical device dev)
//
// When API_BASE_URL is not provided we fall back to sensible LOCAL dev defaults
// (never a hardcoded personal Wi-Fi IP): the Android emulator reaches the host
// via 10.0.2.2, the iOS simulator and web via localhost.
const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

String get _base {
  if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
  // Backend is published on host port 8080 (docker maps 8080->8000).
  if (kIsWeb) return 'http://localhost:8080';
  if (Platform.isAndroid) return 'http://10.0.2.2:8080';
  return 'http://localhost:8080';
}

class ApiService {
  static String get baseUrl => _base;

  /// Resolve a media path returned by the backend into a loadable URL.
  /// Absolute URLs and bundled asset paths are returned unchanged; relative
  /// server paths (e.g. `/uploads/x.jpg`) are prefixed with the API base.
  static String? resolveMediaUrl(String? path) {
    if (path == null) return null;
    final value = path.trim();
    if (value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('assets/')) return value;
    if (value.startsWith('/')) return '$_base$value';
    return '$_base/$value';
  }

  static String indiaPhoneNumber(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 12 && digits.startsWith('91')) {
      return '+91${digits.substring(digits.length - 10)}';
    }
    if (digits.length >= 10) {
      return '+91${digits.substring(digits.length - 10)}';
    }
    return '+91$digits';
  }

  static String loginIdentifier(String value) {
    final text = value.trim();
    if (text.contains('@')) return text.toLowerCase();
    return indiaPhoneNumber(text);
  }

  static int _numericId(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    final text = value?.toString() ?? '0';
    return int.tryParse(text) ??
        int.tryParse(RegExp(r'\d+').firstMatch(text)?.group(0) ?? '') ??
        text.hashCode.abs();
  }

  static double _doubleValue(dynamic value, [double fallback = 0]) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static ServiceModel _serviceFromJson(Map<String, dynamic> json) {
    final price = _doubleValue(json['price']);
    return ServiceModel(
      id: _numericId(json['id']),
      name: json['name']?.toString() ?? 'Service',
      emoji: json['emoji']?.toString() ?? '',
      category: json['category']?.toString() ?? 'other',
      description: json['description']?.toString() ?? '',
      iconAsset:
          json['icon_asset']?.toString() ?? json['iconAsset']?.toString(),
      price: price,
      originalPrice:
          _doubleValue(json['original_price'] ?? json['originalPrice'], price),
      rating: _doubleValue(json['rating'], 5),
      reviewCount: _numericId(json['review_count'] ?? json['reviewCount'] ?? 0),
      isHot: json['is_hot'] ?? json['isHot'] ?? false,
      isNew: json['is_new'] ?? json['isNew'] ?? false,
      includes: List<String>.from(json['includes'] ?? []),
    );
  }

  static UserModel _userFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const UserModel(id: 0, name: 'Customer', email: '');
    }
    return UserModel(
      id: _numericId(json['id']),
      remoteId: json['id']?.toString(),
      name: json['name']?.toString() ?? 'User',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      avatarUrl: (json['avatar_url']?.toString().isNotEmpty == true) 
          ? json['avatar_url']?.toString() 
          : (json['avatarUrl']?.toString().isNotEmpty == true) ? json['avatarUrl']?.toString() : null,
      rating: _doubleValue(json['rating'], 0),
      totalReviews:
          _numericId(json['total_reviews'] ?? json['totalReviews'] ?? 0),
      coins: _numericId(json['coins'] ?? 0),
      isVerified: json['is_verified'] == true || json['isVerified'] == true,
      completedTasks:
          _numericId(json['completed_tasks'] ?? json['completedTasks'] ?? 0),
      reputation: _reputationFromJson(json['reputation']),
    );
  }

  /// Parses the optional public `reputation` block. Returns null for older
  /// payloads that omit it so callers stay null-safe.
  static Reputation? _reputationFromJson(dynamic raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final next = m['next_level_at'] ?? m['nextLevelAt'];
    return Reputation(
      level: m['level']?.toString() ?? 'new',
      levelLabel:
          m['level_label']?.toString() ?? m['levelLabel']?.toString() ?? '',
      reliability: _numericId(m['reliability'] ?? 0),
      completedTasks:
          _numericId(m['completed_tasks'] ?? m['completedTasks'] ?? 0),
      cancelCount: _numericId(m['cancel_count'] ?? m['cancelCount'] ?? 0),
      nextLevelAt: next == null ? null : _numericId(next),
    );
  }

  static ServiceModel _bookingServiceFromJson(Map<String, dynamic> json) {
    final serviceJson = json['service'];
    if (serviceJson is Map<String, dynamic>) {
      return _serviceFromJson(serviceJson);
    }

    final fallbackId = _numericId(json['service_id'] ?? json['serviceId'] ?? 0);
    return ServiceModel(
      id: fallbackId,
      name: 'Service #$fallbackId',
      emoji: '',
      category: 'service',
      description: 'Booked service',
      price: _doubleValue(json['amount'] ?? json['total_amount'] ?? 0),
      originalPrice: _doubleValue(json['amount'] ?? json['total_amount'] ?? 0),
      rating: 0,
      reviewCount: 0,
      includes: const [],
    );
  }

  static ApplicationModel _applicationFromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: _numericId(json['id']),
      remoteId: json['id']?.toString(),
      taskId: json['task_id']?.toString() ?? json['task']?['id']?.toString(),
      task: json['task'] != null ? _taskFromJson(Map<String, dynamic>.from(json['task'])) : null,
      applicant: _userFromJson(Map<String, dynamic>.from(json['applicant'] ?? {})),
      bidAmount: _doubleValue(json['bid_amount']),
      coverLetter: json['cover_letter']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      appliedAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Maps the backend `status` string onto a [TaskStatus]. Handles both the
  /// snake_case (`pending_review`, `in_progress`) and camelCase forms the API
  /// may emit, defaulting to [TaskStatus.open] for anything unrecognised.
  static TaskStatus _taskStatusFromString(String raw) {
    switch (raw) {
      case 'pending_review':
      case 'pendingReview':
        return TaskStatus.pendingReview;
      case 'open':
        return TaskStatus.open;
      case 'assigned':
        return TaskStatus.assigned;
      case 'in_progress':
      case 'inProgress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'cancelled':
      case 'canceled':
        return TaskStatus.cancelled;
      case 'rejected':
        return TaskStatus.rejected;
      default:
        return TaskStatus.open;
    }
  }

  static TaskModel _taskFromJson(Map<String, dynamic> json) {
    final categoryName = json['category']?.toString() ?? 'other';
    final statusName = json['status']?.toString() ?? 'open';
    final assigned = json['assigned_to'] is Map
        ? Map<String, dynamic>.from(json['assigned_to'] as Map)
        : (json['assigned_to_info'] is Map
            ? Map<String, dynamic>.from(json['assigned_to_info'] as Map)
            : null);
    return TaskModel(
      id: _numericId(json['id']),
      remoteId: json['id']?.toString(),
      title: json['title']?.toString() ?? 'Task',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? 'Nearby',
      category: TaskCategory.values.firstWhere(
        (c) => c.name == categoryName,
        orElse: () => TaskCategory.other,
      ),
      status: _taskStatusFromString(statusName),
      budget: _doubleValue(json['budget']),
      deadline: DateTime.tryParse(json['deadline']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 1)),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      postedBy: _userFromJson(
        json['posted_by'] is Map
            ? Map<String, dynamic>.from(json['posted_by'] as Map)
            : null,
      ),
      assignedTo: assigned == null ? null : _userFromJson(assigned),
      applicantsCount:
          _numericId(json['applicants_count'] ?? json['applicantsCount'] ?? 0),
      completionOtp: json['completion_otp']?.toString() ??
          json['completionOtp']?.toString(),
      onTheWayAt: DateTime.tryParse(
          (json['on_the_way_at'] ?? json['onTheWayAt'])?.toString() ?? ''),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      cancelReason: json['cancel_reason']?.toString() ??
          json['cancelReason']?.toString(),
      cancelledBy: json['cancelled_by']?.toString() ??
          json['cancelledBy']?.toString(),
      reviewReason: json['review_reason']?.toString() ??
          json['reviewReason']?.toString(),
      reviewed: json['reviewed'] == true,
    );
  }

  // User-friendly error messages
  static String _errorMessage(http.Response res, String fallback) {
    try {
      final data = jsonDecode(res.body);
      if (data is Map) {
        // Handle detail field (FastAPI standard error format)
        if (data['detail'] != null) {
          final detail = data['detail'];
          if (detail is List && detail.isNotEmpty) {
            // Validation error array
            final first = detail.first;
            if (first is Map) {
              final msg = first['msg']?.toString() ?? '';
              final loc = first['loc'] as List?;
              if (loc != null) {
                final field = loc.last?.toString() ?? '';
                return _mapValidationError(field, msg);
              }
              return _mapErrorMessage(msg);
            }
          }
          // Single detail string or object
          return _mapErrorMessage(detail.toString());
        }
        // Handle custom error messages from our API
        if (data['message'] != null) {
          return _mapErrorMessage(data['message'].toString());
        }
      }
    } catch (_) {}
    return _mapErrorMessage(fallback);
  }

  // Map technical errors to user-friendly messages
  static String _mapValidationError(String field, String msg) {
    if (field.contains('phone')) {
      return 'Please enter a valid 10-digit phone number';
    }
    if (field.contains('email')) {
      return 'Please enter a valid email address';
    }
    if (field.contains('otp')) {
      return 'Please enter the 6-digit OTP';
    }
    return _mapErrorMessage(msg);
  }

  static String _mapErrorMessage(String msg) {
    final lower = msg.toLowerCase();

    // Network errors
    if (lower.contains('connection') ||
        lower.contains('socket') ||
        lower.contains('timeout')) {
      return 'Unable to connect. Please check your internet connection.';
    }
    if (lower.contains('refused')) {
      return 'Server is not responding. Please try again later.';
    }

    // Auth errors
    if (lower.contains('invalid otp') || lower.contains('expired otp')) {
      return 'Invalid or expired OTP. Please request a new OTP.';
    }
    if (lower.contains('too many') || lower.contains('rate limit')) {
      return 'Too many attempts. Please try again after some time.';
    }
    if (lower.contains('not found')) {
      return 'User not found. Please register first.';
    }
    if (lower.contains('unauthorized') || lower.contains('unauthorized')) {
      return 'Please log in again.';
    }

    // Validation errors
    if (lower.contains('field required') || lower.contains('missing')) {
      return 'Please fill in all required fields.';
    }
    if (lower.contains('min_length') || lower.contains('too short')) {
      return 'Input is too short. Please check and try again.';
    }
    if (lower.contains('max_length') || lower.contains('too long')) {
      return 'Input is too long. Please shorten it.';
    }

    // Server errors
    if (lower.contains('500') ||
        lower.contains('internal') ||
        lower.contains('server error')) {
      return 'Something went wrong. Please try again later.';
    }
    if (lower.contains('503') || lower.contains('unavailable')) {
      return 'Service is temporarily unavailable. Please try again later.';
    }

    // Default - return a clean message
    return msg.isNotEmpty ? msg : 'Something went wrong. Please try again.';
  }

  static Future<Map<String, String>> _headers() async {
    final token = await Session.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ========== AUTHENTICATION ==========

  // Send OTP to phone number
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$_base/api/auth/send-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone': indiaPhoneNumber(phone),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception(_errorMessage(res, 'Failed to send OTP'));
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Verify OTP and login
  static Future<Map<String, dynamic>> verifyOtp(
      String phone, String otp) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$_base/api/auth/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone': indiaPhoneNumber(phone),
              'otp': otp,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception(_errorMessage(res, 'Invalid OTP'));
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Best-effort server-side token revocation. Callers should still clear the
  /// local session regardless of the outcome — network failures are ignored.
  static Future<void> logout() async {
    try {
      await _client
          .post(
            Uri.parse('$_base/api/auth/logout'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      developer.log('Logout revoke error (ignored): $e', name: 'ApiService');
    }
  }

  static Future<Map<String, dynamic>> getMe() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/users/me'),
        headers: await _headers(),
      );

      if (res.statusCode == 200) {
        final user = jsonDecode(res.body) as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(user));
        return user;
      } else if (res.statusCode == 401) {
        throw const UnauthorizedException();
      } else {
        throw Exception(_errorMessage(res, 'Could not load profile'));
      }
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<Map<String, dynamic>> updateMe({
    required String name,
    required String phone,
    required String location,
    required String bio,
    String? email,
    String? title,
    String? gender,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name,
        'phone': indiaPhoneNumber(phone),
        'location': location,
        'bio': bio,
        if (email != null) 'email': email.trim().toLowerCase(),
        if (title != null) 'title': title,
        if (gender != null) 'gender': gender,
      };
      final res = await http.patch(
        Uri.parse('$_base/api/users/me'),
        headers: await _headers(),
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        final user = jsonDecode(res.body) as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(user));
        return user;
      } else {
        throw Exception(_errorMessage(res, 'Could not update profile'));
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Upload a new profile avatar (multipart `file`). Returns the updated user
  /// profile with the new avatar_url (also persisted to the local cache).
  static Future<Map<String, dynamic>> uploadAvatar(XFile file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/api/users/me/avatar'),
    );
    final authHeaders = await _headers();
    authHeaders.remove('Content-Type');
    request.headers.addAll(authHeaders);

    final bytes = await file.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: file.name,
    ));

    final streamed = await _client.send(request);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      // Merge the new avatar_url into the cached user so the UI stays in sync.
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('user');
      if (cached != null) {
        final user = Map<String, dynamic>.from(jsonDecode(cached) as Map);
        user['avatar_url'] = data['avatar_url'];
        await prefs.setString('user', jsonEncode(user));
        return user;
      }
      return data;
    }
    throw Exception(_errorMessage(res, 'Failed to upload avatar'));
  }

  /// Set the user's display name and (pending) email in one PATCH — used by the
  /// welcome-bonus claim flow. Only these two fields are sent, so nothing else
  /// on the profile is touched.
  static Future<Map<String, dynamic>> setNameAndEmail({
    required String name,
    required String email,
  }) async {
    final res = await http.patch(
      Uri.parse('$_base/api/users/me'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
      }),
    );
    if (res.statusCode == 200) {
      final user = jsonDecode(res.body) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(user));
      return user;
    }
    throw Exception(_errorMessage(res, 'Could not save your details'));
  }

  static Future<Map<String, dynamic>> verifyEmail({
    required String code,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/api/users/me/verify-email'),
        headers: await _headers(),
        body: jsonEncode({'code': code}),
      );

      if (res.statusCode == 200) {
        final user = jsonDecode(res.body) as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(user));
        return user;
      } else {
        throw Exception(_errorMessage(res, 'Could not verify email'));
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Request a new email verification code/link
  static Future<Map<String, dynamic>> requestEmailVerification() async {
    try {
      final res = await http.post(
        Uri.parse('$_base/api/users/me/request-email-verification'),
        headers: await _headers(),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data;
      } else {
        throw Exception(_errorMessage(res, 'Could not request verification'));
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ========== SERVICES ==========

  static List<ServiceModel> _parseServices(String body) {
    final decoded = jsonDecode(body);
    final List<dynamic> data;
    if (decoded is List) {
      data = decoded;
    } else if (decoded is Map && decoded['services'] is List) {
      data = List<dynamic>.from(decoded['services'] as List);
    } else if (decoded is Map && decoded['items'] is List) {
      data = List<dynamic>.from(decoded['items'] as List);
    } else {
      developer.log('Unexpected services payload: $decoded',
          name: 'ApiService');
      return [];
    }
    return data
        .whereType<Map>()
        .map((json) => _serviceFromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  /// Instantly returns the last successfully fetched services (may be empty).
  /// Used to paint the home screen before the network round-trip completes.
  static Future<List<ServiceModel>> getCachedServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('services_cache');
      if (raw == null || raw.isEmpty) return [];
      return _parseServices(raw);
    } catch (_) {
      return [];
    }
  }

  /// Fetch services, optionally filtered/sorted by the discovery endpoint.
  ///
  /// [sort] ∈ {recommended, price_low, price_high, rating, newest}. When any
  /// filter is supplied the full-catalog cache is left untouched (so a search
  /// never clobbers the home screen's offline snapshot). Pass
  /// [throwOnError] to distinguish a load failure from a genuinely empty
  /// result so the caller can show a retry state.
  static Future<List<ServiceModel>> getServices({
    String? q,
    String? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? sort,
    bool throwOnError = false,
  }) async {
    final query = <String, String>{};
    final trimmedQ = q?.trim();
    if (trimmedQ != null && trimmedQ.isNotEmpty) query['q'] = trimmedQ;
    if (category != null && category.isNotEmpty && category != 'all') {
      query['category'] = category;
    }
    if (minPrice != null) query['min_price'] = minPrice.toStringAsFixed(0);
    if (maxPrice != null) query['max_price'] = maxPrice.toStringAsFixed(0);
    if (minRating != null && minRating > 0) {
      query['min_rating'] = minRating.toString();
    }
    if (sort != null && sort.isNotEmpty && sort != 'recommended') {
      query['sort'] = sort;
    }
    final hasFilters = query.isNotEmpty;
    try {
      // Trailing slash avoids a 307 redirect round-trip on every load.
      final uri = Uri.parse('$_base/api/services/')
          .replace(queryParameters: query.isEmpty ? null : query);
      final res = await _client
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final services = _parseServices(res.body);
        // Only the unfiltered full catalog is cached for offline paint.
        if (!hasFilters && services.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('services_cache', res.body);
        }
        return services;
      }
      throw Exception(_errorMessage(res, 'Failed to load services'));
    } catch (e) {
      developer.log('Get services error: $e', name: 'ApiService');
      if (throwOnError) {
        throw Exception(e.toString().replaceAll('Exception: ', ''));
      }
      return [];
    }
  }

  /// Distinct service categories with their counts, from
  /// GET /services/categories → [{category, count}].
  static Future<List<Map<String, dynamic>>> getServiceCategories() async {
    try {
      final res = await _client
          .get(Uri.parse('$_base/api/services/categories'),
              headers: await _headers())
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
      }
      throw Exception(_errorMessage(res, 'Failed to load categories'));
    } catch (e) {
      developer.log('Get service categories error: $e', name: 'ApiService');
      return [];
    }
  }

  static Future<ServiceModel?> getServiceById(String id) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/services/$id'),
        headers: await _headers(),
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        return _serviceFromJson(json);
      }
      return null;
    } catch (e) {
      developer.log('Get service by ID error: $e', name: 'ApiService');
      return null;
    }
  }

  // ========== BOOKINGS ==========

  static Future<Map<String, dynamic>> createBooking({
    required String serviceId,
    required DateTime scheduledAt,
    required String address,
    String? notes,
    bool payWithWallet = false,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/api/bookings/'),
        headers: await _headers(),
        body: jsonEncode({
          'service_id': serviceId,
          'scheduled_at': scheduledAt.toIso8601String(),
          'address': address,
          'notes': notes ?? '',
          'pay_with_wallet': payWithWallet,
        }),
      );

      if (res.statusCode == 201) {
        return jsonDecode(res.body);
      } else if (res.statusCode == 401) {
        throw const UnauthorizedException();
      } else {
        throw Exception(_errorMessage(res, 'Booking failed'));
      }
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      developer.log('Create booking error: $e', name: 'ApiService');
      throw Exception('Failed to create booking. Please try again.');
    }
  }

  /// Cancel one of the current user's bookings. [bookingUuid] is the record's
  /// primary id (not the human-readable BOOK_xxx reference). Returns the
  /// response (includes `refunded` when the booking was wallet-paid).
  static Future<Map<String, dynamic>> cancelBooking(String bookingUuid) async {
    final res = await _client.post(
      Uri.parse('$_base/api/bookings/$bookingUuid/cancel'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res, 'Could not cancel booking'));
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Move an upcoming booking to a new date/time.
  static Future<void> rescheduleBooking(
      String bookingUuid, DateTime newTime) async {
    final res = await _client.patch(
      Uri.parse('$_base/api/bookings/$bookingUuid/reschedule'),
      headers: await _headers(),
      body: jsonEncode({'scheduled_at': newTime.toIso8601String()}),
    );
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res, 'Could not reschedule booking'));
    }
  }

  static Future<List<BookingModel>> getBookings({bool throwOnError = false}) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/bookings/'),
        headers: await _headers(),
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((json) {
          return BookingModel(
            id: _numericId(json['id']),
            remoteId: json['id']?.toString(),
            bookingId:
                (json['booking_id'] ?? json['bookingId'] ?? '').toString(),
            customer: _userFromJson(
              json['customer'] is Map
                  ? Map<String, dynamic>.from(json['customer'] as Map)
                  : null,
            ),
            service: _bookingServiceFromJson(Map<String, dynamic>.from(json)),
            scheduledAt:
                DateTime.tryParse(json['scheduled_at']?.toString() ?? '') ??
                    DateTime.now(),
            address: json['address']?.toString() ?? '',
            status: json['status']?.toString() ?? 'pending',
            amount: _doubleValue(json['total_amount'] ?? json['amount']),
            notes: json['notes']?.toString() ?? '',
            paidWithWallet: json['paid_with_wallet'] == true,
          );
        }).toList();
      }
      throw Exception(_errorMessage(res, 'Failed to load bookings'));
    } catch (e) {
      developer.log('Get bookings error: $e', name: 'ApiService');
      if (throwOnError) throw Exception(e.toString().replaceAll('Exception: ', ''));
      return [];
    }
  }

  /// Submit a review for a completed task's tasker.
  static Future<void> createReview({
    required String taskId,
    required String reviewedUserId,
    required double rating,
    String? comment,
  }) async {
    final res = await _client.post(
      Uri.parse('$_base/api/reviews/'),
      headers: await _headers(),
      body: jsonEncode({
        'task_id': taskId,
        'reviewed_user_id': reviewedUserId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(_errorMessage(res, 'Could not submit review'));
    }
  }

  /// Positional-argument alias for [createReview] — rate the tasker assigned to
  /// a completed task (rating 1–5).
  static Future<void> submitReview(
    String taskId,
    String reviewedUserId,
    double rating,
    String? comment,
  ) =>
      createReview(
        taskId: taskId,
        reviewedUserId: reviewedUserId,
        rating: rating,
        comment: comment,
      );

  // ========== WALLET ==========

  /// Returns the wallet balance, or `null` when the balance could not be
  /// loaded. A null result is distinct from a genuine ₹0 balance so the UI can
  /// surface a retry instead of silently showing zero.
  static Future<double?> getWalletBalance() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/wallet/balance'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return _doubleValue(data['balance']);
      }
      throw Exception(_errorMessage(res, 'Failed to load wallet balance'));
    } catch (e) {
      developer.log('Get wallet balance error: $e', name: 'ApiService');
      return null;
    }
  }

  /// The customer's non-withdrawable TaskTeddy bonus (₹ + discount rules).
  static Future<Map<String, dynamic>?> getPromoBalance() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/wallet/promo'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      }
      return null;
    } catch (e) {
      developer.log('Get promo balance error: $e', name: 'ApiService');
      return null;
    }
  }

  /// Billing summary for a task: amount, available bonus, net payable.
  static Future<Map<String, dynamic>?> getTaskCheckout(String taskId) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/tasks/$taskId/checkout'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      }
      return null;
    } catch (e) {
      developer.log('Get checkout error: $e', name: 'ApiService');
      return null;
    }
  }

  /// Apply / remove the TaskTeddy bonus on a task. Returns the updated summary.
  static Future<Map<String, dynamic>> applyTaskBonus(String taskId,
      {required bool apply}) async {
    final path = apply ? 'apply-bonus' : 'remove-bonus';
    final res = await http.post(
      Uri.parse('$_base/api/tasks/$taskId/$path'),
      headers: await _headers(),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    }
    throw Exception(_errorMessage(res, 'Could not update bonus'));
  }

  static Future<Map<String, dynamic>> topUpWallet({
    required double amount,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/api/wallet/topup'),
        headers: await _headers(),
        body: jsonEncode({'amount': amount}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      }
      throw Exception(_errorMessage(res, 'Failed to add wallet money'));
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<List<Map<String, dynamic>>> getWalletTransactions({
    int limit = 20,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/wallet/transactions?limit=$limit'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
      }
      throw Exception(_errorMessage(res, 'Failed to load wallet transactions'));
    } catch (e) {
      developer.log('Get wallet transactions error: $e', name: 'ApiService');
      return [];
    }
  }

  // ========== TASKS ==========

  static Future<Map<String, dynamic>> createTask({
    required String title,
    required String description,
    required String category,
    required double budget,
    required String location,
    required DateTime deadline,
    List<String>? images,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/api/tasks'),
        headers: await _headers(),
        body: jsonEncode({
          'title': title,
          'description': description,
          'category': category,
          'budget': budget,
          'location': location,
          'deadline': deadline.toIso8601String(),
          'images': images ?? [],
        }),
      );

      if (res.statusCode == 201) {
        return jsonDecode(res.body);
      } else {
        throw Exception(_errorMessage(res, 'Task creation failed'));
      }
    } catch (e) {
      developer.log('Create task error: $e', name: 'ApiService');
      throw Exception('Failed to create task. Please try again.');
    }
  }

  // New frontend contract for uploading task photos before task creation.
  static Future<List<String>> uploadTaskImages({
    required List<String> imagePaths,
  }) async {
    if (imagePaths.isEmpty) return const [];
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_base/api/tasks/uploads'),
      );
      final authHeaders = await _headers();
      authHeaders.remove('Content-Type');
      request.headers.addAll(authHeaders);

      for (final path in imagePaths) {
        request.files.add(await http.MultipartFile.fromPath('files', path));
      }

      final streamed = await _client.send(request);
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        if (data is Map && data['image_urls'] is List) {
          return List<String>.from(data['image_urls']);
        }
        if (data is Map && data['images'] is List) {
          return List<String>.from(data['images']);
        }
        return const [];
      }
      throw Exception(_errorMessage(res, 'Failed to upload task images'));
    } catch (e) {
      developer.log('Upload task images error: $e', name: 'ApiService');
      return const [];
    }
  }

  /// Fetch the user's tasks. When [throwOnError] is true a failure is rethrown
  /// so the caller can show an error/retry state instead of an empty list that
  /// is indistinguishable from "you have no tasks".
  static Future<List<TaskModel>> getTasks(
      {String? status, bool throwOnError = false}) async {
    try {
      final uri = status != null
          ? Uri.parse('$_base/api/tasks?status=$status')
          : Uri.parse('$_base/api/tasks');

      final res = await http.get(uri, headers: await _headers());

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((json) => _taskFromJson(json)).toList();
      }
      throw Exception(_errorMessage(res, 'Failed to load tasks'));
    } catch (e) {
      developer.log('Get tasks error: $e', name: 'ApiService');
      if (throwOnError) throw Exception(e.toString().replaceAll('Exception: ', ''));
      return [];
    }
  }

  /// Fetch a single task (includes completion_otp when the caller owns it).
  static Future<TaskModel?> getTaskById(String taskId) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/tasks/$taskId'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        return _taskFromJson(Map<String, dynamic>.from(jsonDecode(res.body)));
      }
      throw Exception(_errorMessage(res, 'Failed to load task'));
    } catch (e) {
      developer.log('Get task by id error: $e', name: 'ApiService');
      return null;
    }
  }

  static Future<List<ApplicationModel>> getTaskApplications(String taskId) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/applications/task/$taskId'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((json) => _applicationFromJson(json)).toList();
      }
      throw Exception(_errorMessage(res, 'Failed to load bids'));
    } catch (e) {
      developer.log('Get task bids error: $e', name: 'ApiService');
      return [];
    }
  }

  static Future<void> acceptApplication(String applicationId) async {
    try {
      final res = await http.patch(
        Uri.parse('$_base/api/applications/$applicationId/accept'),
        headers: await _headers(),
      );
      if (res.statusCode != 200) {
        throw Exception(_errorMessage(res, 'Failed to accept bid'));
      }
    } catch (e) {
      developer.log('Accept bid error: $e', name: 'ApiService');
      rethrow;
    }
  }

  static Future<void> rejectApplication(String applicationId) async {
    try {
      final res = await http.patch(
        Uri.parse('$_base/api/applications/$applicationId/reject'),
        headers: await _headers(),
      );
      if (res.statusCode != 200) {
        throw Exception(_errorMessage(res, 'Failed to reject bid'));
      }
    } catch (e) {
      developer.log('Reject bid error: $e', name: 'ApiService');
      rethrow;
    }
  }

  // ===== Offer-comparison aliases (customer-facing naming) =====

  /// Offers (applications) received on a customer's own posted task.
  static Future<List<ApplicationModel>> getTaskOffers(String taskId) =>
      getTaskApplications(taskId);

  /// Accept an offer — assigns the task and rejects the others.
  static Future<void> acceptOffer(String offerId) =>
      acceptApplication(offerId);

  /// Decline a single offer.
  static Future<void> rejectOffer(String offerId) =>
      rejectApplication(offerId);

  // ========== SAFETY (report / block) ==========

  /// Report a user for a policy violation. [reason] must be one of the backend
  /// enum values: inappropriate_behaviour, no_show, safety_concern,
  /// fraud_or_scam, poor_quality, spam, other.
  static Future<void> reportUser({
    required String reportedId,
    required String reason,
    String? detail,
    String? taskId,
  }) async {
    final res = await _client.post(
      Uri.parse('$_base/api/safety/report'),
      headers: await _headers(),
      body: jsonEncode({
        'reported_id': reportedId,
        'reason': reason,
        if (detail != null && detail.trim().isNotEmpty) 'detail': detail.trim(),
        if (taskId != null && taskId.isNotEmpty) 'task_id': taskId,
      }),
    );
    if (res.statusCode == 401) throw const UnauthorizedException();
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(_errorMessage(res, 'Could not submit report'));
    }
  }

  /// Block a user so their content stops appearing.
  static Future<void> blockUser(String blockedId) async {
    final res = await _client.post(
      Uri.parse('$_base/api/safety/block'),
      headers: await _headers(),
      body: jsonEncode({'blocked_id': blockedId}),
    );
    if (res.statusCode == 401) throw const UnauthorizedException();
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(_errorMessage(res, 'Could not block user'));
    }
  }

  /// Remove a block.
  static Future<void> unblockUser(String blockedId) async {
    final res = await _client.delete(
      Uri.parse('$_base/api/safety/block/$blockedId'),
      headers: await _headers(),
    );
    if (res.statusCode == 401) throw const UnauthorizedException();
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(_errorMessage(res, 'Could not unblock user'));
    }
  }

  /// The current user's blocked list: [{id, blocked_id, user}].
  static Future<List<Map<String, dynamic>>> getBlocks() async {
    final res = await _client.get(
      Uri.parse('$_base/api/safety/blocks'),
      headers: await _headers(),
    );
    if (res.statusCode == 401) throw const UnauthorizedException();
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res, 'Failed to load blocked users'));
    }
    final List data = jsonDecode(res.body);
    return data
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getUserReviews(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/reviews/user/$userId'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
      }
      throw Exception(_errorMessage(res, 'Failed to load reviews'));
    } catch (e) {
      developer.log('Get user reviews error: $e', name: 'ApiService');
      return [];
    }
  }

  /// Cancel a posted task the customer owns. Works for OPEN and ASSIGNED tasks;
  /// cancelling an assigned job notifies the tasker server-side. An optional
  /// [reason] is passed through as a query param and stored on the task.
  static Future<void> cancelTask(String taskId, {String? reason}) async {
    try {
      final uri = Uri.parse('$_base/api/customer/tasks/$taskId').replace(
        queryParameters: (reason != null && reason.trim().isNotEmpty)
            ? {'reason': reason.trim()}
            : null,
      );
      final res = await http.delete(uri, headers: await _headers());
      if (res.statusCode != 200) {
        throw Exception(_errorMessage(res, 'Failed to cancel task'));
      }
    } catch (e) {
      developer.log('Cancel task error: $e', name: 'ApiService');
      rethrow;
    }
  }

  /// Live location of the assigned tasker while they are on the way.
  /// Returns null when no tasker is assigned (404) or the caller is not the
  /// poster (403), so the UI can simply hide the tracking card.
  static Future<TaskerLocation?> getTaskerLocation(String taskId) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/tasks/$taskId/tasker-location'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final data = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
        final tasker = data['tasker'] is Map
            ? Map<String, dynamic>.from(data['tasker'] as Map)
            : const <String, dynamic>{};
        return TaskerLocation(
          taskId: data['task_id']?.toString() ?? taskId,
          onTheWayAt:
              DateTime.tryParse(data['on_the_way_at']?.toString() ?? ''),
          latitude: (data['latitude'] as num?)?.toDouble(),
          longitude: (data['longitude'] as num?)?.toDouble(),
          lastLocationAt:
              DateTime.tryParse(data['last_location_at']?.toString() ?? ''),
          taskerName: tasker['name']?.toString(),
          taskerAvatarUrl: tasker['avatar_url']?.toString(),
        );
      }
      // 403 (not poster) / 404 (no tasker) — nothing to track.
      return null;
    } catch (e) {
      developer.log('Get tasker location error: $e', name: 'ApiService');
      return null;
    }
  }

  static Future<Map<String, dynamic>> updateTask(String taskId, Map<String, dynamic> payload) async {
    try {
      final res = await http.patch(
        Uri.parse('$_base/api/customer/tasks/$taskId'),
        headers: await _headers(),
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      }
      throw Exception(_errorMessage(res, 'Failed to update task'));
    } catch (e) {
      developer.log('Update task error: $e', name: 'ApiService');
      rethrow;
    }
  }

  // New frontend contract for Post Task screen:
  // Backend can return budget presets, SLA hints, and category guidance.
  static Future<Map<String, dynamic>> getTaskPostingMeta(
      {String? category}) async {
    try {
      final query = <String, String>{};
      if (category != null && category.isNotEmpty) {
        query['category'] = category;
      }
      final uri = Uri.parse('$_base/api/tasks/posting-meta')
          .replace(queryParameters: query.isEmpty ? null : query);
      final res = await http.get(uri, headers: await _headers());
      if (res.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      }
      throw Exception(_errorMessage(res, 'Failed to load posting metadata'));
    } catch (e) {
      developer.log('Get task posting meta error: $e', name: 'ApiService');
      return {
        'budget_presets': [499, 899, 1499, 2499],
      };
    }
  }

  // New frontend contract for market-rate and budget fit insights.
  static Future<Map<String, dynamic>> getTaskBudgetInsights({
    required String category,
    required String location,
    required double budget,
    String? urgency,
    int? expectedHours,
  }) async {
    try {
      // The backend reads these as query params (not a JSON body), so passing
      // them in the query string is what makes category-specific ranges work.
      final uri =
          Uri.parse('$_base/api/tasks/budget-insights').replace(queryParameters: {
        'category': category,
        'location': location,
        'budget': budget.toString(),
        if (urgency != null) 'urgency': urgency,
        if (expectedHours != null) 'expected_hours': expectedHours.toString(),
      });
      final res = await http.post(uri, headers: await _headers());
      if (res.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      }
      throw Exception(_errorMessage(res, 'Failed to fetch budget insights'));
    } catch (e) {
      developer.log('Task budget insight error: $e', name: 'ApiService');
      return {
        'note': 'Budget insights unavailable right now',
      };
    }
  }

  // ========== CHAT ==========

  static Future<Map<String, dynamic>?> createConversation({
    required String otherUserId,
    required String taskId,
  }) async {
    try {
      final res = await _client.post(
        Uri.parse('$_base/api/chat/conversations?other_user_id=$otherUserId&task_id=$taskId'),
        headers: await _headers(),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      developer.log('Create conversation error: $e', name: 'ApiService');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/chat/conversations'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
      }
      throw Exception(_errorMessage(res, 'Failed to load conversations'));
    } catch (e) {
      developer.log('Get conversations error: $e', name: 'ApiService');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getMessages(
      String conversationId) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/chat/conversations/$conversationId/messages'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
      }
      throw Exception(_errorMessage(res, 'Failed to load messages'));
    } catch (e) {
      developer.log('Get messages error: $e', name: 'ApiService');
      return [];
    }
  }

  static Future<bool> sendMessage({
    required String conversationId,
    required String text,
    Map<String, dynamic>? location,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/api/chat/conversations/$conversationId/messages'),
        headers: await _headers(),
        body: jsonEncode({
          'text': text,
          'image_url': null,
          if (location != null) 'location': location,
        }),
      );
      return res.statusCode == 201 || res.statusCode == 200;
    } catch (e) {
      developer.log('Send message error: $e', name: 'ApiService');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> sendImageMessage({
    required String conversationId,
    required XFile file,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_base/api/chat/conversations/$conversationId/messages/image'),
      );
      final authHeaders = await _headers();
      authHeaders.remove('Content-Type');
      request.headers.addAll(authHeaders);

      final bytes = await file.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
      ));

      final streamed = await _client.send(request);
      final res = await http.Response.fromStream(streamed);
      
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      developer.log('Send image message failed: ${res.body}', name: 'ApiService');
      return null;
    } catch (e) {
      developer.log('Send image message error: $e', name: 'ApiService');
      return null;
    }
  }

  // ========== NOTIFICATIONS ==========

  static Future<List<Map<String, dynamic>>> getNotifications(
      {int limit = 50}) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/notifications/?limit=$limit'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
      }
      throw Exception(_errorMessage(res, 'Failed to load notifications'));
    } catch (e) {
      developer.log('Get notifications error: $e', name: 'ApiService');
      return [];
    }
  }

  /// Number of unread notifications. Returns 0 on any failure (the badge simply
  /// hides rather than surfacing an error for a non-critical indicator).
  static Future<int> getUnreadNotificationCount() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/notifications/unread-count'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return _numericId(data['unread_count'] ?? 0);
      }
      return 0;
    } catch (e) {
      developer.log('Get unread notification count error: $e',
          name: 'ApiService');
      return 0;
    }
  }

  /// Alias for [getUnreadNotificationCount] matching the notification-center
  /// naming contract.
  static Future<int> getUnreadCount() => getUnreadNotificationCount();

  /// Total unread chat messages across all conversations. Returns 0 on any
  /// failure (the badge simply hides for a non-critical indicator).
  static Future<int> getChatUnreadCount() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/chat/unread-count'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return _numericId(data['unread_count'] ?? 0);
      }
      return 0;
    } catch (e) {
      developer.log('Get chat unread count error: $e', name: 'ApiService');
      return 0;
    }
  }

  /// Mark a single notification as read.
  static Future<bool> markNotificationRead(String id) async {
    try {
      final res = await http.patch(
        Uri.parse('$_base/api/notifications/$id/read'),
        headers: await _headers(),
      );
      return res.statusCode == 200;
    } catch (e) {
      developer.log('Mark notification read error: $e', name: 'ApiService');
      return false;
    }
  }

  /// Permanently delete a single notification.
  static Future<bool> deleteNotification(String id) async {
    try {
      final res = await http.delete(
        Uri.parse('$_base/api/notifications/$id'),
        headers: await _headers(),
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      developer.log('Delete notification error: $e', name: 'ApiService');
      return false;
    }
  }

  static Future<bool> markAllNotificationsRead() async {
    try {
      final res = await http.patch(
        Uri.parse('$_base/api/notifications/mark-all-read'),
        headers: await _headers(),
      );
      return res.statusCode == 200;
    } catch (e) {
      developer.log('Mark all notifications read error: $e',
          name: 'ApiService');
      return false;
    }
  }

  // ========== FAVORITES ==========

  /// Full saved services + taskers with their enriched target objects.
  static Future<List<FavoriteItem>> getFavorites() async {
    final res = await _client.get(
      Uri.parse('$_base/api/favorites'),
      headers: await _headers(),
    );
    if (res.statusCode == 401) throw const UnauthorizedException();
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res, 'Failed to load favorites'));
    }
    final List data = jsonDecode(res.body);
    final items = <FavoriteItem>[];
    for (final row in data.whereType<Map>()) {
      final json = Map<String, dynamic>.from(row);
      final type = json['target_type']?.toString() ?? '';
      final target = json['target'];
      if (target is! Map) continue;
      final targetMap = Map<String, dynamic>.from(target);
      items.add(
        FavoriteItem(
          id: json['id'].toString(),
          targetType: type,
          targetId: json['target_id'].toString(),
          service: type == 'service' ? _serviceFromJson(targetMap) : null,
          tasker: type == 'tasker' ? _userFromJson(targetMap) : null,
          taskerVerified: targetMap['is_verified'] == true,
        ),
      );
    }
    return items;
  }

  /// Favorited target ids grouped by type, for rendering heart-fill state.
  /// Ids are returned as strings to match the backend's string primary keys.
  static Future<Map<String, Set<String>>> getFavoriteIds() async {
    try {
      final res = await _client.get(
        Uri.parse('$_base/api/favorites/ids'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final data = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
        Set<String> parse(String key) => (data[key] as List? ?? const [])
            .map((e) => e.toString())
            .toSet();
        return {'service': parse('service'), 'tasker': parse('tasker')};
      }
      throw Exception(_errorMessage(res, 'Failed to load favorites'));
    } catch (e) {
      developer.log('Get favorite ids error: $e', name: 'ApiService');
      return {'service': <String>{}, 'tasker': <String>{}};
    }
  }

  /// Save a favorite (idempotent server-side). [targetType] ∈ {service, tasker}.
  static Future<void> addFavorite(String targetType, String targetId) async {
    final res = await _client.post(
      Uri.parse('$_base/api/favorites'),
      headers: await _headers(),
      body: jsonEncode({'target_type': targetType, 'target_id': targetId}),
    );
    if (res.statusCode == 401) throw const UnauthorizedException();
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(_errorMessage(res, 'Could not save favorite'));
    }
  }

  static Future<void> removeFavorite(String targetType, String targetId) async {
    final res = await _client.delete(
      Uri.parse('$_base/api/favorites/$targetType/$targetId'),
      headers: await _headers(),
    );
    if (res.statusCode == 401) throw const UnauthorizedException();
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception(_errorMessage(res, 'Could not remove favorite'));
    }
  }

  // ========== ADDRESS BOOK ==========

  static Future<List<AddressModel>> getAddresses() async {
    final res = await _client.get(
      Uri.parse('$_base/api/addresses'),
      headers: await _headers(),
    );
    if (res.statusCode == 401) throw const UnauthorizedException();
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res, 'Failed to load addresses'));
    }
    final List data = jsonDecode(res.body);
    return data
        .whereType<Map>()
        .map((row) => AddressModel.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Map<String, dynamic> _addressPayload({
    required String label,
    required String address,
    String? landmark,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) =>
      {
        'label': label,
        'address': address,
        if (landmark != null && landmark.trim().isNotEmpty)
          'landmark': landmark.trim(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (isDefault != null) 'is_default': isDefault,
      };

  static Future<AddressModel> createAddress({
    required String label,
    required String address,
    String? landmark,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    final res = await _client.post(
      Uri.parse('$_base/api/addresses'),
      headers: await _headers(),
      body: jsonEncode(_addressPayload(
        label: label,
        address: address,
        landmark: landmark,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      )),
    );
    if (res.statusCode == 401) throw const UnauthorizedException();
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(_errorMessage(res, 'Could not save address'));
    }
    return AddressModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(res.body) as Map));
  }

  static Future<AddressModel> updateAddress({
    required String id,
    required String label,
    required String address,
    String? landmark,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    final res = await _client.patch(
      Uri.parse('$_base/api/addresses/$id'),
      headers: await _headers(),
      body: jsonEncode(_addressPayload(
        label: label,
        address: address,
        landmark: landmark,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      )),
    );
    if (res.statusCode == 401) throw const UnauthorizedException();
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res, 'Could not update address'));
    }
    return AddressModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(res.body) as Map));
  }

  static Future<void> setDefaultAddress(String id) async {
    final res = await _client.post(
      Uri.parse('$_base/api/addresses/$id/default'),
      headers: await _headers(),
    );
    if (res.statusCode == 401) throw const UnauthorizedException();
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res, 'Could not set default address'));
    }
  }

  static Future<void> deleteAddress(String id) async {
    final res = await _client.delete(
      Uri.parse('$_base/api/addresses/$id'),
      headers: await _headers(),
    );
    if (res.statusCode == 401) throw const UnauthorizedException();
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception(_errorMessage(res, 'Could not delete address'));
    }
  }

  // ========== PUBLIC TASKER PROFILE ==========

  static Future<List<Map<String, dynamic>>> getUserPortfolio(
      String userId) async {
    try {
      final res = await _client.get(
        Uri.parse('$_base/api/users/$userId/portfolio'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
      }
      throw Exception(_errorMessage(res, 'Failed to load portfolio'));
    } catch (e) {
      developer.log('Get portfolio error: $e', name: 'ApiService');
      return [];
    }
  }

  /// Weekly availability: {days:[{day_of_week, start_minute, end_minute,
  /// is_available}]}. Returns the raw day rows.
  static Future<List<Map<String, dynamic>>> getUserAvailability(
      String userId) async {
    try {
      final res = await _client.get(
        Uri.parse('$_base/api/users/$userId/availability'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final days = data is Map ? data['days'] : null;
        if (days is List) {
          return days
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList();
        }
        return [];
      }
      throw Exception(_errorMessage(res, 'Failed to load availability'));
    } catch (e) {
      developer.log('Get availability error: $e', name: 'ApiService');
      return [];
    }
  }
}

class Session {
  // The bearer token is a secret and lives in the OS keystore/keychain via
  // flutter_secure_storage — never in plaintext SharedPreferences. The cached
  // user profile (non-secret, re-fetchable) stays in SharedPreferences.
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _tokenKey = 'token';
  static const _userKey = 'user';

  static Future<void> setAuth(String token, Map<String, dynamic> user) async {
    if (token.isEmpty) {
      throw Exception('Login response did not include an access token');
    }
    await _secure.write(key: _tokenKey, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  static Future<void> setUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  static Future<void> clear() async {
    await _secure.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    // Clean up any token left in prefs by a pre-secure-storage build.
    await prefs.remove(_tokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<String?> getToken() async {
    final secure = await _secure.read(key: _tokenKey);
    if (secure != null && secure.isNotEmpty) return secure;
    // One-time migration: move a token written by an older build into secure
    // storage, then drop the plaintext copy.
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_tokenKey);
    if (legacy != null && legacy.isNotEmpty) {
      await _secure.write(key: _tokenKey, value: legacy);
      await prefs.remove(_tokenKey);
      return legacy;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr != null) {
      return jsonDecode(userStr);
    }
    return null;
  }
}

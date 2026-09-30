import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';

/// Thrown when the backend rejects the token (HTTP 401), used to trigger logout.
class UnauthorizedException implements Exception {
  const UnauthorizedException([this.message = 'Session expired']);
  final String message;
  @override
  String toString() => message;
}

/// Thrown when an action is blocked because the tasker has not completed KYC
/// verification (HTTP 403 on apply). Callers should route the user to the
/// verification screen rather than showing a generic error.
class VerificationRequiredException implements Exception {
  const VerificationRequiredException(
      [this.message =
          'Please complete verification before applying to tasks.']);
  final String message;
  @override
  String toString() => message;
}

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

/// Parse a server-generated timestamp (e.g. created_at). The backend emits
/// naive UTC (`datetime.utcnow()`) with no timezone in the string, which
/// `DateTime.parse` would otherwise read as device-local time — making
/// "posted x ago" wrong by the device's UTC offset. So a timezone-less string
/// is interpreted as UTC and converted to local.
DateTime _parseServerUtc(String? raw, {DateTime? fallback}) {
  final s = raw?.trim() ?? '';
  if (s.isEmpty) return fallback ?? DateTime.now();
  final dt = DateTime.tryParse(s);
  if (dt == null) return fallback ?? DateTime.now();
  if (dt.isUtc) return dt.toLocal();
  return DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second,
          dt.millisecond, dt.microsecond)
      .toLocal();
}

class ApiService {
  static final _client = http.Client();
  static String get baseUrl => _base;

  /// Resolve a possibly-relative media path (e.g. "/uploads/avatars/x.png")
  /// returned by the backend into an absolute URL the app can load.
  static String? resolveMediaUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '$_base$url';
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

  static String _errorMessage(http.Response res, String fallback) {
    try {
      final data = jsonDecode(res.body);
      if (data is Map && data['detail'] != null) {
        final detail = data['detail'];
        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first['loc'] is List) {
            final loc = first['loc'] as List;
            if (loc.contains('email')) {
              return 'Please enter a valid email address without spaces';
            }
          }
          if (first is Map && first['msg'] != null) {
            return first['msg'].toString();
          }
        }
        return data['detail'].toString();
      }
    } catch (_) {}
    return fallback;
  }

  /// Decode a response body that is expected to be a JSON object.
  ///
  /// Returns an empty map when the body is empty, malformed, or a non-object
  /// (e.g. the server returned a bare list or an error page on a 200). This
  /// keeps a shape surprise from throwing `_TypeError`/`FormatException` and
  /// crashing the caller.
  static Map<String, dynamic> _decodeMap(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    try {
      final data = jsonDecode(body);
      return data is Map<String, dynamic>
          ? data
          : (data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{});
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// Decode a response body that is expected to be a JSON array of objects.
  /// Returns an empty list on empty/malformed/non-list bodies.
  static List<Map<String, dynamic>> _decodeList(String body) {
    if (body.trim().isEmpty) return const [];
    try {
      final data = jsonDecode(body);
      if (data is List) {
        return data.whereType<Map>().map(Map<String, dynamic>.from).toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  static Future<Map<String, String>> _headers() async {
    final token = await Session.getToken() ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ========== AUTH ==========

  static Future<Map<String, dynamic>> sendOtpForTasker(String phone) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/api/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': indiaPhoneNumber(phone),
          'user_type': 'tasker',
        }),
      );

      if (res.statusCode == 200) {
        return _decodeMap(res.body);
      }
      throw Exception(_errorMessage(res, 'Failed to send OTP'));
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(
      String phone, String otp) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': indiaPhoneNumber(phone),
          'otp': otp,
        }),
      );

      if (res.statusCode == 200) {
        final data = _decodeMap(res.body);
        final user = data['user'];
        final role = user is Map ? user['role']?.toString() : null;
        if (role != 'tasker') {
          throw Exception('Please use a tasker account to sign in');
        }
        return data;
      }
      throw Exception(_errorMessage(res, 'Invalid OTP'));
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<Map<String, dynamic>> login(
      String identifier, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': identifier, 'password': password}),
      );

      if (res.statusCode == 200) {
        final data = _decodeMap(res.body);
        final user = data['user'] as Map<String, dynamic>? ?? {};
        if (user['role'] != 'tasker') {
          throw Exception('Please use a tasker account to sign in');
        }
        return data;
      }
      throw Exception(_errorMessage(res, 'Invalid credentials'));
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Revoke the current bearer token on the server (best-effort).
  static Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$_base/api/auth/logout'),
        headers: await _headers(),
      );
    } catch (e) {
      developer.log('Logout error: $e', name: 'ApiService');
    }
  }

  // ========== TASKS ==========

  static int _numericId(dynamic val) {
    if (val is int) return val;
    if (val is String) return val.hashCode.abs();
    return 0;
  }

  static double _doubleValue(dynamic val) {
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0;
    return 0;
  }

  static UserModel _userFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const UserModel(id: 0, name: 'Unknown', email: '');
    }
    return UserModel(
      id: _numericId(json['id']),
      remoteId: json['id']?.toString(),
      name: json['name']?.toString() ?? 'User',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      avatarUrl: resolveMediaUrl(json['avatar_url']?.toString()),
      rating: _doubleValue(json['rating'] ?? 5.0),
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      coins: (json['coins'] as num?)?.toInt() ?? 0,
    );
  }

  static ApplicationModel _applicationFromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: _numericId(json['id']),
      remoteId: json['id']?.toString(),
      task: json['task'] is Map ? _taskFromJson(Map<String, dynamic>.from(json['task'] as Map)) : null,
      applicant: _userFromJson(json['applicant'] is Map ? Map<String, dynamic>.from(json['applicant'] as Map) : const {}),
      bidAmount: _doubleValue(json['bid_amount']),
      coverLetter: json['cover_letter']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      appliedAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static TaskModel _taskFromJson(Map<String, dynamic> json) {
    final categoryName = json['category']?.toString() ?? 'other';
    final statusName = json['status']?.toString() ?? 'open';
    final assigned = json['assigned_to'] is Map
        ? Map<String, dynamic>.from(json['assigned_to'] as Map)
        : null;
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
      status: TaskStatus.values.firstWhere(
        (s) => s.name == statusName,
        orElse: () => TaskStatus.open,
      ),
      budget: _doubleValue(json['budget']),
      deadline: DateTime.tryParse(json['deadline']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 1)),
      createdAt: _parseServerUtc(json['created_at']?.toString()),
      postedBy: _userFromJson(
        json['posted_by'] is Map
            ? Map<String, dynamic>.from(json['posted_by'] as Map)
            : null,
      ),
      assignedTo: assigned == null ? null : _userFromJson(assigned),
      applicantsCount: (json['applicants_count'] as num?)?.toInt() ?? 0,
      completionOtp: json['completion_otp']?.toString(),
      images: (json['images'] as List?)
              ?.map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
    );
  }

  /// Fetch all open tasks (for browse screen)
  static Future<List<ApplicationModel>> getMyApplications() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/applications/my-applications'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((json) => _applicationFromJson(json)).toList();
      }
      throw Exception(_errorMessage(res, 'Failed to load applications'));
    } catch (e) {
      developer.log('Get my applications error: $e', name: 'ApiService');
      return [];
    }
  }

  static Future<List<TaskModel>> getTasks({
    String? status,
    String? category,
    double? radiusKm,
  }) async {
    try {
      final params = <String, String>{};
      if (status != null) params['status'] = status;
      if (category != null) params['category'] = category;
      // Search radius (km). Clamped 5–50 to match the app's slider and the
      // backend's 50 km hard cap.
      if (radiusKm != null) {
        params['radius_km'] = radiusKm.clamp(5, 50).toStringAsFixed(0);
      }

      // Attach the tasker's last known location so the backend limits the feed
      // to nearby tasks (default 40km, nearest-first) and keeps un-geotagged
      // tasks visible. With no saved location the feed falls back to recent.
      try {
        final prefs = await SharedPreferences.getInstance();
        final lat = prefs.getDouble('detected_location_lat');
        final lng = prefs.getDouble('detected_location_lng');
        if (lat != null && lng != null) {
          params['latitude'] = lat.toString();
          params['longitude'] = lng.toString();
        }
      } catch (_) {
        // Location is best-effort; browse without it if prefs are unavailable.
      }

      final uri = Uri.parse('$_base/api/tasker/tasks').replace(
        queryParameters: params.isEmpty ? null : params,
      );
      final res = await http.get(uri, headers: await _headers());

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data
            .map((json) => _taskFromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception(_errorMessage(res, 'Failed to load tasks'));
    } catch (e) {
      developer.log('Get tasks error: $e', name: 'ApiService');
      return [];
    }
  }

  /// Whether the tasker is paused from browsing over unsettled cash dues.
  /// Returns {blocked, dues, pending_cash_jobs, limit}. Never throws.
  static Future<Map<String, dynamic>> getDuesStatus() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/tasker/dues-status'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) return _decodeMap(res.body);
    } catch (_) {
      // Best-effort: on error, don't block the tasker.
    }
    return {'blocked': false, 'dues': 0, 'pending_cash_jobs': 0, 'limit': 2};
  }

  /// Settle the tasker's outstanding cash dues (clears the balance + counter,
  /// unpausing browsing). Returns null on success, or an error message.
  static Future<String?> settleDues() async {
    try {
      final res = await http.post(
        Uri.parse('$_base/api/tasker/settle-dues'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return null;
      return _errorMessage(res, 'Could not settle dues');
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Fetch a single task by ID
  static Future<TaskModel?> getTaskById(String taskId) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/tasks/$taskId'),
        headers: await _headers(),
      );

      if (res.statusCode == 200) {
        return _taskFromJson(_decodeMap(res.body));
      }
      throw Exception(_errorMessage(res, 'Task not found'));
    } catch (e) {
      developer.log('Get task by ID error: $e', name: 'ApiService');
      return null;
    }
  }

  /// Apply for a task (as a tasker)
  static Future<Map<String, dynamic>> applyForTask({
    required String taskId,
    required double bidAmount,
    required String coverLetter,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/api/applications'),
        headers: await _headers(),
        body: jsonEncode({
          'task_id': taskId,
          'bid_amount': bidAmount,
          'cover_letter': coverLetter,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return _decodeMap(res.body);
      }
      // KYC gate: the backend blocks unverified taskers from applying. Surface a
      // dedicated exception so the UI can route to verification instead of a
      // generic error snackbar.
      if (res.statusCode == 403) {
        throw VerificationRequiredException(_errorMessage(
            res, 'Please complete verification before applying to tasks.'));
      }
      throw Exception(_errorMessage(res, 'Failed to submit application'));
    } catch (e) {
      developer.log('Apply for task error: $e', name: 'ApiService');
      if (e is VerificationRequiredException) rethrow;
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// The tasker's own profile including `is_verified` (KYC status).
  static Future<Map<String, dynamic>> getTaskerProfile() async {
    final res = await http.get(
      Uri.parse('$_base/api/tasker/profile'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return _decodeMap(res.body);
    }
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to load profile'));
  }

  /// Whether the current tasker is KYC-verified. Reads the live tasker profile
  /// and falls back to the cached user. Never throws (returns false on error).
  static Future<bool> isVerified() async {
    try {
      final profile = await getTaskerProfile();
      if (profile.containsKey('is_verified')) {
        return profile['is_verified'] == true;
      }
    } catch (_) {
      // Fall through to the cached user below.
    }
    try {
      final user = await Session.getUser();
      return user?['is_verified'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> withdrawApplication(String id) async {
    try {
      final res = await http.delete(
        Uri.parse('$_base/api/tasker/applications/$id'),
        headers: await _headers(),
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        return;
      }
      throw Exception(_errorMessage(res, 'Failed to withdraw application'));
    } catch (e) {
      developer.log('Withdraw application error: $e', name: 'ApiService');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Complete a task with the customer's OTP. [paymentMethod] defaults to cash:
  /// the tasker collected the gross amount in cash and the platform commission
  /// is deducted from their wallet. Returns `{message, earning:{gross,
  /// commission, net, method}}`.
  static Future<Map<String, dynamic>> completeTask(
    String taskId,
    String otp, {
    String paymentMethod = 'cash',
  }) async {
    try {
      final res = await http.patch(
        Uri.parse(
            '$_base/api/tasker/tasks/$taskId/complete?completion_otp=$otp&payment_method=$paymentMethod'),
        headers: await _headers(),
      );

      if (res.statusCode == 200) {
        return _decodeMap(res.body);
      }
      throw Exception(_errorMessage(res, 'Failed to complete task'));
    } catch (e) {
      developer.log('Complete task error: $e', name: 'ApiService');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Signal that the tasker is heading to an assigned job. Notifies the
  /// customer and powers their live "on the way" tracking UI.
  /// Returns {message, on_the_way_at}.
  static Future<Map<String, dynamic>> markOnTheWay(String taskId) async {
    final res = await _client.patch(
      Uri.parse('$_base/api/tasker/tasks/$taskId/on-the-way'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return _decodeMap(res.body);
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to mark on the way'));
  }

  /// Push the tasker's current location so the backend (and the customer's
  /// tracking view) has a fresh position. Best-effort: never throws.
  static Future<void> updateLocation(double lat, double lng) async {
    try {
      await _client.post(
        Uri.parse('$_base/api/tasker/location'),
        headers: await _headers(),
        body: jsonEncode({'latitude': lat, 'longitude': lng}),
      );
    } catch (e) {
      developer.log('Update location error: $e', name: 'ApiService');
    }
  }

  /// Back out of an assigned job. Reopens the task for other taskers and
  /// counts against the tasker's reliability. Returns {message, task_id}.
  static Future<Map<String, dynamic>> cancelAssignedTask(
    String taskId, {
    String? reason,
  }) async {
    final res = await _client.patch(
      Uri.parse('$_base/api/tasker/tasks/$taskId/cancel'),
      headers: await _headers(),
      body: jsonEncode({
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      }),
    );
    if (res.statusCode == 200) return _decodeMap(res.body);
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to cancel job'));
  }

  /// Leave a review about the customer after a completed task.
  static Future<Map<String, dynamic>> submitReview(
    String taskId,
    String reviewedUserId,
    int rating,
    String comment,
  ) async {
    final res = await _client.post(
      Uri.parse('$_base/api/reviews/'),
      headers: await _headers(),
      body: jsonEncode({
        'task_id': taskId,
        'reviewed_user_id': reviewedUserId,
        'rating': rating,
        if (comment.trim().isNotEmpty) 'comment': comment.trim(),
      }),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return _decodeMap(res.body);
    }
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to submit review'));
  }

  // ========== BOOKINGS (admin-assigned service jobs) ==========

  /// Bookings assigned to this tasker by an admin. Each row includes
  /// {id, booking_id, service, scheduled_at, address, status, total_amount,
  ///  customer:{...}}.
  static Future<List<Map<String, dynamic>>> getTaskerBookings() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/tasker/bookings'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        return _decodeList(res.body);
      }
      if (res.statusCode == 401) throw const UnauthorizedException();
      throw Exception(_errorMessage(res, 'Failed to load bookings'));
    } catch (e) {
      developer.log('Get bookings error: $e', name: 'ApiService');
      if (e is UnauthorizedException) rethrow;
      return [];
    }
  }

  /// Mark a confirmed booking complete using the customer's completion OTP.
  static Future<Map<String, dynamic>> completeBooking(
      String bookingId, String otp) async {
    final res = await http.patch(
      Uri.parse(
          '$_base/api/tasker/bookings/$bookingId/complete?completion_otp=$otp'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return _decodeMap(res.body);
    }
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to complete booking'));
  }

  // ========== USER PROFILE ==========

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/users/me'),
        headers: await _headers(),
      );

      if (res.statusCode == 200) {
        return _decodeMap(res.body);
      }
      if (res.statusCode == 401) {
        throw const UnauthorizedException();
      }
      throw Exception(_errorMessage(res, 'Failed to load profile'));
    } catch (e) {
      developer.log('Get profile error: $e', name: 'ApiService');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateMe({
    required String name,
    required String phone,
    String? email,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name,
        'phone': phone.replaceAll(RegExp(r'\D'), '').startsWith('91') ? '+$phone' : '+91$phone',
        if (email != null) 'email': email.trim().toLowerCase(),
      };
      final res = await http.patch(
        Uri.parse('$_base/api/users/me'),
        headers: await _headers(),
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        final user = _decodeMap(res.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(user));
        return user;
      }
      throw Exception(_errorMessage(res, 'Failed to update profile'));
    } catch (e) {
      developer.log('Update profile error: $e', name: 'ApiService');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Patch arbitrary profile fields (e.g. {'bio': '...'}) on /api/users/me.
  static Future<Map<String, dynamic>> patchProfile(
      Map<String, dynamic> fields) async {
    final res = await http.patch(
      Uri.parse('$_base/api/users/me'),
      headers: await _headers(),
      body: jsonEncode(fields),
    );
    if (res.statusCode == 200) {
      return _decodeMap(res.body);
    }
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to update profile'));
  }

  /// Persist the tasker's online/availability status.
  static Future<void> setOnline(bool isOnline) async {
    final res = await http.patch(
      Uri.parse('$_base/api/users/me/online?is_online=$isOnline'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return;
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to update availability'));
  }

  /// Upload a new avatar image. Returns the (relative) avatar_url on success.
  static Future<String> uploadAvatar(XFile file) async {
    final token = await Session.getToken() ?? '';
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/api/users/me/avatar'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    final bytes = await file.readAsBytes();
    request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: file.name));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = _decodeMap(res.body);
      return data['avatar_url']?.toString() ?? '';
    }
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to upload photo'));
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
        return _decodeMap(res.body);
      }
      return null;
    } catch (e) {
      developer.log('Create conversation error: $e', name: 'ApiService');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final res = await _client.get(
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

  /// Total unread chat messages across all conversations (for the dashboard
  /// messages badge). Never throws (returns 0 on error/offline).
  static Future<int> getChatUnreadCount() async {
    try {
      final res = await _client.get(
        Uri.parse('$_base/api/chat/unread-count'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return (data['unread_count'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      developer.log('Get chat unread count error: $e', name: 'ApiService');
    }
    return 0;
  }

  static Future<List<Map<String, dynamic>>> getMessages(
      String conversationId) async {
    try {
      final res = await _client.get(
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
      final res = await _client.post(
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
      final token = await Session.getToken() ?? '';
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_base/api/chat/conversations/$conversationId/messages/image'),
      );
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });
      final bytes = await file.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
      ));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return _decodeMap(response.body);
      }
      return null;
    } catch (e) {
      developer.log('Send image message error: $e', name: 'ApiService');
      return null;
    }
  }

  // ========== WALLET ==========

  static Future<double> getWalletBalance() async {
    final res = await http.get(
      Uri.parse('$_base/api/wallet/balance'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = _decodeMap(res.body);
      return (data['balance'] as num?)?.toDouble() ?? 0.0;
    }
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to load balance'));
  }

  static Future<List<Map<String, dynamic>>> getWalletTransactions({int limit = 50}) async {
    final res = await http.get(
      Uri.parse('$_base/api/wallet/transactions?limit=$limit'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return _decodeList(res.body);
    }
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to load transactions'));
  }

  /// Returns {earnings: [...], total_earnings, this_month_earnings, completed_tasks}.
  static Future<Map<String, dynamic>> getEarnings() async {
    final res = await http.get(
      Uri.parse('$_base/api/wallet/earnings'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return _decodeMap(res.body);
    }
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to load earnings'));
  }

  static Future<Map<String, dynamic>> requestWithdrawal({
    required double amount,
    required String method,
    String? details,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/api/wallet/withdraw'),
      headers: await _headers(),
      body: jsonEncode({
        'amount': amount,
        'method': method,
        'details': {'account': details ?? method},
      }),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return _decodeMap(res.body);
    }
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Withdrawal failed'));
  }

  // ========== REVIEWS ==========

  /// Reviews written ABOUT the given user (each row includes a `reviewer` object).
  static Future<List<Map<String, dynamic>>> getUserReviews(String userId, {int limit = 20}) async {
    final res = await http.get(
      Uri.parse('$_base/api/reviews/user/$userId?limit=$limit'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return _decodeList(res.body);
    }
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to load reviews'));
  }

  // ========== NOTIFICATIONS ==========

  static Future<List<Map<String, dynamic>>> getNotifications({int limit = 50}) async {
    final res = await http.get(
      Uri.parse('$_base/api/notifications/?limit=$limit'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return _decodeList(res.body);
    }
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to load notifications'));
  }

  /// Number of unread notifications (for the dashboard bell badge).
  static Future<int> getUnreadCount() async {
    final res = await http.get(
      Uri.parse('$_base/api/notifications/unread-count'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = _decodeMap(res.body);
      return (data['unread_count'] as num?)?.toInt() ?? 0;
    }
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to load unread count'));
  }

  /// Mark a single notification as read.
  static Future<void> markNotificationRead(String id) async {
    final res = await http.patch(
      Uri.parse('$_base/api/notifications/$id/read'),
      headers: await _headers(),
    );
    if (res.statusCode == 200 || res.statusCode == 204) return;
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to update notification'));
  }

  /// Delete a single notification.
  static Future<void> deleteNotification(String id) async {
    final res = await http.delete(
      Uri.parse('$_base/api/notifications/$id'),
      headers: await _headers(),
    );
    if (res.statusCode == 200 || res.statusCode == 204) return;
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to delete notification'));
  }

  // ========== KYC ==========

  /// Upload a verification document (aadhaar | pan | address | selfie).
  static Future<Map<String, dynamic>> uploadKycDocument({
    required String docType,
    required XFile file,
  }) async {
    final token = await Session.getToken() ?? '';
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/api/kyc/documents'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['doc_type'] = docType;
    final bytes = await file.readAsBytes();
    request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: file.name));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return _decodeMap(res.body);
    }
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Upload failed'));
  }

  /// My KYC documents with review status/reason.
  static Future<List<Map<String, dynamic>>> getKycDocuments() async {
    final res = await http.get(
      Uri.parse('$_base/api/kyc/documents'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return _decodeList(res.body);
    }
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to load documents'));
  }

  // ========== SUPPORT ==========

  static Future<void> createSupportTicket({
    required String subject,
    required String message,
  }) async {
    final res = await _client.post(
      Uri.parse('$_base/api/support/tickets'),
      headers: await _headers(),
      body: jsonEncode({'subject': subject, 'message': message}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      if (res.statusCode == 401) throw const UnauthorizedException();
      throw Exception(_errorMessage(res, 'Could not send message'));
    }
  }

  static Future<List<Map<String, dynamic>>> getMyTickets() async {
    final res = await http.get(
      Uri.parse('$_base/api/support/tickets'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return _decodeList(res.body);
    }
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to load tickets'));
  }

  static Future<void> markAllNotificationsRead() async {
    final res = await http.patch(
      Uri.parse('$_base/api/notifications/mark-all-read'),
      headers: await _headers(),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      if (res.statusCode == 401) throw const UnauthorizedException();
      throw Exception(_errorMessage(res, 'Failed to update notifications'));
    }
  }

  // ========== AVAILABILITY (weekly working hours) ==========

  /// Weekly availability schedule. Always returns 7 rows, one per weekday,
  /// each {day_of_week (0=Mon..6=Sun), start_minute, end_minute, is_available}.
  static Future<List<Map<String, dynamic>>> getAvailability() async {
    final res = await http.get(
      Uri.parse('$_base/api/tasker/availability'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = _decodeMap(res.body);
      return ((data['days'] as List?) ?? const [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to load availability'));
  }

  /// Persist the weekly schedule. [days] is a list of
  /// {day_of_week, start_minute, end_minute, is_available}. A subset of days
  /// may be sent (the backend upserts by day). Returns the updated 7 rows.
  static Future<List<Map<String, dynamic>>> updateAvailability(
      List<Map<String, dynamic>> days) async {
    final res = await http.put(
      Uri.parse('$_base/api/tasker/availability'),
      headers: await _headers(),
      body: jsonEncode({'days': days}),
    );
    if (res.statusCode == 200) {
      final data = _decodeMap(res.body);
      return ((data['days'] as List?) ?? const [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to save availability'));
  }

  // ========== PORTFOLIO (work gallery) ==========

  /// The tasker's portfolio images, each {id, image_url, caption, created_at}.
  static Future<List<Map<String, dynamic>>> getPortfolio() async {
    final res = await http.get(
      Uri.parse('$_base/api/tasker/portfolio'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return _decodeList(res.body)
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to load portfolio'));
  }

  /// Upload a portfolio image (multipart `file`); [caption] is sent as a query
  /// param. Returns the created item. Throws when the 12-item cap is reached.
  static Future<Map<String, dynamic>> addPortfolioItem(
    XFile file, {
    String? caption,
  }) async {
    final token = await Session.getToken() ?? '';
    final uri = Uri.parse('$_base/api/tasker/portfolio').replace(
      queryParameters: (caption != null && caption.trim().isNotEmpty)
          ? {'caption': caption.trim()}
          : null,
    );
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    final bytes = await file.readAsBytes();
    request.files
        .add(http.MultipartFile.fromBytes('file', bytes, filename: file.name));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return _decodeMap(res.body);
    }
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to add photo'));
  }

  /// Remove a portfolio image by id.
  static Future<void> deletePortfolioItem(String id) async {
    final res = await http.delete(
      Uri.parse('$_base/api/tasker/portfolio/$id'),
      headers: await _headers(),
    );
    if (res.statusCode == 200 || res.statusCode == 204) return;
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to remove photo'));
  }

  // ========== SAFETY (trust & safety: report / block) ==========

  /// Report a user for a safety/quality issue. [reason] is one of the backend
  /// codes (inappropriate_behaviour, no_show, safety_concern, fraud_or_scam,
  /// poor_quality, spam, other).
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
    if (res.statusCode == 200 || res.statusCode == 201) return;
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to submit report'));
  }

  /// Block a user so they can no longer be matched/messaged.
  static Future<void> blockUser(String blockedId) async {
    final res = await _client.post(
      Uri.parse('$_base/api/safety/block'),
      headers: await _headers(),
      body: jsonEncode({'blocked_id': blockedId}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) return;
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to block user'));
  }

  /// Remove a block.
  static Future<void> unblockUser(String blockedId) async {
    final res = await http.delete(
      Uri.parse('$_base/api/safety/block/$blockedId'),
      headers: await _headers(),
    );
    if (res.statusCode == 200 || res.statusCode == 204) return;
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to unblock user'));
  }

  /// The users this tasker has blocked. Each row includes the blocked user.
  static Future<List<Map<String, dynamic>>> getBlocks() async {
    final res = await http.get(
      Uri.parse('$_base/api/safety/blocks'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return _decodeList(res.body);
    }
    if (res.statusCode == 401) throw const UnauthorizedException();
    throw Exception(_errorMessage(res, 'Failed to load blocked users'));
  }
}

class Session {
  // The bearer token (a secret) lives in the OS keystore/keychain via
  // flutter_secure_storage. The cached user profile stays in SharedPreferences.
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

  static Future<void> clear() async {
    await _secure.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey); // drop any legacy plaintext token
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<String?> getToken() async {
    final secure = await _secure.read(key: _tokenKey);
    if (secure != null && secure.isNotEmpty) return secure;
    // One-time migration from an older plaintext build.
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
    if (userStr == null || userStr.trim().isEmpty) return null;
    // Never let a corrupt/truncated cached blob crash startup — decode defensively.
    try {
      final data = jsonDecode(userStr);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
    } catch (_) {}
    return null;
  }
}

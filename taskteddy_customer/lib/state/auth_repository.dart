import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';

class StoredAuthSession {
  const StoredAuthSession({
    required this.token,
    required this.user,
  });

  final String? token;
  final Map<String, dynamic>? user;

  bool get isLoggedIn => token != null && token!.trim().isNotEmpty;
}

class AuthRepository {
  const AuthRepository();

  Future<StoredAuthSession> readStoredSession() async {
    final token = await Session.getToken();
    final user = await Session.getUser();
    return StoredAuthSession(
      token: token,
      user: user == null ? null : Map<String, dynamic>.from(user),
    );
  }

  Future<void> persistSession({
    required String token,
    required Map<String, dynamic> user,
  }) {
    return Session.setAuth(token, user);
  }

  Future<void> persistUser(Map<String, dynamic> user) {
    return Session.setUser(user);
  }

  Future<void> clearSession() async {
    // Best-effort server-side revocation of the current token before wiping it
    // locally. Uses the still-present token; network failures are ignored.
    await ApiService.logout();
    await Session.clear();
  }

  Future<Map<String, dynamic>> fetchCurrentUser() {
    return ApiService.getMe();
  }

  Future<Map<String, dynamic>> requestPhoneOtp(String phone) {
    return ApiService.sendOtp(phone);
  }

  Future<Map<String, dynamic>> verifyPhoneOtp({
    required String phone,
    required String otp,
  }) {
    return ApiService.verifyOtp(phone, otp);
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => const AuthRepository(),
  name: 'authRepositoryProvider',
);

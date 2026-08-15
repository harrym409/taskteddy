import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import 'auth_repository.dart';

class AuthSnapshot {
  const AuthSnapshot({
    this.token,
    this.user,
    this.lastUserSyncAt,
    this.isRefreshingUser = false,
  });

  final String? token;
  final Map<String, dynamic>? user;
  final DateTime? lastUserSyncAt;
  final bool isRefreshingUser;

  bool get isLoggedIn => token != null && token!.trim().isNotEmpty;

  String? get email {
    final value = user?['email']?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  String get displayName {
    final value = user?['name']?.toString().trim();
    if (value == null || value.isEmpty) return 'Customer';
    return value;
  }

  AuthSnapshot copyWith({
    String? token,
    Map<String, dynamic>? user,
    DateTime? lastUserSyncAt,
    bool? isRefreshingUser,
  }) {
    return AuthSnapshot(
      token: token ?? this.token,
      user: user ?? this.user,
      lastUserSyncAt: lastUserSyncAt ?? this.lastUserSyncAt,
      isRefreshingUser: isRefreshingUser ?? this.isRefreshingUser,
    );
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSnapshot>(
  AuthController.new,
  name: 'authControllerProvider',
);

final authSnapshotProvider = Provider<AuthSnapshot?>((ref) {
  return ref.watch(authControllerProvider).valueOrNull;
}, name: 'authSnapshotProvider');

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authSnapshotProvider.select(
    (snapshot) => snapshot?.isLoggedIn ?? false,
  ));
}, name: 'isLoggedInProvider');

final currentUserProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(authSnapshotProvider.select((snapshot) => snapshot?.user));
}, name: 'currentUserProvider');

final currentUserNameProvider = Provider<String>((ref) {
  return ref.watch(authSnapshotProvider.select(
    (snapshot) => snapshot?.displayName ?? 'Customer',
  ));
}, name: 'currentUserNameProvider');

class AuthController extends AsyncNotifier<AuthSnapshot> {
  static const _minimumUserRefreshInterval = Duration(seconds: 20);

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<AuthSnapshot> _readStoredSession() async {
    final stored = await _repository.readStoredSession();
    return AuthSnapshot(
      token: stored.token,
      user: stored.user,
    );
  }

  @override
  FutureOr<AuthSnapshot> build() async {
    return _readStoredSession();
  }

  Future<void> reloadFromStorage() async {
    state = await AsyncValue.guard(_readStoredSession);
  }

  Future<void> setSession(String token, Map<String, dynamic> user) async {
    await _repository.persistSession(token: token, user: user);
    state = AsyncData(
      AuthSnapshot(
        token: token,
        user: Map<String, dynamic>.from(user),
        lastUserSyncAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateCachedUser(Map<String, dynamic> user) async {
    await _repository.persistUser(user);
    final current = state.valueOrNull;
    final token =
        current?.token ?? (await _repository.readStoredSession()).token;
    state = AsyncData(
      AuthSnapshot(
        token: token,
        user: Map<String, dynamic>.from(user),
        lastUserSyncAt: DateTime.now(),
      ),
    );
  }

  Future<Map<String, dynamic>?> refreshUser({bool force = false}) async {
    final previous = state.valueOrNull ?? await _readStoredSession();
    if (!previous.isLoggedIn) {
      state = AsyncData(previous);
      return previous.user;
    }

    final refreshedAt = previous.lastUserSyncAt;
    final hasFreshCache = previous.user != null &&
        refreshedAt != null &&
        DateTime.now().difference(refreshedAt) < _minimumUserRefreshInterval;
    if (!force && hasFreshCache) {
      return previous.user;
    }

    state = AsyncData(previous.copyWith(isRefreshingUser: true));

    try {
      final fresh = await _repository.fetchCurrentUser();
      await _repository.persistUser(fresh);
      state = AsyncData(
        previous.copyWith(
          user: Map<String, dynamic>.from(fresh),
          lastUserSyncAt: DateTime.now(),
          isRefreshingUser: false,
        ),
      );
      return fresh;
    } on UnauthorizedException {
      // Token is no longer valid — clear the session so the app returns to login.
      await logout();
      return null;
    } catch (error, stackTrace) {
      state = AsyncData(previous.copyWith(isRefreshingUser: false));
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> logout() async {
    await _repository.clearSession();
    state = const AsyncData(AuthSnapshot());
  }
}

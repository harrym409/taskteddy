import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    if (kReleaseMode) return;
    developer.log(
      'Provider added: ${provider.name ?? provider.runtimeType}',
      name: 'Riverpod',
    );
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (kReleaseMode) return;
    if (identical(previousValue, newValue)) return;
    developer.log(
      'Provider updated: ${provider.name ?? provider.runtimeType}',
      name: 'Riverpod',
    );
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    if (kReleaseMode) return;
    developer.log(
      'Provider disposed: ${provider.name ?? provider.runtimeType}',
      name: 'Riverpod',
    );
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    developer.log(
      'Provider failed: ${provider.name ?? provider.runtimeType}',
      name: 'Riverpod',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

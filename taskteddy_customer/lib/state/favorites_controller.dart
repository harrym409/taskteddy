import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';

/// Set of favorited *service* ids (as strings, matching the backend keys).
/// Backs the heart-fill state on service cards and the service detail screen,
/// keeping every card in sync through a single source of truth.
final favoriteServiceIdsProvider =
    AsyncNotifierProvider<FavoriteServiceIdsNotifier, Set<String>>(
  FavoriteServiceIdsNotifier.new,
  name: 'favoriteServiceIdsProvider',
);

class FavoriteServiceIdsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final ids = await ApiService.getFavoriteIds();
    return ids['service'] ?? <String>{};
  }

  bool isFavorite(String serviceId) =>
      state.valueOrNull?.contains(serviceId) ?? false;

  /// Optimistically flip the heart, then persist. Reverts on failure and
  /// rethrows so the caller can surface an error.
  Future<void> toggle(String serviceId) async {
    final current = {...(state.valueOrNull ?? <String>{})};
    final wasFavorite = current.contains(serviceId);
    if (wasFavorite) {
      current.remove(serviceId);
    } else {
      current.add(serviceId);
    }
    state = AsyncData(current);

    try {
      if (wasFavorite) {
        await ApiService.removeFavorite('service', serviceId);
      } else {
        await ApiService.addFavorite('service', serviceId);
      }
    } catch (e) {
      final reverted = {...(state.valueOrNull ?? <String>{})};
      if (wasFavorite) {
        reverted.add(serviceId);
      } else {
        reverted.remove(serviceId);
      }
      state = AsyncData(reverted);
      rethrow;
    }
  }

  /// Force a refresh from the server (e.g. after the Favorites screen mutates
  /// favorites through the full list endpoint).
  Future<void> refresh() async {
    final ids = await ApiService.getFavoriteIds();
    state = AsyncData(ids['service'] ?? <String>{});
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/profile_repo.dart';

// ✅ Add this import so we can invalidate deals providers after city update
import '../../deals/logic/deals_controller.dart';

// ✅ NEW: push service import (for city-change token update)
import '../../../core/notifications/push_service.dart';

final profileRepoProvider = Provider<ProfileRepo>((ref) => ProfileRepo());

/// ✅ Change: FutureProvider<ProfileModel?> (nullable)
/// If user is logged out, return null instead of throwing.
final myProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return null;

  try {
    return await ref.read(profileRepoProvider).getMyProfile();
  } catch (_) {
    // If anything auth-related happens during transition, fail gracefully
    final stillSession = Supabase.instance.client.auth.currentSession;
    if (stillSession == null) return null;
    rethrow;
  }
});

final profileUpdateControllerProvider =
    StateNotifierProvider<ProfileUpdateController, AsyncValue<void>>(
  (ref) => ProfileUpdateController(ref.read(profileRepoProvider), ref),
);

class ProfileUpdateController extends StateNotifier<AsyncValue<void>> {
  ProfileUpdateController(this._repo, this._ref) : super(const AsyncData(null));

  final ProfileRepo _repo;
  final Ref _ref;

  Future<void> update({
    required String phone,
    required String whatsapp,
    required String address,
    required String city,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _repo.updateMyProfile(
        phone: phone,
        whatsapp: whatsapp,
        address: address,
        city: city,
      );

      // ✅ Refresh profile UI
      _ref.invalidate(myProfileProvider);

      // ✅ VERY IMPORTANT:
      // City is used for deals filter. Supabase read is cached in providers.
      // So invalidate these to force fresh city + refetch deals.
      _ref.invalidate(currentUserCityProvider);
      _ref.invalidate(dealsControllerProvider);

      // ✅ NEW: update push token row city (same user row update allowed by RLS)
      await PushService.instance.upsertToken(city: city);
    });
  }
}

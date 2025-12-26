import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/profile_model.dart';

import '../data/profile_repo.dart';

// ✅ Add this import so we can invalidate deals providers after city update
import '../../deals/logic/deals_controller.dart';

final profileRepoProvider = Provider<ProfileRepo>((ref) => ProfileRepo());

final myProfileProvider = FutureProvider<ProfileModel>((ref) async {
  return ref.read(profileRepoProvider).getMyProfile();
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
    });
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_repo.dart';

final profileRepoProvider = Provider<ProfileRepo>((ref) => ProfileRepo());

final myProfileProvider = FutureProvider((ref) async {
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
      _ref.invalidate(myProfileProvider);
    });
  }
}

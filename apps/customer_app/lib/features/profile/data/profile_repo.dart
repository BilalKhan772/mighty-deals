import 'package:shared_supabase/shared_supabase.dart';
import 'package:shared_models/profile_model.dart';

class ProfileRepo {
  final _repo = ProfileRepoSB(); // shared_supabase repo wrapper

  Future<ProfileModel> getMyProfile() => _repo.getMyProfile();

  Future<void> updateMyProfile({
    required String phone,
    required String whatsapp,
    required String address,
    required String city,
  }) =>
      _repo.updateMyProfile(
        phone: phone,
        whatsapp: whatsapp,
        address: address,
        city: city,
      );
}

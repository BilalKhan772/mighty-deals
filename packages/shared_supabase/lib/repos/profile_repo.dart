import 'package:shared_models/profile_model.dart';
import '../supabase_client.dart';
import '../supabase_tables.dart';

class ProfileRepoSB {
  Future<ProfileModel> getMyProfile() async {
    final uid = SB.auth.currentUser?.id;
    if (uid == null) throw Exception('Not logged in');

    final data = await SB.client
        .from(Tables.profiles)
        .select()
        .eq('id', uid)
        .single();

    return ProfileModel.fromMap(data);
  }

  Future<void> updateMyProfile({
    required String phone,
    required String whatsapp,
    required String address,
    required String city,
  }) async {
    final uid = SB.auth.currentUser?.id;
    if (uid == null) throw Exception('Not logged in');

    final isComplete = phone.trim().isNotEmpty &&
        whatsapp.trim().isNotEmpty &&
        address.trim().isNotEmpty &&
        city.trim().isNotEmpty;

    await SB.client.from(Tables.profiles).update({
      'phone': phone.trim(),
      'whatsapp': whatsapp.trim(),
      'address': address.trim(),
      'city': city.trim(),
      'is_profile_complete': isComplete,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', uid);
  }
}

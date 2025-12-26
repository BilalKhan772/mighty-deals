// packages/shared_supabase/lib/repos/profile_repo.dart
import 'package:shared_models/profile_model.dart';
import '../supabase_client.dart';
import '../supabase_tables.dart';

class ProfileRepoSB {
  Future<ProfileModel> getMyProfile() async {
    final uid = SB.auth.currentUser?.id;
    if (uid == null) throw Exception('Not logged in');

    final row = await SB.client
        .from(Tables.profiles)
        .select('*')
        .eq('id', uid)
        .single();

    // ✅ Your model uses fromMap (not fromJson)
    return ProfileModel.fromMap(row);
  }

  Future<void> updateMyProfile({
    required String phone,
    required String whatsapp,
    required String address,
    required String city,
  }) async {
    final uid = SB.auth.currentUser?.id;
    if (uid == null) throw Exception('Not logged in');

    final p = phone.trim();
    final w = whatsapp.trim();
    final a = address.trim();
    final c = city.trim();

    final isComplete = p.isNotEmpty && w.isNotEmpty && a.isNotEmpty && c.isNotEmpty;

    await SB.client.from(Tables.profiles).update({
      'phone': p,
      'whatsapp': w,
      'address': a,
      'city': c,
      'is_profile_complete': isComplete,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', uid);
  }
}

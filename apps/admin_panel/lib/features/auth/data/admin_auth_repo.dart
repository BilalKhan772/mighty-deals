import 'package:supabase_flutter/supabase_flutter.dart';

class AdminAuthRepo {
  final SupabaseClient _sb;
  AdminAuthRepo(this._sb);

  Future<void> loginAdmin({
    required String email,
    required String password,
  }) async {
    final res = await _sb.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = res.user;
    if (user == null) throw Exception('Login failed');

    // ✅ check role from profiles
    final profile = await _sb
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    final role = (profile?['role'] ?? '').toString();

    if (role != 'admin') {
      // logout if not admin
      await _sb.auth.signOut();
      throw Exception('Access denied: not an admin');
    }
  }

  Future<void> logout() async {
    await _sb.auth.signOut();
  }
}

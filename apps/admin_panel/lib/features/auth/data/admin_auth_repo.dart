import 'package:supabase_flutter/supabase_flutter.dart';

class AdminAuthRepo {
  final SupabaseClient _sb;
  AdminAuthRepo(this._sb);

  bool _isUuid(String s) {
    final re = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return re.hasMatch(s.trim());
  }

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

    // ✅ quick sanity (Supabase user.id should be UUID)
    if (!_isUuid(user.id)) {
      await _sb.auth.signOut();
      throw Exception('Invalid session: user.id is not UUID. Please login again.');
    }

    // ✅ check role from profiles
    final profile = await _sb.from('profiles').select('role').eq('id', user.id).maybeSingle();
    final role = (profile?['role'] ?? '').toString();

    if (role != 'admin') {
      // logout if not admin
      await _sb.auth.signOut();
      throw Exception('Access denied: not an admin');
    }

    // ✅ ensure we have fresh session token (helps on web sometimes)
    try {
      await _sb.auth.refreshSession();
    } catch (_) {
      // ignore; not fatal
    }
  }

  Future<void> logout() async {
    await _sb.auth.signOut();
  }
}

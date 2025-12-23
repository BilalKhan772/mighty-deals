import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';

class AuthRepoSB {
  String _sanitizeEmail(String email) {
    // remove quotes + trim + lowerCase + remove hidden newlines/spaces
    return email
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .trim()
        .toLowerCase();
  }

  Future<void> signUp({required String email, required String password}) async {
    final cleanEmail = _sanitizeEmail(email);

    final res = await SB.auth.signUp(email: cleanEmail, password: password);

    if (res.user == null) {
      throw AuthException('Signup failed (no user returned)');
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final cleanEmail = _sanitizeEmail(email);
    await SB.auth.signInWithPassword(email: cleanEmail, password: password);
  }

  Future<void> signOut() => SB.auth.signOut();

  Stream<AuthState> get onAuthStateChange => SB.auth.onAuthStateChange;
}

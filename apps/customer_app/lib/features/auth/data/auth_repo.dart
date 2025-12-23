import 'package:shared_supabase/shared_supabase.dart';

class AuthRepo {
  final _sb = AuthRepoSB();

  Future<void> signup({required String email, required String password}) =>
      _sb.signUp(email: email, password: password);

  Future<void> login({required String email, required String password}) =>
      _sb.signIn(email: email, password: password);

  Future<void> logout() => _sb.signOut();
}

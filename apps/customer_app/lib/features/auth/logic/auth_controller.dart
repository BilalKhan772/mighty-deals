import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/auth_error_mapper.dart';
import '../data/auth_repo.dart';

final authRepoProvider = Provider<AuthRepo>((ref) => AuthRepo());

final authControllerProvider =
    AutoDisposeAsyncNotifierProvider<AuthController, void>(AuthController.new);

class AuthController extends AutoDisposeAsyncNotifier<void> {
  late final AuthRepo _repo = ref.read(authRepoProvider);

  String _sanitizeEmail(String email) {
    return email
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .trim()
        .toLowerCase();
  }

  @override
  Future<void> build() async {
    // nothing to load initially
  }

  Future<bool> signup(String email, String password) async {
    state = const AsyncLoading();
    try {
      final e = _sanitizeEmail(email);
      await _repo.signup(email: e, password: password);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      final msg = AuthErrorMapper.friendlyMessage(e);
      state = AsyncError(Exception(msg), st);
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final e = _sanitizeEmail(email);
      await _repo.login(email: e, password: password);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      final msg = AuthErrorMapper.friendlyMessage(e);
      state = AsyncError(Exception(msg), st);
      return false;
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await _repo.logout();
      state = const AsyncData(null);
    } catch (e, st) {
      final msg = AuthErrorMapper.friendlyMessage(e);
      state = AsyncError(Exception(msg), st);
    }
  }
}

import 'package:flutter/foundation.dart';
import '../data/admin_auth_repo.dart';

class AdminAuthController extends ChangeNotifier {
  final AdminAuthRepo _repo;
  AdminAuthController(this._repo);

  bool loading = false;
  String error = '';

  bool _disposed = false;

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> login(String email, String password) async {
    email = email.trim();
    error = '';
    _safeNotify();

    if (email.isEmpty || password.isEmpty) {
      error = 'Email and password required';
      _safeNotify();
      return;
    }

    loading = true;
    _safeNotify();

    try {
      await _repo.loginAdmin(email: email, password: password);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      _safeNotify();
    }
  }
}

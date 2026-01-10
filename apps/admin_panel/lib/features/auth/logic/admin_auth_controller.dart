import 'package:flutter/foundation.dart';
import '../data/admin_auth_repo.dart';

class AdminAuthController extends ChangeNotifier {
  final AdminAuthRepo _repo;
  AdminAuthController(this._repo);

  bool loading = false;
  String error = '';

  Future<void> login(String email, String password) async {
    email = email.trim();
    error = '';
    notifyListeners();

    if (email.isEmpty || password.isEmpty) {
      error = 'Email and password required';
      notifyListeners();
      return;
    }

    loading = true;
    notifyListeners();

    try {
      await _repo.loginAdmin(email: email, password: password);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

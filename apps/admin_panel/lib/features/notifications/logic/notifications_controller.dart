import 'package:flutter/foundation.dart';
import '../data/notifications_repo.dart';

class NotificationsController extends ChangeNotifier {
  final NotificationsRepo _repo;

  NotificationsController(this._repo);

  bool loading = false;
  String message = '';

  void _setLoading(bool v) {
    loading = v;
    notifyListeners();
  }

  void _setMessage(String v) {
    message = v;
    notifyListeners();
  }

  Future<void> sendPublished(String spinId) async {
    spinId = spinId.trim();
    if (spinId.isEmpty) {
      _setMessage('❌ Spin ID required');
      return;
    }

    _setLoading(true);
    _setMessage('');

    try {
      final res = await _repo.sendSpinPublished(spinId);
      _setMessage('✅ Published notification sent:\n$res');
    } catch (e) {
      _setMessage('❌ ERROR: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendWinner(String spinId) async {
    spinId = spinId.trim();
    if (spinId.isEmpty) {
      _setMessage('❌ Spin ID required');
      return;
    }

    _setLoading(true);
    _setMessage('');

    try {
      final res = await _repo.sendSpinWinner(spinId);
      _setMessage('✅ Winner notification sent:\n$res');
    } catch (e) {
      _setMessage('❌ ERROR: $e');
    } finally {
      _setLoading(false);
    }
  }
}

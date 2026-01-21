import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkStatus {
  NetworkStatus._();
  static final NetworkStatus I = NetworkStatus._();

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onChanged => _controller.stream;

  bool _hasInternet = true;
  bool get hasInternet => _hasInternet;

  StreamSubscription? _sub;
  bool _started = false;

  static const String _host = 'vvjxpvegqmlemebzmesy.supabase.co';

  Future<bool> _check() async {
    try {
      final res = await InternetAddress.lookup(_host)
          .timeout(const Duration(seconds: 3));
      return res.isNotEmpty && res.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;

    // ✅ initial check
    _hasInternet = await _check();
    _safeAdd(_hasInternet);

    // ✅ listen to connectivity changes then confirm with real lookup
    _sub = Connectivity().onConnectivityChanged.listen((_) async {
      final ok = await _check();
      if (ok != _hasInternet) {
        _hasInternet = ok;
        _safeAdd(ok);
      }
    });
  }

  void _safeAdd(bool v) {
    if (_controller.isClosed) return;
    _controller.add(v);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    if (!_controller.isClosed) {
      await _controller.close();
    }
    _started = false;
  }
}

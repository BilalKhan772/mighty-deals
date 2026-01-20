import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class NetworkStatus {
  NetworkStatus._();
  static final NetworkStatus I = NetworkStatus._();

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onChanged => _controller.stream;

  bool _hasInternet = true;
  bool get hasInternet => _hasInternet;

  StreamSubscription? _sub;
  bool _started = false;

  Future<void> start() async {
    if (_started) return; // ✅ prevent double start
    _started = true;

    // ✅ initial check (real internet reachability)
    _hasInternet = await InternetConnection().hasInternetAccess;
    _safeAdd(_hasInternet);

    // ✅ listen to connectivity changes, then confirm real internet
    _sub = Connectivity().onConnectivityChanged.listen((_) async {
      final ok = await InternetConnection().hasInternetAccess;
      if (ok != _hasInternet) {
        _hasInternet = ok;
        _safeAdd(ok);
      }
    });
  }

  void _safeAdd(bool v) {
    if (_controller.isClosed) return; // ✅ avoid "Bad state: Stream has been closed"
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

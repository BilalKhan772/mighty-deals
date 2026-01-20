import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'config/env.dart';
import 'firebase_options.dart';
import 'core/notifications/push_service.dart';
import 'core/network/network_status.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Lock orientation globally (portrait only)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // ✅ Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Supabase
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  // ✅ Network watcher (safe: never crash app if something fails)
  try {
    await NetworkStatus.I.start();
  } catch (_) {
    // ignore - app should still run even if network watcher fails
  }

  // ✅ Push init (safe)
  try {
    await PushService.instance.init();
  } catch (_) {
    // ignore - app should still run even if push init fails
  }

  runApp(await builder());
}

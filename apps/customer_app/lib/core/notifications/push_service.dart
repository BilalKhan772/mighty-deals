import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushService {
  PushService._();
  static final instance = PushService._();

  final _fcm = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _tokenRefreshSub;
  String? _lastCity; // keep latest city for refresh updates

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _local.initialize(initSettings);

    // Permission (Android 13+ & iOS)
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Foreground => show local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
      final title = msg.notification?.title ?? 'Mighty Deals';
      final body = msg.notification?.body ?? '';

      const androidDetails = AndroidNotificationDetails(
        'mighty_channel',
        'Mighty Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _local.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      // keep empty for now (no routing changes)
    });
  }

  Future<void> upsertToken({required String city}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print('⚠️ PushService: no user, skip upsertToken');
      return;
    }

    _lastCity = city;

    final token = await _fcm.getToken();
    if (token == null) {
      print('⚠️ PushService: FCM token is null');
      return;
    }

    final platform = Platform.isAndroid
        ? 'android'
        : Platform.isIOS
            ? 'ios'
            : 'unknown';

    try {
      // ✅ This will insert OR update (if same user owns the row)
      await Supabase.instance.client.from('push_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'platform': platform,
        'city': city,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'token');

      print('✅ Push token upserted. token=${token.substring(0, 12)}..., city=$city');

      // ✅ ensure we only attach one listener
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _fcm.onTokenRefresh.listen((newToken) async {
        final u = Supabase.instance.client.auth.currentUser;
        if (u == null) return;

        final c = _lastCity ?? city;

        try {
          await Supabase.instance.client.from('push_tokens').upsert({
            'user_id': u.id,
            'token': newToken,
            'platform': platform,
            'city': c,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'token');

          print('🔁 Token refreshed + upserted. city=$c');
        } catch (e) {
          print('❌ Token refresh upsert failed: $e');
        }
      });
    } catch (e) {
      // IMPORTANT: this is where RLS conflict will show (old user row can't be updated)
      print('❌ Push token upsert failed (likely RLS/token conflict): $e');
    }
  }

  /// ✅ Call this BEFORE signOut so RLS allows delete.
  Future<void> removeMyTokens() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client
          .from('push_tokens')
          .delete()
          .eq('user_id', user.id);

      print('🧹 Deleted push tokens for user=${user.id}');
    } catch (e) {
      print('❌ removeMyTokens failed: $e');
    }
  }
}

import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class SB {
  SB._();
  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;

  /// Debug: JWT payload "sub" (user id) check karne ke liye
  static String? debugJwtSub() {
    final token = auth.currentSession?.accessToken;
    if (token == null || token.split('.').length < 2) return null;

    try {
      final payload = token.split('.')[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = json.decode(decoded) as Map<String, dynamic>;
      return map['sub']?.toString();
    } catch (_) {
      return null;
    }
  }
}

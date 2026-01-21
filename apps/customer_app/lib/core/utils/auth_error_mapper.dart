import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthErrorMapper {
  static String friendlyMessage(Object error) {
    final s = error.toString().toLowerCase();

    // ✅ 1) Real network/offline indicators (strong + reliable)
    // Covers: no internet, DNS fail, handshake, timeouts, etc.
    if (error is SocketException ||
        error is TimeoutException ||
        s.contains('socketexception') ||
        s.contains('failed host lookup') ||
        s.contains('no address associated with hostname') ||
        s.contains('network is unreachable') ||
        s.contains('connection refused') ||
        s.contains('connection reset') ||
        s.contains('handshakeexception') ||
        s.contains('timed out') ||
        s.contains('clientexception')) {
      return "You're offline. Please connect to internet and try again.";
    }

    // ✅ 2) Supabase Auth exceptions (your existing logic kept)
    if (error is AuthException) {
      final msg = (error.message).toLowerCase();

      // Common validations
      if (msg.contains('missing email') ||
          msg.contains('missing email or phone') ||
          (msg.contains('email') && msg.contains('missing'))) {
        return 'Please enter your email.';
      }

      if (msg.contains('missing password') ||
          (msg.contains('password') && msg.contains('missing'))) {
        return 'Please enter your password.';
      }

      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid_credentials')) {
        return 'Email or password is incorrect.';
      }

      if (msg.contains('user already registered') ||
          msg.contains('user_already_exists') ||
          msg.contains('already exists')) {
        return 'This email is already registered. Please log in.';
      }

      if (msg.contains('password') && msg.contains('at least 6')) {
        return 'Password must be at least 6 characters.';
      }

      if (msg.contains('anonymous sign-ins are disabled') ||
          msg.contains('anonymous_provider_disabled')) {
        return 'Anonymous sign-in is disabled. Please use email and password.';
      }

      // fallback
      return _clean(error.message);
    }

    // ✅ 3) Generic / unknown
    return 'Something went wrong. Please try again.';
  }

  static String _clean(String raw) {
    return raw.trim();
  }
}

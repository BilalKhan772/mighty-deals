import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthErrorMapper {
  static String friendlyMessage(Object error) {
    // ✅ 1) OFFLINE / DNS / NO INTERNET (your exact case)
    // Sometimes these come as SocketException / ClientException text
    final s = error.toString();

    if (error is SocketException ||
        s.contains('SocketException') ||
        s.contains('Failed host lookup') ||
        s.contains('No address associated with hostname') ||
        s.contains('ClientException')) {
      return "You're offline. Please connect to internet.";
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

    // ✅ 3) Generic / unknown (same)
    return 'Something went wrong. Please try again.';
  }

  static String _clean(String raw) {
    return raw.trim();
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthErrorMapper {
  static String friendlyMessage(Object error) {
    // Supabase Auth exceptions
    if (error is AuthException) {
      final msg = (error.message).toLowerCase();

      // Common validations
      if (msg.contains('missing email') ||
          msg.contains('missing email or phone') ||
          msg.contains('email') && msg.contains('missing')) {
        return 'Please enter your email.';
      }

      if (msg.contains('missing password') || (msg.contains('password') && msg.contains('missing'))) {
        return 'Please enter your password.';
      }

      if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
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

    // Generic / unknown
    return 'Something went wrong. Please try again.';
  }

  static String _clean(String raw) {
    // Keep it short and user-friendly (no statusCode/code)
    // Example raw: "Invalid login credentials"
    // or "Password should be at least 6 characters"
    return raw.trim();
  }
}

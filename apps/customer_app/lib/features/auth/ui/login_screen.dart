// apps/customer_app/lib/features/auth/ui/login_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/utils/support_launcher.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/network/network_status.dart';
import '../../profile/logic/profile_controller.dart';
import '../../wallet/logic/wallet_controller.dart';
import '../logic/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();

  bool _hidePass = true;

  // ✅ Inline errors
  String? _emailError;
  String? _passError;
  String? _formError; // server/auth error banner

  @override
  void initState() {
    super.initState();
    email.addListener(_clearEmailError);
    pass.addListener(_clearPassError);
  }

  void _clearEmailError() {
    if (_emailError != null) setState(() => _emailError = null);
    if (_formError != null) setState(() => _formError = null);
  }

  void _clearPassError() {
    if (_passError != null) setState(() => _passError = null);
    if (_formError != null) setState(() => _formError = null);
  }

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  void _invalidateAfterAuth() {
    // ✅ IMPORTANT: clear cached data when session changes
    ref.invalidate(myProfileProvider);
    ref.invalidate(myWalletProvider);
    ref.invalidate(myLedgerProvider);
  }

  bool _isValidEmail(String v) {
    final value = v.trim();
    // lightweight validation (no heavy regex)
    return value.contains('@') && value.contains('.') && value.length >= 6;
  }

  bool _validate() {
    final e = email.text.trim();
    final p = pass.text;

    String? eErr;
    String? pErr;

    if (e.isEmpty) {
      eErr = 'Email is required.';
    } else if (!_isValidEmail(e)) {
      eErr = 'Please enter a valid email.';
    }

    if (p.isEmpty) {
      pErr = 'Password is required.';
    } else if (p.length < 6) {
      pErr = 'Password must be at least 6 characters.';
    }

    setState(() {
      _emailError = eErr;
      _passError = pErr;
    });

    return eErr == null && pErr == null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    // ✅ Receive mapped, clean errors from controller and show inline banner
    ref.listen(authControllerProvider, (_, next) {
      next.whenOrNull(
        error: (e, __) {
          final msg = e.toString().replaceFirst('Exception: ', '').trim();
          if (!mounted) return;
          setState(() => _formError = msg.isEmpty ? 'Something went wrong.' : msg);
        },
      );
    });

    return Scaffold(
      body: Container(
        color: const Color(0xFF070B14),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'Login',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // ✅ Inline form/server error banner
                          if (_formError != null) ...[
                            _InlineBanner(message: _formError!),
                            const SizedBox(height: 12),
                          ],

                          _AuthField(
                            controller: email,
                            hint: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.mail_outline_rounded,
                            obscureText: false,
                            suffix: null,
                            errorText: _emailError,
                          ),
                          const SizedBox(height: 12),
                          _AuthField(
                            controller: pass,
                            hint: 'Password',
                            keyboardType: TextInputType.text,
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _hidePass,
                            suffix: IconButton(
                              onPressed: () =>
                                  setState(() => _hidePass = !_hidePass),
                              icon: Icon(
                                _hidePass
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                            errorText: _passError,
                          ),
                          const SizedBox(height: 18),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: AppButton(
                              text: 'Log In',
                              isLoading: state.isLoading,
                              onPressed: state.isLoading
                                  ? null
                                  : () async {
                                      FocusScope.of(context).unfocus();

                                      // ✅ validate first
                                      if (!_validate()) return;

                                      // ✅ HYBRID OFFLINE GUARD:
                                      // Show friendly warning, but DO NOT block login.
                                      if (!NetworkStatus.I.hasInternet) {
                                        setState(() => _formError =
                                            "You're offline. Trying to connect...");
                                      } else {
                                        // clear old banner if any
                                        if (_formError != null) {
                                          setState(() => _formError = null);
                                        }
                                      }

                                      final ok = await ref
                                          .read(authControllerProvider.notifier)
                                          .login(email.text.trim(), pass.text);

                                      if (!context.mounted) return;

                                      if (ok) {
                                        _invalidateAfterAuth();
                                        context.go(RouteNames.home);
                                      }
                                    },
                            ),
                          ),

                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 13.5,
                              ),
                            ),
                          ),

                          // ✅ Support/help
                          const SizedBox(height: 10),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'Need help logging in?',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.65),
                                    fontSize: 13.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextButton.icon(
                                  onPressed: () => SupportLauncher.open(context),
                                  icon: const Icon(Icons.support_agent_rounded,
                                      size: 18),
                                  label: const Text('Open Support'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF06B6D4),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 6),
                          Center(
                            child: GestureDetector(
                              onTap: () => context.go(RouteNames.signup),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.70),
                                    fontSize: 13.5,
                                  ),
                                  children: const [
                                    TextSpan(text: "Don't have an account? "),
                                    TextSpan(
                                      text: "Sign Up",
                                      style: TextStyle(
                                        color: Color(0xFF06B6D4),
                                        decoration: TextDecoration.underline,
                                        decorationThickness: 1.3,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineBanner extends StatelessWidget {
  final String message;
  const _InlineBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color.fromRGBO(255, 86, 86, 0.12),
        border: Border.all(
            color: const Color.fromRGBO(255, 86, 86, 0.35), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: Color(0xFFFF6B6B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13.2,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    const radius = 24.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(10, 18, 32, 0.45),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: const Color.fromRGBO(255, 255, 255, 0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffix;
  final String? errorText;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    required this.prefixIcon,
    required this.obscureText,
    required this.suffix,
    required this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = const Color(0xFF06B6D4).withOpacity(0.65);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 54,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            autocorrect: false,
            obscureText: obscureText,
            style: const TextStyle(fontSize: 14.8),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(prefixIcon, color: iconColor),
              suffixIcon: suffix == null
                  ? null
                  : IconTheme(
                      data: IconThemeData(color: iconColor),
                      child: suffix!,
                    ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

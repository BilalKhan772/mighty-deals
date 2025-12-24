// apps/customer_app/lib/features/auth/ui/signup_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/widgets/app_button.dart';
import '../logic/auth_controller.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();
  final confirm = TextEditingController();

  bool _hidePass = true;
  bool _hideConfirm = true;

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (_, next) {
      next.whenOrNull(
        error: (e, __) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        ),
      );
    });

    return Scaffold(
      body: Container(
        color: const Color(0xFF070B14), // solid deep navy
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
                      'Sign Up',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Create your account to get started.',
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
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 14),

                          _AuthField(
                            controller: email,
                            hint: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.mail_outline_rounded,
                            obscureText: false,
                            suffix: null,
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
                          ),
                          const SizedBox(height: 12),

                          _AuthField(
                            controller: confirm,
                            hint: 'Confirm Password',
                            keyboardType: TextInputType.text,
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _hideConfirm,
                            suffix: IconButton(
                              onPressed: () =>
                                  setState(() => _hideConfirm = !_hideConfirm),
                              icon: Icon(
                                _hideConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),

                          // ✅ Give the button room for its shadow/glow
                          const SizedBox(height: 18),

                          // ✅ Inset the button slightly so glow doesn't touch card border
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: AppButton(
                              text: 'Sign Up',
                              isLoading: state.isLoading,
                              onPressed: state.isLoading
                                  ? null
                                  : () async {
                                      if (pass.text != confirm.text) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Passwords do not match',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final ok = await ref
                                          .read(authControllerProvider.notifier)
                                          .signup(
                                            email.text.trim(),
                                            pass.text,
                                          );

                                      if (!context.mounted) return;
                                      if (ok) context.go(RouteNames.home);
                                    },
                            ),
                          ),

                          // ✅ Small bottom space to keep everything inside card nicely
                          const SizedBox(height: 12),

                          Center(
                            child: GestureDetector(
                              onTap: () => context.go(RouteNames.login),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.70),
                                    fontSize: 13.5,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: 'Already have an account? ',
                                    ),
                                    TextSpan(
                                      text: 'Login',
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
          // ✅ Slightly more bottom padding so button shadow doesn't feel outside
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

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    required this.prefixIcon,
    required this.obscureText,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = const Color(0xFF06B6D4).withOpacity(0.65);

    return SizedBox(
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
    );
  }
}

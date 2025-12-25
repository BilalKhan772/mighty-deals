// apps/customer_app/lib/features/profile/ui/profile_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/routing/route_names.dart';
import '../../wallet/logic/wallet_controller.dart';
import '../logic/profile_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _invalidateAll(WidgetRef ref) {
    ref.invalidate(myProfileProvider);
    ref.invalidate(myWalletProvider);
    ref.invalidate(myLedgerProvider);
  }

  Color w(double a) => Colors.white.withAlpha((a * 255).round());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    // ✅ You said: "thora sa nichay" (slightly down)
    // Just adjust this spacing. Keep it small.
    const double topGap = 14; // (was 6) -> now slightly lower, more balanced

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 18,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
            onPressed: () => ref.invalidate(myProfileProvider),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF070B14),
              Color(0xFF040814),
            ],
          ),
        ),
        child: profileAsync.when(
          loading: () => const SafeArea(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SafeArea(
            child: Center(
              child: Text(
                e.toString(),
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (p) {
            return SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: topGap), // ✅ slightly down

                        _ProfileField(label: 'Unique ID', value: p.uniqueCode),
                        const SizedBox(height: 12),

                        _ProfileField(
                          label: 'Phone',
                          value: (p.phone == null || p.phone!.isEmpty)
                              ? '-'
                              : p.phone!,
                        ),
                        const SizedBox(height: 12),

                        _ProfileField(
                          label: 'WhatsApp',
                          value: (p.whatsapp == null || p.whatsapp!.isEmpty)
                              ? '-'
                              : p.whatsapp!,
                        ),
                        const SizedBox(height: 12),

                        _ProfileField(
                          label: 'Address',
                          value: (p.address == null || p.address!.isEmpty)
                              ? '-'
                              : p.address!,
                        ),
                        const SizedBox(height: 12),

                        _ProfileField(
                          label: 'City',
                          value: (p.city == null || p.city!.isEmpty)
                              ? '-'
                              : p.city!,
                        ),
                        const SizedBox(height: 18),

                        SizedBox(
                          height: 56,
                          child: _PrimaryButton(
                            text: 'Edit',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Edit abhi disabled hai (Profile updates RPC se honge).',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () async {
                              await Supabase.instance.client.auth.signOut();
                              _invalidateAll(ref);

                              if (!context.mounted) return;
                              context.go(RouteNames.login);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: w(0.20)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Logout',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return _GlassTile(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassTile extends StatelessWidget {
  final Widget child;
  const _GlassTile({required this.child});

  @override
  Widget build(BuildContext context) {
    const radius = 18.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(10, 18, 32, 0.45),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: const Color.fromRGBO(255, 255, 255, 0.10),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const _PrimaryButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF06B6D4),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

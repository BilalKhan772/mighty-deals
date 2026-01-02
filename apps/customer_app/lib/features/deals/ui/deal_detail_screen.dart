import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logic/deals_controller.dart';

// ✅ Same constants as DealsScreen
const Color kDeepNavy = Color(0xFF01203D);
const Color kAccentA = Color(0xFF10B7C7);
const Color kAccentB = Color(0xFF0B7C9D);

// ✅ safe string helper (fix warnings)
String _s(dynamic v) => (v == null) ? '' : v.toString();

class DealDetailScreen extends ConsumerWidget {
  final String dealId;
  const DealDetailScreen({super.key, required this.dealId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsStateAsync = ref.watch(dealsControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050A14),
      body: Stack(
        children: [
          const _PlainDarkBackground(),
          SafeArea(
            child: dealsStateAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  e.toString(),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              data: (state) {
                final d = state.items.firstWhere(
                  (x) => x.id == dealId,
                  orElse: () => throw Exception('Deal not found'),
                );

                final r = d.restaurant ?? {};
                final restaurantName = _s(r['name']).trim().isEmpty
                    ? 'Restaurant'
                    : _s(r['name']).trim();

                final phone = _s(r['phone']).trim();
                final whatsapp = _s(r['whatsapp']).trim();

                final details = _bulletLines(_s(d.description));

                final rs = _tryInt(d.priceRs);
                final mighty = _tryInt(d.priceMighty);

                final rsText = (rs != null && rs > 0) ? 'Rs $rs' : '— — —';
                final mightyText = (mighty != null && mighty > 0)
                    ? '$mighty Mighty'
                    : 'Mighty Only';

                final dealTitleSafe =
                    _s(d.title).trim().isEmpty ? 'Deal' : _s(d.title).trim();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon:
                                const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              restaurantName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Card (same style as Deals card)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                      child: _DealsLikeCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dealTitleSafe,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 8),

                            if (details.isNotEmpty) ...[
                              for (final line in details)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '• ',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.85),
                                          fontSize: 18,
                                          height: 1.2,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          line,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.75),
                                            fontSize: 16,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ] else ...[
                              Text(
                                'Deal details will appear here.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.70),
                                  fontSize: 16,
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),

                            // Rs + Mighty (same as cards)
                            Row(
                              children: [
                                Text(
                                  rsText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _MightyCapsuleSimple(text: mightyText),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Call + WhatsApp + Pay
                            Row(
                              children: [
                                _GlassIconButton(
                                  onTap: phone.isEmpty
                                      ? null
                                      : () => _launchTel(phone),
                                  icon: Icons.call,
                                ),
                                const SizedBox(width: 10),
                                _GlassIconButton(
                                  onTap: whatsapp.isEmpty
                                      ? null
                                      : () => _launchWhatsApp(whatsapp),
                                  iconWidget: const FaIcon(
                                    FontAwesomeIcons.whatsapp,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                _PayWithMightyButton(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Pay with Mighty will be wired to Edge Function next.',
                                        ),
                                      ),
                                    );
                                  },
                                  width: 170,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Expanded(child: SizedBox()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static int? _tryInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static List<String> _bulletLines(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return [];
    final cleaned = t.replaceAll('•', '\n•');
    final parts = cleaned
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.length > 1) {
      return parts
          .map((e) => e.startsWith('•') ? e.substring(1).trim() : e)
          .toList();
    }
    return [t];
  }

  static Future<void> _launchTel(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  static Future<void> _launchWhatsApp(String number) async {
    final cleaned = number.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _PlainDarkBackground extends StatelessWidget {
  const _PlainDarkBackground();

  @override
  Widget build(BuildContext context) {
    // same feel as Deals screen
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF050A14), Color(0xFF02040A)],
        ),
      ),
    );
  }
}

class _DealsLikeCard extends StatelessWidget {
  const _DealsLikeCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: kDeepNavy.withOpacity(0.88),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: 26,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _MightyCapsuleSimple extends StatelessWidget {
  const _MightyCapsuleSimple({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFF0FAFC0),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12.5,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.onTap, this.icon, this.iconWidget});

  final VoidCallback? onTap;
  final IconData? icon;
  final Widget? iconWidget;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 54,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(disabled ? 0.03 : 0.08),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Center(
          child: iconWidget ??
              Icon(
                icon,
                size: 22,
                color: Colors.white.withOpacity(disabled ? 0.25 : 0.92),
              ),
        ),
      ),
    );
  }
}

class _PayWithMightyButton extends StatelessWidget {
  const _PayWithMightyButton({required this.onTap, this.width = 180});

  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        height: 46,
        width: width,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(colors: [kAccentA, kAccentB]),
        ),
        child: const Text(
          'Redeem with Mighty',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15.5,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

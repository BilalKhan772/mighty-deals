import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../wallet/logic/wallet_controller.dart'; // ✅ NEW
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

    // ✅ wallet for disable
    final walletAsync = ref.watch(myWalletProvider);
    final int walletBalance = walletAsync.maybeWhen(
      data: (w) => w.balance,
      orElse: () => 0,
    );

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
                final whatsappRaw = _s(r['whatsapp']).trim();

                // ✅ Fallback: if whatsapp empty, use phone
                final whatsapp = whatsappRaw.isNotEmpty ? whatsappRaw : phone;

                final details = _bulletLines(_s(d.description));

                final rs = _tryInt(d.priceRs);
                final mighty = _tryInt(d.priceMighty);

                final rsText = (rs != null && rs > 0) ? 'Rs $rs' : '— — —';
                final mightyText = (mighty != null && mighty > 0)
                    ? '$mighty Mighty'
                    : 'Mighty Only';

                final dealTitleSafe =
                    _s(d.title).trim().isEmpty ? 'Deal' : _s(d.title).trim();

                final requiredMighty =
                    (mighty != null && mighty > 0) ? mighty : null;
                final canPay = requiredMighty != null
                    ? walletBalance >= requiredMighty
                    : false;

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
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
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

                    // Card
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            color:
                                                Colors.white.withOpacity(0.75),
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

                            Row(
                              children: [
                                // ✅ FIXED: proper widget use
                                _GlassIconButtonRow(
                                  context: context,
                                  phone: phone,
                                  whatsapp: whatsapp,
                                ),

                                const Spacer(),

                                _PayWithMightyButton(
                                  enabled: canPay,
                                  onTap: () async {
                                    if (requiredMighty == null) {
                                      _toast(
                                        context,
                                        'This deal is Mighty Only (set price_mighty > 0).',
                                      );
                                      return;
                                    }
                                    if (!canPay) {
                                      _toast(
                                        context,
                                        'Insufficient balance: need $requiredMighty Mighty.',
                                      );
                                      return;
                                    }

                                    final ok = await _confirmPay(
                                      context,
                                      title: 'Redeem Deal?',
                                      message:
                                          'This will deduct $requiredMighty Mighty from your wallet.',
                                    );
                                    if (!ok) return;

                                    await _payDealWithMighty(
                                      context,
                                      ref,
                                      dealId: d.id,
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
}

// =======================================================
// ✅ Pay helpers
// =======================================================

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg)),
  );
}

Future<bool> _confirmPay(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
  return res ?? false;
}

Future<void> _payDealWithMighty(
  BuildContext context,
  WidgetRef ref, {
  required String dealId,
}) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final client = Supabase.instance.client;

    final resp = await client.functions.invoke(
      'create_order_and_deduct_coins',
      body: {
        'deal_id': dealId,
      },
    );

    if (resp.status != 200) {
      throw Exception(resp.data?.toString() ?? 'Payment failed');
    }

    if (context.mounted) Navigator.pop(context);

    _toast(context, 'Order placed successfully ✅');

    ref.invalidate(myWalletProvider);
    ref.invalidate(myLedgerProvider);
    ref.invalidate(myOrdersProvider);
  } catch (e) {
    if (context.mounted) Navigator.pop(context);
    _toast(context, 'Error: $e');
  }
}

// =======================================================
// UI
// =======================================================

class _PlainDarkBackground extends StatelessWidget {
  const _PlainDarkBackground();

  @override
  Widget build(BuildContext context) {
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
  const _GlassIconButton({
    required this.onTap,
    this.icon,
    this.iconWidget,
  });

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
  const _PayWithMightyButton({
    required this.onTap,
    required this.width,
    required this.enabled,
  });

  final VoidCallback onTap;
  final double width;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
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
      ),
    );
  }
}

// =======================================================
// ✅ Contact buttons row (FIXED & USED ✅)
// =======================================================

class _GlassIconButtonRow extends StatelessWidget {
  const _GlassIconButtonRow({
    required this.context,
    required this.phone,
    required this.whatsapp,
  });

  final BuildContext context;
  final String phone;
  final String whatsapp;

  String _sanitizePhone(String phone) =>
      phone.replaceAll(RegExp(r'[^0-9+]'), '');

  // Pakistan default: 03xxxxxxxxx -> +923xxxxxxxxx
  String _normalizeToE164PK(String raw) {
    var p = _sanitizePhone(raw);
    if (p.isEmpty) return p;
    if (p.startsWith('+')) return p;

    if (p.startsWith('03')) {
      p = p.substring(1);
      return '+92$p';
    }
    if (p.startsWith('92')) return '+$p';
    return p;
  }

  Future<void> _launchTel(String phone) async {
    final cleaned = _sanitizePhone(phone);
    if (cleaned.isEmpty) {
      _toast(context, 'Phone number not available');
      return;
    }
    final uri = Uri(scheme: 'tel', path: cleaned);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _toast(context, 'Could not open dialer');
  }

  Future<void> _launchWhatsApp(String number) async {
    final e164 = _normalizeToE164PK(number);
    if (e164.isEmpty) {
      _toast(context, 'WhatsApp number not available');
      return;
    }

    final digits = e164.replaceAll('+', '').replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.https('wa.me', '/$digits', {
      'text': 'Hi! I saw your deal on Mighty Deals.',
    });

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _toast(context, 'Could not open WhatsApp');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GlassIconButton(
          onTap: phone.isEmpty ? null : () => _launchTel(phone),
          icon: Icons.call,
        ),
        const SizedBox(width: 10),
        _GlassIconButton(
          onTap: whatsapp.isEmpty ? null : () => _launchWhatsApp(whatsapp),
          iconWidget: const FaIcon(
            FontAwesomeIcons.whatsapp,
            size: 20,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

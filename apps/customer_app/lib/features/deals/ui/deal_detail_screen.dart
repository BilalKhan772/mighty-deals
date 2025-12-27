import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logic/deals_controller.dart';

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
          const _DetailBackground(),
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
                final restaurantName = (r['name'] as String?) ?? 'Restaurant';
                final phone = (r['phone'] as String?) ?? '';
                final whatsapp = (r['whatsapp'] as String?) ?? '';

                final priceText = _priceText(d);
                final details = _bulletLines(d.description ?? '');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // top bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
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

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 22),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withOpacity(0.10)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  if (details.isNotEmpty) ...[
                                    for (final line in details)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
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

                                  const SizedBox(height: 16),

                                  Text(
                                    priceText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  // actions row (call / whatsapp / pay)
                                  Row(
                                    children: [
                                      _SquareActionButton(
                                        icon: Icons.call,
                                        onTap: phone.isEmpty
                                            ? null
                                            : () => _launchTel(phone),
                                      ),
                                      const SizedBox(width: 12),
                                      _SquareActionButton(
                                        icon: Icons.chat_bubble_rounded,
                                        onTap: whatsapp.isEmpty
                                            ? null
                                            : () => _launchWhatsApp(whatsapp),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _PayButtonLarge(
                                          onTap: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Pay with Mighty will be added via Edge Function next.',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _priceText(dynamic d) {
    final rs = (d.priceRs as int?) ?? (d.priceRs as num?)?.toInt();
    if (rs != null && rs > 0) return 'Rs $rs';
    return '${d.priceMighty} Mighty';
  }

  static List<String> _bulletLines(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return [];

    // support: lines / commas / bullets
    final cleaned = t.replaceAll('•', '\n•');
    final parts = cleaned.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (parts.length > 1) {
      return parts.map((e) => e.startsWith('•') ? e.substring(1).trim() : e).toList();
    }
    // single line
    return [t];
  }

  static Future<void> _launchTel(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static Future<void> _launchWhatsApp(String number) async {
    final cleaned = number.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _DetailBackground extends StatelessWidget {
  const _DetailBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF08162B),
            Color(0xFF050A14),
          ],
        ),
      ),
    );
  }
}

class _SquareActionButton extends StatelessWidget {
  const _SquareActionButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 56,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(disabled ? 0.03 : 0.08),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Icon(
          icon,
          color: Colors.white.withOpacity(disabled ? 0.25 : 0.90),
        ),
      ),
    );
  }
}

class _PayButtonLarge extends StatelessWidget {
  const _PayButtonLarge({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF0CA9B8), Color(0xFF0B7C9D)],
          ),
        ),
        child: const Text(
          'Pay with Mighty',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

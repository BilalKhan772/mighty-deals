import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/deals_repo.dart';
import 'package:shared_supabase/shared_supabase.dart';
import 'package:shared_models/deal_model.dart';
import 'package:shared_models/restaurant_model.dart';

import '../../wallet/logic/wallet_controller.dart';

// ---------------- Colors ----------------
const Color kDeepNavy = Color(0xFF01203D);
const Color kAccentA = Color(0xFF10B7C7);
const Color kAccentB = Color(0xFF0B7C9D);

String _s(dynamic v) => (v == null) ? '' : v.toString();

// ✅ 1 Mighty = 3 Rs (fallback only)
const int kRsPerMighty = 3;

// ---------------- Providers ----------------
final restaurantsRepoProvider =
    Provider<RestaurantsRepo>((ref) => RestaurantsRepo());

final dealsRepoProvider = Provider<DealsRepo>((ref) => DealsRepo());

final restaurantProvider =
    FutureProvider.family<RestaurantModel, String>((ref, id) {
  return ref.read(restaurantsRepoProvider).getRestaurant(id);
});

final restaurantMenuProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, id) {
  return ref.read(restaurantsRepoProvider).listMenuItems(id);
});

final restaurantDealsProvider =
    FutureProvider.family<List<DealModel>, String>((ref, id) {
  return ref.read(dealsRepoProvider).listDealsByRestaurant(restaurantId: id);
});

// =======================================================

class RestaurantViewScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  const RestaurantViewScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<RestaurantViewScreen> createState() =>
      _RestaurantViewScreenState();
}

class _RestaurantViewScreenState extends ConsumerState<RestaurantViewScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rAsync = ref.watch(restaurantProvider(widget.restaurantId));

    return Scaffold(
      backgroundColor: const Color(0xFF050A14),
      body: Stack(
        children: [
          const _PlainDarkBackground(),
          SafeArea(
            child: rAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  e.toString(),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              data: (rest) => _Body(
                restaurant: rest,
                tab: _tab,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// BODY
// =======================================================

class _Body extends ConsumerWidget {
  const _Body({
    required this.restaurant,
    required this.tab,
  });

  final RestaurantModel restaurant;
  final TabController tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone = _s(restaurant.phone).trim();
    final whatsappRaw = _s(restaurant.whatsapp).trim();

    // ✅ Fallback: if whatsapp empty, use phone (same as deal detail screen)
    final whatsapp = whatsappRaw.isNotEmpty ? whatsappRaw : phone;

    final addressLine = [
      _s(restaurant.address).trim(),
      _s(restaurant.city).trim(),
    ].where((e) => e.isNotEmpty).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(child: _RestaurantAvatar(photoUrl: restaurant.photoUrl)),
                const SizedBox(height: 14),
                Text(
                  restaurant.name.isEmpty ? 'Restaurant' : restaurant.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  addressLine,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Contact Info (AS-IT-IS)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contact Info',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _GlassIconButton(
                    onTap:
                        phone.isEmpty ? null : () => _launchTel(context, phone),
                    icon: Icons.call,
                  ),
                  const SizedBox(width: 12),
                  _GlassIconButton(
                    onTap: whatsapp.isEmpty
                        ? null
                        : () => _launchWhatsApp(context, whatsapp),
                    iconWidget: const FaIcon(
                      FontAwesomeIcons.whatsapp,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: TabBar(
            controller: tab,
            indicatorColor: kAccentA,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
            tabs: const [
              Tab(text: 'Menu'),
              Tab(text: 'Deals'),
            ],
          ),
        ),

        const SizedBox(height: 10),

        Expanded(
          child: TabBarView(
            controller: tab,
            children: [
              _MenuTab(restaurantId: restaurant.id),
              _DealsTab(restaurantId: restaurant.id),
            ],
          ),
        ),
      ],
    );
  }
}

// =======================================================
// MENU TAB (✅ wallet balance checks + confirm + refresh)
// =======================================================

class _MenuTab extends ConsumerWidget {
  const _MenuTab({required this.restaurantId});
  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(restaurantMenuProvider(restaurantId));

    final walletAsync = ref.watch(myWalletProvider);
    final int walletBalance = walletAsync.maybeWhen(
      data: (w) => w.balance,
      orElse: () => 0,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: menuAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            e.toString(),
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No menu items',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final it = items[i];
              final menuItemId = _s(it['id']).trim();

              final name = _s(it['name']).trim();
              final priceRs = _tryInt(it['price_rs']);

              final mightyDb = _tryInt(it['price_mighty']);
              final mightyFallback = _mightyFromRs(priceRs);
              final priceMighty = mightyDb ?? mightyFallback;

              final rsText =
                  (priceRs != null && priceRs > 0) ? 'Rs $priceRs' : '— — —';

              final mightyText = (priceMighty != null && priceMighty > 0)
                  ? '$priceMighty Mighty'
                  : 'Mighty Only';

              final int? requiredMighty =
                  (priceMighty != null && priceMighty > 0) ? priceMighty : null;

              final bool canPay = requiredMighty != null
                  ? walletBalance >= requiredMighty
                  : false;

              return _RedeemListCard(
                title: name.isEmpty ? 'Item' : name,
                subtitle: null,
                rsText: rsText,
                mightyText: mightyText,
                buttonEnabled: canPay,
                onRedeemTap: canPay
                    ? () async {
                        if (menuItemId.isEmpty) {
                          _toast(context, 'Menu item invalid');
                          return;
                        }

                        final ok = await _confirmPay(
                          context,
                          title: 'Redeem Menu Item?',
                          message:
                              'This will deduct $requiredMighty Mighty from your wallet.',
                        );
                        if (!ok) return;

                        await _invokePay(
                          context,
                          ref,
                          body: {'menu_item_id': menuItemId},
                        );
                      }
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

// =======================================================
// DEALS TAB (✅ wallet balance checks + confirm + refresh)
// =======================================================

class _DealsTab extends ConsumerWidget {
  const _DealsTab({required this.restaurantId});
  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsAsync = ref.watch(restaurantDealsProvider(restaurantId));

    final walletAsync = ref.watch(myWalletProvider);
    final int walletBalance = walletAsync.maybeWhen(
      data: (w) => w.balance,
      orElse: () => 0,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: dealsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            e.toString(),
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        data: (deals) {
          if (deals.isEmpty) {
            return const Center(
              child: Text('No deals', style: TextStyle(color: Colors.white70)),
            );
          }

          return ListView.separated(
            itemCount: deals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final d = deals[i];

              final title =
                  _s(d.title).trim().isEmpty ? 'Deal' : _s(d.title).trim();
              final desc = _s(d.description).trim();
              final subLine = desc.isNotEmpty ? desc : _s(d.category).trim();
              final subtitle = subLine.isNotEmpty ? subLine : null;

              final rsText = (d.priceRs != null && d.priceRs! > 0)
                  ? 'Rs ${d.priceRs}'
                  : '— — —';

              final int? requiredMighty =
                  (d.priceMighty > 0) ? d.priceMighty : null;

              final mightyText = (requiredMighty != null)
                  ? '${d.priceMighty} Mighty'
                  : 'Mighty Only';

              final bool canPay = requiredMighty != null
                  ? walletBalance >= requiredMighty
                  : false;

              return _RedeemListCard(
                title: title,
                subtitle: subtitle,
                rsText: rsText,
                mightyText: mightyText,
                buttonEnabled: canPay,
                onRedeemTap: canPay
                    ? () async {
                        if (d.id.isEmpty) {
                          _toast(context, 'Deal invalid');
                          return;
                        }

                        final ok = await _confirmPay(
                          context,
                          title: 'Redeem Deal?',
                          message:
                              'This will deduct $requiredMighty Mighty from your wallet.',
                        );
                        if (!ok) return;

                        await _invokePay(
                          context,
                          ref,
                          body: {'deal_id': d.id},
                        );
                      }
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

// =======================================================
// ✅ FINAL: Card layout (button ALWAYS on next row bottom-right)
// =======================================================

class _RedeemListCard extends StatelessWidget {
  const _RedeemListCard({
    required this.title,
    required this.subtitle,
    required this.rsText,
    required this.mightyText,
    required this.buttonEnabled,
    required this.onRedeemTap,
  });

  final String title;
  final String? subtitle;
  final String rsText;
  final String mightyText;
  final bool buttonEnabled;
  final VoidCallback? onRedeemTap;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Subtitle (Deals only)
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.70),
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // ✅ Row 1: Price ONLY (Rs + Mighty capsule)
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                rsText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              _MightyCapsuleSimple(text: mightyText),
            ],
          ),

          const SizedBox(height: 14),

          // ✅ Row 2: Button forced to next line (bottom-right)
          SizedBox(
            width: double.infinity,
            child: Align(
              alignment: Alignment.centerRight,
              child: _PayWithMightyButton(
                enabled: buttonEnabled,
                onTap: onRedeemTap,
                width: 190,
                height: 44,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// Edge Function caller + helpers
// =======================================================

Future<void> _invokePay(
  BuildContext context,
  WidgetRef ref, {
  required Map<String, dynamic> body,
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
      body: body,
    );

    if (context.mounted) Navigator.pop(context);

    final data = resp.data;

    if (resp.status != 200) {
      final err = (data is Map && data['error'] != null)
          ? data['error'].toString()
          : 'Payment failed';

      String msg;
      switch (err) {
        case 'PROFILE_INCOMPLETE':
          msg = 'Please complete your profile first.';
          break;
        case 'INSUFFICIENT_BALANCE':
          msg = 'Insufficient Mighty balance.';
          break;
        case 'DEAL_NOT_FOUND':
          msg = 'Deal not found or inactive.';
          break;
        case 'MENU_ITEM_NOT_FOUND':
          msg = 'Menu item not found or inactive.';
          break;
        case 'RESTAURANT_RESTRICTED':
          msg = 'Restaurant is restricted.';
          break;
        case 'RESTAURANT_NOT_FOUND':
          msg = 'Restaurant not found.';
          break;
        case 'INVALID_MIGHTY_PRICE':
          msg = 'Invalid Mighty price for this item.';
          break;
        default:
          msg = 'Error: $err';
      }

      _toast(context, msg);
      return;
    }

    _toast(context, 'Order placed successfully ✅');

    ref.invalidate(myWalletProvider);
    ref.invalidate(myLedgerProvider);
    ref.invalidate(myOrdersProvider);
  } catch (e) {
    if (context.mounted) Navigator.pop(context);
    _toast(context, 'Error: $e');
  }
}

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

// =======================================================
// UI HELPERS
// =======================================================

class _RestaurantAvatar extends StatelessWidget {
  const _RestaurantAvatar({required this.photoUrl});
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = _s(photoUrl).trim();

    if (url.isEmpty) {
      return const CircleAvatar(
        radius: 60,
        backgroundColor: Color(0xFFFFC83D),
        child: Icon(
          Icons.lunch_dining,
          size: 54,
          color: Color(0xFF3B2A00),
        ),
      );
    }

    return ClipOval(
      child: Image.network(
        url,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const CircleAvatar(
          radius: 60,
          backgroundColor: Color(0xFFFFC83D),
          child: Icon(
            Icons.lunch_dining,
            size: 54,
            color: Color(0xFF3B2A00),
          ),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const SizedBox(
            width: 120,
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
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
  const _PayWithMightyButton({
    required this.onTap,
    required this.width,
    required this.height,
    required this.enabled,
  });

  final VoidCallback? onTap;
  final double width;
  final double height;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: height,
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
              fontSize: 14.5,
              letterSpacing: -0.2,
            ),
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

// =======================================================
// Helpers
// =======================================================

int? _tryInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

// ✅ ceil division: ceil(rs/3) (fallback only)
int? _mightyFromRs(int? rs) {
  if (rs == null || rs <= 0) return null;
  return ((rs + (kRsPerMighty - 1)) / kRsPerMighty).floor();
}

// -------------------- Reliable launch helpers --------------------

String _sanitizePhone(String phone) => phone.replaceAll(RegExp(r'[^0-9+]'), '');

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

Future<void> _launchTel(BuildContext context, String phone) async {
  final cleaned = _sanitizePhone(phone);
  if (cleaned.isEmpty) {
    _toast(context, 'Phone number not available');
    return;
  }

  final uri = Uri(scheme: 'tel', path: cleaned);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) _toast(context, 'Could not open dialer');
}

Future<void> _launchWhatsApp(BuildContext context, String number) async {
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

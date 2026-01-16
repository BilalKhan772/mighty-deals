import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routing/route_names.dart';
import '../../wallet/logic/wallet_controller.dart';
import '../logic/deals_controller.dart';
import 'deal_detail_screen.dart';

// ✅ Deep navy
const Color kDeepNavy = Color(0xFF01203D);

// ✅ Accent
const Color kAccentA = Color(0xFF10B7C7);
const Color kAccentB = Color(0xFF0B7C9D);

// ---------------- Debouncer ----------------
class _Debouncer {
  _Debouncer(this.ms);
  final int ms;
  VoidCallback? _action;
  bool _disposed = false;

  void run(VoidCallback action) {
    _action = action;
    Future.delayed(Duration(milliseconds: ms), () {
      if (_disposed) return;
      if (_action == action) action();
    });
  }

  void dispose() => _disposed = true;
}

// ✅ safe string helper
String _s(dynamic v) => (v == null) ? '' : v.toString();

class DealsScreen extends ConsumerStatefulWidget {
  const DealsScreen({super.key});

  @override
  ConsumerState<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends ConsumerState<DealsScreen> {
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();
  late final _debouncer = _Debouncer(400);

  final _categories = const [
    'All',
    'Fast Food',
    'Desi',
    'Street Food',
    'Chinese',
    'Cafe',
    'BBQ',
  ];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 250) {
        ref.read(dealsControllerProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cityAsync = ref.watch(currentUserCityProvider);
    final dealsStateAsync = ref.watch(dealsControllerProvider);
    final query = ref.watch(dealsQueryProvider);

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 14, 18, 6),
                  child: Text(
                    'Mighty Deals',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Search
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                  child: _PremiumSearchBar(
                    controller: _searchCtrl,
                    hintText: 'Search',
                    onChanged: (v) {
                      setState(() {});
                      _debouncer.run(() {
                        ref
                            .read(dealsControllerProvider.notifier)
                            .setSearch(v.trim());
                      });
                    },
                    onClear: () {
                      _searchCtrl.clear();
                      setState(() {});
                      ref.read(dealsControllerProvider.notifier).setSearch('');
                    },
                  ),
                ),

                // Chips
                SizedBox(
                  height: 46,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final c = _categories[i];
                      final selected = query.category == c;
                      return _FilterChipPill(
                        text: c,
                        selected: selected,
                        onTap: () => ref
                            .read(dealsControllerProvider.notifier)
                            .setCategory(c),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: cityAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text(
                        e.toString(),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    data: (city) {
                      if (city.trim().isEmpty) {
                        return const Center(
                          child: Text(
                            'Please set your city in Profile first.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      return dealsStateAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(
                          child: Text(
                            e.toString(),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        data: (state) {
                          // ✅ NEW: better empty message for category vs city
                          final selectedCategory = query.category.trim();
                          final isAll = selectedCategory == 'All';

                          final String emptyText = isAll
                              ? 'No deals available for $city right now.'
                              : 'No $selectedCategory deals available in $city yet.';

                          return RefreshIndicator(
                            onRefresh: () async {
                              await ref
                                  .read(dealsControllerProvider.notifier)
                                  .refresh();
                              ref.invalidate(myWalletProvider);
                              ref.invalidate(myLedgerProvider);
                              ref.invalidate(myOrdersProvider);
                            },
                            child: state.items.isEmpty
                                ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      const SizedBox(height: 140),
                                      Center(
                                        child: _EmptyPillMessage(
                                          text: emptyText,
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    controller: _scroll,
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      6,
                                      16,
                                      20,
                                    ),
                                    itemCount: state.items.length + 1,
                                    itemBuilder: (_, i) {
                                      if (i == state.items.length) {
                                        if (state.isLoadingMore) {
                                          return const Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        }
                                        if (!state.hasMore) {
                                          return const Padding(
                                            padding: EdgeInsets.all(18),
                                            child: Center(
                                              child: Text(
                                                'No more deals',
                                                style: TextStyle(
                                                  color: Colors.white54,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox(height: 14);
                                      }

                                      final d = state.items[i];
                                      final r = d.restaurant ?? {};

                                      final restaurantName =
                                          _s(r['name']).trim().isNotEmpty
                                              ? _s(r['name']).trim()
                                              : 'Restaurant';

                                      final restaurantId = _s(r['id']).trim();

                                      final phone = _s(r['phone']).trim();
                                      final whatsappRaw =
                                          _s(r['whatsapp']).trim();

                                      // ✅ If whatsapp missing, still allow whatsapp icon using phone
                                      final whatsapp = whatsappRaw.isNotEmpty
                                          ? whatsappRaw
                                          : phone;

                                      // ✅ NEW: photo url for avatar
                                      final restaurantPhotoUrl =
                                          _s(r['photo_url']).trim();

                                      final rs = _tryInt(d.priceRs);
                                      final mighty = _tryInt(d.priceMighty);

                                      final dealTitleSafe =
                                          _s(d.title).trim().isEmpty
                                              ? 'Deal'
                                              : _s(d.title).trim();

                                      final descSafe = _s(d.description).trim();
                                      final catSafe = _s(d.category).trim();

                                      final subLineSafe =
                                          descSafe.isEmpty ? catSafe : descSafe;

                                      final int? requiredMighty =
                                          (mighty != null && mighty > 0)
                                              ? mighty
                                              : null;

                                      final bool canPay = requiredMighty != null
                                          ? walletBalance >= requiredMighty
                                          : false;

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 14),
                                        child: DealCardCleanFinal(
                                          restaurantName: restaurantName,
                                          restaurantPhotoUrl:
                                              restaurantPhotoUrl,
                                          dealTitle: dealTitleSafe,
                                          subLine: subLineSafe,
                                          priceRs: rs,
                                          mightyAmount: mighty,
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    DealDetailScreen(
                                                  dealId: d.id,
                                                ),
                                              ),
                                            );
                                          },
                                          onRestaurantTap: restaurantId.isEmpty
                                              ? null
                                              : () {
                                                  context.push(
                                                    '${RouteNames.restaurant}/$restaurantId',
                                                  );
                                                },
                                          onCall: phone.isEmpty
                                              ? null
                                              : () =>
                                                  _launchTel(context, phone),
                                          onWhatsapp: whatsapp.isEmpty
                                              ? null
                                              : () => _launchWhatsApp(
                                                  context, whatsapp),
                                          payEnabled: canPay,
                                          onPay: canPay
                                              ? () async {
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
                                              : () {
                                                  if (requiredMighty == null) {
                                                    _toast(context,
                                                        'Invalid Mighty price for this deal.');
                                                  } else {
                                                    _toast(
                                                      context,
                                                      'Insufficient balance: need $requiredMighty Mighty.',
                                                    );
                                                  }
                                                },
                                        ),
                                      );
                                    },
                                  ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int? _tryInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  // ===================== LAUNCHERS (FIXED) =====================

  String _sanitizePhone(String phone) =>
      phone.replaceAll(RegExp(r'[^0-9+]'), '');

  // ✅ default Pakistan conversion: 0300... -> +92300...
  String _normalizeToE164PK(String raw) {
    var p = _sanitizePhone(raw);
    if (p.isEmpty) return p;
    if (p.startsWith('+')) return p;

    if (p.startsWith('03')) {
      p = p.substring(1); // remove leading 0
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

    if (!ok && context.mounted) {
      _toast(context, 'Could not open dialer');
    }
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
    if (!ok && context.mounted) {
      _toast(context, 'Could not open WhatsApp');
    }
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

// =======================================================
// UI WIDGETS
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

/// ✅ Spins-style empty state pill for Deals
class _EmptyPillMessage extends StatelessWidget {
  const _EmptyPillMessage({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: kDeepNavy.withOpacity(0.78),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.88),
          fontSize: 14.5,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

class _PremiumSearchBar extends StatelessWidget {
  const _PremiumSearchBar({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: kDeepNavy.withOpacity(0.88),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.30),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 10),
                child:
                    Icon(Icons.search, color: Colors.white.withOpacity(0.75)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 46),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: onClear,
                      icon: Icon(
                        Icons.close,
                        color: Colors.white.withOpacity(0.72),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  const _FilterChipPill({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected ? Colors.transparent : Colors.white.withOpacity(0.18);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: selected
                ? const LinearGradient(colors: [kAccentA, kAccentB])
                : null,
            color: selected ? null : Colors.transparent,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white.withOpacity(0.82),
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

// =======================================================
// Deal Card (unchanged)
// =======================================================

class DealCardCleanFinal extends StatelessWidget {
  const DealCardCleanFinal({
    super.key,
    required this.restaurantName,
    required this.restaurantPhotoUrl,
    required this.dealTitle,
    required this.subLine,
    required this.priceRs,
    required this.mightyAmount,
    required this.onTap,
    required this.onPay,
    this.onCall,
    this.onWhatsapp,
    this.onRestaurantTap,
    required this.payEnabled,
  });

  final String restaurantName;
  final String restaurantPhotoUrl;
  final String dealTitle;
  final String subLine;
  final int? priceRs;
  final int? mightyAmount;
  final VoidCallback onTap;
  final VoidCallback onPay;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsapp;
  final VoidCallback? onRestaurantTap;

  final bool payEnabled;

  @override
  Widget build(BuildContext context) {
    final rsText =
        (priceRs != null && priceRs! > 0) ? 'Rs $priceRs' : '— — —';

    return RepaintBoundary(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Material(
          color: Colors.transparent,
          elevation: 0,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: onRestaurantTap,
                        child: _RestaurantAvatar(
                          letter: _firstLetter(restaurantName),
                          photoUrl: restaurantPhotoUrl,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurantName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dealTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.82),
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.78),
                      fontSize: 13.8,
                      height: 1.22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                      _MightyCapsuleSimple(
                        text: (mightyAmount != null && mightyAmount! > 0)
                            ? '$mightyAmount Mighty'
                            : 'Mighty Only',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _GlassIconButton(onTap: onCall, icon: Icons.call),
                      const SizedBox(width: 10),
                      _GlassIconButton(
                        onTap: onWhatsapp,
                        iconWidget: const FaIcon(
                          FontAwesomeIcons.whatsapp,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      _PayWithMightyButton(
                        onTap: payEnabled ? onPay : null,
                        width: 170,
                        enabled: payEnabled,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _firstLetter(String s) {
    final t = s.trim();
    if (t.isEmpty) return 'M';
    return t[0].toUpperCase();
  }
}

class _RestaurantAvatar extends StatelessWidget {
  const _RestaurantAvatar({
    required this.letter,
    required this.photoUrl,
  });

  final String letter;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl.trim().isNotEmpty;

    return Container(
      width: 54,
      height: 54,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFFF4D4D), Color(0xFFFF8A3D)],
        ),
      ),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
                photoUrl,
                width: 54,
                height: 54,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    letter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  letter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
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
    this.width = 180,
    required this.enabled,
  });

  final VoidCallback? onTap;
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

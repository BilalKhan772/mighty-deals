import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart'; // ✅ add
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routing/route_names.dart'; // ✅ add
import '../logic/deals_controller.dart';
import 'deal_detail_screen.dart';

// ✅ Deep navy (image jaisa)
const Color kDeepNavy = Color(0xFF01203D);

// ✅ Accent (Pay with Mighty vibe)
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

// ✅ safe string helper (fix warnings)
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
                          return RefreshIndicator(
                            onRefresh: () => ref
                                .read(dealsControllerProvider.notifier)
                                .refresh(),
                            child: state.items.isEmpty
                                ? ListView(
                                    children: const [
                                      SizedBox(height: 140),
                                      Center(
                                        child: Text(
                                          'No deals found',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
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

                                      final restaurantId =
                                          _s(r['id']).trim(); // ✅ important

                                      final phone = _s(r['phone']).trim();
                                      final whatsapp = _s(r['whatsapp']).trim();

                                      final rs = _tryInt(d.priceRs);
                                      final mighty = _tryInt(d.priceMighty);

                                      final dealTitleSafe =
                                          _s(d.title).trim().isEmpty
                                              ? 'Deal'
                                              : _s(d.title).trim();

                                      final descSafe = _s(d.description).trim();
                                      final catSafe = _s(d.category).trim();

                                      final subLineSafe = descSafe.isEmpty
                                          ? catSafe
                                          : descSafe;

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 14,
                                        ),
                                        child: DealCardCleanFinal(
                                          restaurantName: restaurantName,
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
                                              : () => _launchTel(phone),
                                          onWhatsapp: whatsapp.isEmpty
                                              ? null
                                              : () => _launchWhatsApp(whatsapp),
                                          onPay: () {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Pay with Mighty will be wired to Edge Function next.',
                                                ),
                                              ),
                                            );
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

  Future<void> _launchTel(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchWhatsApp(String number) async {
    final cleaned = number.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
                child: Icon(Icons.search, color: Colors.white.withOpacity(0.75)),
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
// Deal Card
// =======================================================

class DealCardCleanFinal extends StatelessWidget {
  const DealCardCleanFinal({
    super.key,
    required this.restaurantName,
    required this.dealTitle,
    required this.subLine,
    required this.priceRs,
    required this.mightyAmount,
    required this.onTap,
    required this.onPay,
    this.onCall,
    this.onWhatsapp,
    this.onRestaurantTap, // ✅ NEW
  });

  final String restaurantName;
  final String dealTitle;
  final String subLine;
  final int? priceRs;
  final int? mightyAmount;
  final VoidCallback onTap;
  final VoidCallback onPay;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsapp;
  final VoidCallback? onRestaurantTap; // ✅ NEW

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
                      // ✅ Avatar clickable
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: onRestaurantTap,
                        child: _RestaurantAvatar(
                          letter: _firstLetter(restaurantName),
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
                      color: Colors.white.withOpacity(0.68),
                      fontSize: 13.8,
                      height: 1.22,
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
                      _PayWithMightyButton(onTap: onPay, width: 170),
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
  const _RestaurantAvatar({required this.letter});
  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFFF4D4D), Color(0xFFFF8A3D)],
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
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

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/deals_repo.dart';
import 'package:shared_supabase/shared_supabase.dart';
import 'package:shared_models/deal_model.dart';
import 'package:shared_models/restaurant_model.dart';

// ---------------- Colors ----------------
const Color kDeepNavy = Color(0xFF01203D);
const Color kAccentA = Color(0xFF10B7C7);
const Color kAccentB = Color(0xFF0B7C9D);

String _s(dynamic v) => (v == null) ? '' : v.toString();

// ✅ 1 Mighty = 3 Rs
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
    final whatsapp = _s(restaurant.whatsapp).trim();

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

        // ✅ Header (center aligned)
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

        // Contact Info label + buttons
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
                    onTap: phone.isEmpty ? null : () => _launchTel(phone),
                    icon: Icons.call,
                  ),
                  const SizedBox(width: 12),
                  _GlassIconButton(
                    onTap:
                        whatsapp.isEmpty ? null : () => _launchWhatsApp(whatsapp),
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
// MENU TAB (✅ Rs + ✅ Mighty Capsule (auto) + Pay with Mighty)
// =======================================================

class _MenuTab extends ConsumerWidget {
  const _MenuTab({required this.restaurantId});
  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(restaurantMenuProvider(restaurantId));

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
              final name = _s(it['name']).trim();

              final priceRs = _tryInt(it['price_rs']);

              // ✅ Mighty auto calculate: ceil(rs/3)
              final priceMighty = _mightyFromRs(priceRs);

              final rsText =
                  (priceRs != null && priceRs > 0) ? 'Rs $priceRs' : '— — —';

              final mightyText = (priceMighty != null && priceMighty > 0)
                  ? '$priceMighty Mighty'
                  : 'Mighty Only';

              return _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Item' : name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
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
                        const Spacer(),
                        _PayWithMightyButton(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Menu Pay with Mighty (Edge Function later)'),
                              ),
                            );
                          },
                          width: 160,
                          height: 44,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =======================================================
// DEALS TAB
// =======================================================

class _DealsTab extends ConsumerWidget {
  const _DealsTab({required this.restaurantId});
  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsAsync = ref.watch(restaurantDealsProvider(restaurantId));

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

              final rsText = (d.priceRs != null && d.priceRs! > 0)
                  ? 'Rs ${d.priceRs}'
                  : '— — —';

              final mightyText =
                  (d.priceMighty > 0) ? '${d.priceMighty} Mighty' : 'Mighty Only';

              return _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_s(d.tag).trim().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _s(d.tag).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subLine,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.70),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
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
                          ),
                        ),
                        const SizedBox(width: 10),
                        _MightyCapsuleSimple(text: mightyText),
                        const Spacer(),
                        _PayWithMightyButton(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pay with Mighty (Edge Function) next step'),
                              ),
                            );
                          },
                          width: 160,
                          height: 44,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
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
  });

  final VoidCallback onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
          'Pay with Mighty',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14.5,
            letterSpacing: -0.2,
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

// ✅ ceil division: ceil(rs/3)
int? _mightyFromRs(int? rs) {
  if (rs == null || rs <= 0) return null;
  return ((rs + (kRsPerMighty - 1)) / kRsPerMighty).floor();
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

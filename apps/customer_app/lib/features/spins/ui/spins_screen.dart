import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_models/spin_model.dart';
import '../data/spins_repo.dart';
import '../ui/spin_detail_screen.dart';
import 'package:shared_supabase/supabase_client.dart';

class SpinsScreen extends StatefulWidget {
  const SpinsScreen({super.key});

  @override
  State<SpinsScreen> createState() => _SpinsScreenState();
}

class _SpinsScreenState extends State<SpinsScreen> {
  final _repo = SpinsRepo();
  bool _loading = true;
  String? _city;
  List<SpinModel> _spins = [];

  // ✅ In-app "publish" notification (session-based; no new packages)
  static final Set<String> _seenSpinIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load(showPublishToast: false);
  }

  Future<void> _load({bool showPublishToast = true}) async {
    if (!mounted) return;
    setState(() => _loading = true);

    final uid = SB.client.auth.currentUser?.id;
    if (uid == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _city = null;
        _spins = [];
      });
      return;
    }

    final prof = await SB.client
        .from('profiles')
        .select('city')
        .eq('id', uid)
        .maybeSingle();

    final city = (prof?['city'] as String?)?.trim();

    if (city == null || city.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _city = null;
        _spins = [];
      });
      return;
    }

    final spins = await _repo.listForCity(city);

    // ✅ detect "new spin published"
    final newOnes = spins.where((s) => !_seenSpinIds.contains(s.id)).toList();
    for (final s in spins) {
      _seenSpinIds.add(s.id);
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _city = city;
      _spins = spins;
    });

    if (showPublishToast && newOnes.isNotEmpty && mounted) {
      final msg = newOnes.length == 1
          ? '🔥 New spin available in $city!'
          : '🔥 ${newOnes.length} new spins available in $city!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050A14),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Mighty Spin',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(onPressed: () => _load(), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Stack(
        children: [
          const _PlainDarkBackground(),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _city == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _DealsLikeCard(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.location_city,
                                  size: 40, color: Colors.white70),
                              SizedBox(height: 10),
                              Text(
                                'Please set your City in Profile to see spins.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : _spins.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: _DealsLikeCard(
                              child: Text(
                                'No spins available for $_city right now.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _load(),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
                            itemCount: _spins.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final s = _spins[i];
                              return _SpinCard(
                                spin: s,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SpinDetailScreen(spin: s),
                                    ),
                                  );
                                  await _load(showPublishToast: false);
                                },
                              );
                            },
                          ),
                        ),
        ],
      ),
    );
  }
}

class _SpinCard extends StatelessWidget {
  final SpinModel spin;
  final VoidCallback onTap;

  const _SpinCard({
    required this.spin,
    required this.onTap,
  });

  String _timeLeftText(SpinModel s) {
    final close = s.regCloseAt;
    if (close == null) return '';
    final diff = close.difference(DateTime.now());
    if (diff.isNegative) return 'Closed';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  String _badgeText(SpinModel s) {
    if (s.status == 'finished') return 'FINISHED';
    if (s.status == 'running') return 'LIVE';
    if (s.status == 'published') return 'OPEN';
    return s.status.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badgeText(spin);
    final t = _timeLeftText(spin);
    final mightyCost =
        (spin.paidCostPerSlot <= 0) ? 10 : spin.paidCostPerSlot; // ✅ UI fallback

    final bool isJoinable = spin.status == 'published' || spin.status == 'running';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: _DealsLikeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ No duplicate title inside card
            Row(
              children: [
                _Badge(text: badge),
                const Spacer(),
                if (t.isNotEmpty) _MiniChip(icon: Icons.timer, text: t),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
                color: Colors.white.withOpacity(0.04),
              ),
              child: Text(
                spin.dealText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),

            // ✅ NEW: subtle guidance text (doesn't disturb existing UI)
            const SizedBox(height: 8),
            if (isJoinable)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 16,
                    color: Colors.white.withOpacity(0.55),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tap to join',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.58),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MiniChip(icon: Icons.location_city, text: spin.city),
                _MiniChip(icon: Icons.people_alt, text: 'Free: ${spin.freeSlots}'),
                _MiniChip(icon: Icons.bolt, text: '$mightyCost Mighty'),
              ],
            ),
            if (spin.status == 'finished' && spin.displayWinnerCode.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.emoji_events,
                      size: 18, color: Colors.amber.withOpacity(0.95)),
                  const SizedBox(width: 8),
                  Text(
                    'Winner: ${spin.displayWinnerCode}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    Color bg;
    if (text == 'OPEN') bg = const Color(0xFF06B6D4);
    else if (text == 'LIVE') bg = Colors.green;
    else if (text == 'FINISHED') bg = Colors.amber;
    else bg = Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: bg.withOpacity(0.18),
        border: Border.all(color: bg.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
          fontSize: 12,
          color: Colors.white.withOpacity(0.92),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MiniChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        color: Colors.white.withOpacity(0.04),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withOpacity(0.85)),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
              color: const Color(0xFF01203D).withOpacity(0.88),
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

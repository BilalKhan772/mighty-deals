// apps/customer_app/lib/features/wallet/ui/wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/no_internet_view.dart'; // ✅ ADD THIS
import '../logic/wallet_controller.dart';

/// ✅ safe string helper (avoids map casting crashes)
String _s(dynamic v) => (v == null) ? '' : v.toString();

/// =======================
/// Tabs state
/// =======================
enum WalletTab { topUp, orders }

final walletTabProvider = StateProvider<WalletTab>((ref) => WalletTab.topUp);

/// ✅ Remove overscroll glow
class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  Color w(double a) => Colors.white.withAlpha((a * 255).round());

  void _showWalletInfo(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF072033),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 22,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    const Color(0xFF0AA6C3).withOpacity(0.22),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Information',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            _MiniIconButton(
                              icon: Icons.close,
                              onTap: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF061A2A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.10),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF34E8B0)
                                      .withOpacity(0.18),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Color(0xFF34E8B0),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Weekly refresh',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'At the end of each week, your Activity and Redemption history refreshes — so older records may be cleared.',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        height: 1.25,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0AA6C3),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'OK',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(myWalletProvider);
    final tab = ref.watch(walletTabProvider);

    const double topGap = 28;

    // ✅ for perfect placement relative to status bar + appbar
    final topInset = MediaQuery.of(context).padding.top;

    return ScrollConfiguration(
      behavior: const _NoGlowScrollBehavior(),
      child: Scaffold(
        backgroundColor: const Color(0xFF070B14),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          titleSpacing: 18,
          title: const Text(
            'Wallet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _AppBarIconTight(
                icon: Icons.refresh,
                onTap: () {
                  ref.invalidate(myWalletProvider);
                  ref.invalidate(myLedgerProvider);
                  ref.invalidate(myOrdersProvider);
                },
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            // ✅ main UI (unchanged)
            Container(
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
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: topGap),

                          // ✅ Balance Card
                          walletAsync.when(
                            loading: () => const _BalanceSkeleton(),
                            error: (e, _) => Center(
                              child: NoInternetView(
                                title: "Can't load wallet",
                                message:
                                    "Please connect to internet and try again.",
                                onRetry: () {
                                  ref.invalidate(myWalletProvider);
                                  ref.invalidate(myLedgerProvider);
                                  ref.invalidate(myOrdersProvider);
                                },
                              ),
                            ),
                            data: (wallet) => _BalanceCard(
                              balance: wallet.balance.toString(),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ✅ Purchase Button
                          SizedBox(
                            height: 56,
                            child: _PurchaseButton(
                              onPressed: () async {
                                final uri = Uri.parse(
                                  'https://mighty-deal-support.netlify.app/',
                                );

                                final ok = await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );

                                if (!ok && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Could not open link'),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ✅ Tabs row: Activity | Redemption
                          Row(
                            children: [
                              _TabButton(
                                label: 'Activity',
                                active: tab == WalletTab.topUp,
                                onTap: () => ref
                                    .read(walletTabProvider.notifier)
                                    .state = WalletTab.topUp,
                              ),
                              const SizedBox(width: 10),
                              _TabButton(
                                label: 'Redemption',
                                active: tab == WalletTab.orders,
                                onTap: () => ref
                                    .read(walletTabProvider.notifier)
                                    .state = WalletTab.orders,
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ✅ Content container
                          Expanded(
                            child: _PanelContainer(
                              child: tab == WalletTab.topUp
                                  ? ref.watch(myLedgerProvider).when(
                                      loading: () => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      error: (e, _) => Center(
                                        child: NoInternetView(
                                          title: "Can't load activity",
                                          message:
                                              "Please connect to internet and try again.",
                                          onRetry: () {
                                            ref.invalidate(myWalletProvider);
                                            ref.invalidate(myLedgerProvider);
                                            ref.invalidate(myOrdersProvider);
                                          },
                                        ),
                                      ),
                                      data: (list) {
                                        if (list.isEmpty) {
                                          return const _EmptyState(
                                            text: 'No activity yet',
                                          );
                                        }
                                        return ListView.separated(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          padding: const EdgeInsets.all(14),
                                          itemCount: list.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(height: 10),
                                          itemBuilder: (_, i) {
                                            final x = list[i];
                                            final isPlus = x.amount >= 0;
                                            final amountText =
                                                '${isPlus ? '+' : ''}${x.amount}';

                                            return _HistoryRow(
                                              title: _prettyLedgerTitle(x.type),
                                              subtitle: _fmtPretty(
                                                x.createdAt.toLocal(),
                                              ),
                                              isPlus: isPlus,
                                              amount: amountText,
                                            );
                                          },
                                        );
                                      },
                                    )
                                  : ref.watch(myOrdersProvider).when(
                                      loading: () => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      error: (e, _) => Center(
                                        child: NoInternetView(
                                          title: "Can't load redemption",
                                          message:
                                              "Please connect to internet and try again.",
                                          onRetry: () {
                                            ref.invalidate(myWalletProvider);
                                            ref.invalidate(myLedgerProvider);
                                            ref.invalidate(myOrdersProvider);
                                          },
                                        ),
                                      ),
                                      data: (orders) {
                                        if (orders.isEmpty) {
                                          return const _EmptyState(
                                            text: 'No orders yet',
                                          );
                                        }

                                        return ListView.separated(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          padding: const EdgeInsets.all(14),
                                          itemCount: orders.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(height: 10),
                                          itemBuilder: (_, i) {
                                            final o = orders[i];

                                            final rest = o.restaurant;
                                            final deal = o.deal;
                                            final menu = o.menuItem;

                                            final restaurantName =
                                                _s(rest?['name']).trim().isNotEmpty
                                                    ? _s(rest?['name']).trim()
                                                    : 'Restaurant';

                                            final dealTitle =
                                                _s(deal?['title']).trim().isNotEmpty
                                                    ? _s(deal?['title']).trim()
                                                    : 'Deal';

                                            final menuName =
                                                _s(menu?['name']).trim().isNotEmpty
                                                    ? _s(menu?['name']).trim()
                                                    : 'Menu Item';

                                            final itemTitle = (o.dealId != null)
                                                ? dealTitle
                                                : menuName;

                                            return _HistoryRow(
                                              title:
                                                  '$restaurantName • $itemTitle',
                                              subtitle: _fmtPretty(
                                                o.createdAt.toLocal(),
                                              ),
                                              isPlus: false,
                                              amount: '-${o.coinsPaid}',
                                            );
                                          },
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ✅ Info dot overlay (NOW you can move it further down safely)
            Positioned(
              right: 12,
              top: topInset + kToolbarHeight + 10, // ✅ more lower than before
              child: _InfoDotButtonTight(
                onTap: () => _showWalletInfo(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtPretty(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    String two(int v) => v.toString().padLeft(2, '0');
    final d = dt.day;
    final m = months[dt.month - 1];
    final y = dt.year;
    final hh = two(dt.hour);
    final mm = two(dt.minute);
    return '$d $m $y • $hh:$mm';
  }

  static String _prettyLedgerTitle(String type) {
    switch (type) {
      case 'signup_bonus':
        return 'Signup Bonus';
      case 'topup':
        return 'Top Up';
      case 'admin_mint':
        return 'Admin Top Up';
      case 'purchase_deal':
        return 'Deal Redeemed';
      case 'purchase_menu':
        return 'Menu Redeemed';
      case 'refund':
        return 'Refund';
      case 'spin_entry':
        return 'Spin Entry';
      default:
        return type;
    }
  }
}

/// ✅ tighter refresh icon
class _AppBarIconTight extends StatelessWidget {
  const _AppBarIconTight({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 34,
        height: 56, // ✅ make whole tap area appbar-friendly
        child: Center(
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

/// ✅ Info dot (no clipping now, because it's in body overlay)
class _InfoDotButtonTight extends StatelessWidget {
  const _InfoDotButtonTight({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0AA6C3),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.info_outline,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

/// =======================
/// Tab Button
/// =======================
class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = Colors.white.withAlpha((0.10 * 255).round());

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: active ? const Color(0xFF0AA6C3) : Colors.transparent,
            border: Border.all(color: active ? Colors.transparent : border),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.25 * 255).round()),
                      blurRadius: 14,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : const [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.white70,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelContainer extends StatelessWidget {
  final Widget child;
  const _PanelContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF060A13),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withAlpha((0.10 * 255).round()),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withAlpha((0.45 * 255).round()),
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

/// =======================
/// Balance Card
/// =======================
class _BalanceCard extends StatelessWidget {
  final String balance;
  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 182,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B2B45),
            Color(0xFF0A1F34),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.35 * 255).round()),
            blurRadius: 22,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        child: Row(
          children: [
            const _PremiumCoin(size: 96),
            const SizedBox(width: 18),
            Expanded(
              child: Center(
                child: Text(
                  balance,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =======================
/// Premium Coin
/// =======================
class _PremiumCoin extends StatelessWidget {
  final double size;
  const _PremiumCoin({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 6,
            child: Container(
              height: size * 0.82,
              width: size * 0.82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.28 * 255).round()),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: size,
            width: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment(-0.30, -0.35),
                radius: 0.95,
                colors: [
                  Color(0xFFFFF1A6),
                  Color(0xFFFFD05A),
                  Color(0xFFF2AF00),
                  Color(0xFFE19000),
                ],
                stops: [0.0, 0.45, 0.78, 1.0],
              ),
            ),
          ),
          Container(
            height: size * 0.92,
            width: size * 0.92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFB87400).withAlpha((0.60 * 255).round()),
                width: 2,
              ),
            ),
          ),
          Container(
            height: size * 0.72,
            width: size * 0.72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFD977),
                  Color(0xFFE6A200),
                ],
              ),
            ),
          ),
          Positioned(
            left: size * 0.18,
            top: size * 0.18,
            child: Container(
              height: size * 0.26,
              width: size * 0.26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withAlpha((0.40 * 255).round()),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Text(
            'M',
            style: TextStyle(
              color: const Color(0xFF8A5600),
              fontSize: size * 0.42,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
              shadows: [
                Shadow(
                  color: Colors.white.withAlpha((0.20 * 255).round()),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
                Shadow(
                  color: Colors.black.withAlpha((0.18 * 255).round()),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// Purchase Button (pill)
/// =======================
class _PurchaseButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _PurchaseButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF06C7D8),
                Color(0xFF0AA6C3),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.25 * 255).round()),
                blurRadius: 16,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'Get Mighty Points',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =======================
/// History Row
/// =======================
class _HistoryRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final bool isPlus;

  const _HistoryRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isPlus,
  });

  Color w(double a) => Colors.white.withAlpha((a * 255).round());

  @override
  Widget build(BuildContext context) {
    final accent = isPlus ? const Color(0xFF34E8B0) : const Color(0xFFFF6B6B);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF070B14),
        border: Border.all(
          color: Colors.white.withAlpha((0.06 * 255).round()),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withAlpha((0.16 * 255).round()),
            ),
            child: Icon(
              isPlus ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      height: 1.10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Transform.translate(
                    offset: const Offset(0, -1.5),
                    child: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: w(0.42),
                        fontSize: 12.1,
                        fontWeight: FontWeight.w600,
                        height: 1.00,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              amount,
              style: TextStyle(
                color: accent,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// Balance loading skeleton
/// =======================
class _BalanceSkeleton extends StatelessWidget {
  const _BalanceSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 182,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: Colors.white.withAlpha((0.06 * 255).round()),
        border: Border.all(
          color: Colors.white.withAlpha((0.08 * 255).round()),
        ),
      ),
      child: const Center(child: LinearProgressIndicator()),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
    );
  }
}

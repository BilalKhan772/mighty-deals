// apps/customer_app/lib/features/wallet/ui/wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logic/wallet_controller.dart';

/// =======================
/// Tabs state
/// =======================
enum WalletTab { topUp, orders }

final walletTabProvider = StateProvider<WalletTab>((ref) => WalletTab.topUp);

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  Color w(double a) => Colors.white.withAlpha((a * 255).round());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(myWalletProvider);
    final ledgerAsync = ref.watch(myLedgerProvider);
    final tab = ref.watch(walletTabProvider);

    // ✅ UI start a bit higher
    const double topGap = 28;

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
            onPressed: () {
              ref.invalidate(myWalletProvider);
              ref.invalidate(myLedgerProvider);
            },
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
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: topGap),

                    // ✅ Balance Card
                    walletAsync.when(
                      loading: () => const _BalanceSkeleton(),
                      error: (e, _) => Text(
                        e.toString(),
                        style: TextStyle(color: w(0.70)),
                        textAlign: TextAlign.center,
                      ),
                      data: (wallet) =>
                          _BalanceCard(balance: wallet.balance.toString()),
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
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
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
                            ? ledgerAsync.when(
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (e, _) => Center(
                                  child: Text(
                                    e.toString(),
                                    style: TextStyle(color: w(0.70)),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                data: (list) {
                                  if (list.isEmpty) {
                                    return const _EmptyState(
                                      text: 'No top ups yet',
                                    );
                                  }
                                  return ListView.separated(
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
                                        title: x.type,
                                        subtitle:
                                            _fmtPretty(x.createdAt.toLocal()),
                                        isPlus: isPlus,
                                        amount: amountText,
                                      );
                                    },
                                  );
                                },
                              )
                            : const _EmptyState(text: 'No orders yet'),
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
  }

  // ✅ clean format
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
}

/// =======================
/// Top Up / Orders Tab Button
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

/// =======================
/// Panel Container (same look as History box)
/// =======================
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

/// =======================
/// Empty State
/// =======================
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
/// Balance Card (match reference)
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
/// Premium Coin (3D metallic look, no assets)
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
/// History Row (✅ FIXED TIME ALIGNMENT)
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
        // ✅ IMPORTANT: start alignment (prevents weird vertical centering)
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // icon
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

          // title + time
          Expanded(
            child: Padding(
              // ✅ small top padding so text block aligns perfectly with icon
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

                  // ✅ Lift date slightly so it doesn't look "too low"
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

          // amount
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

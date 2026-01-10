import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_models/spin_entry_model.dart';
import 'package:shared_models/spin_model.dart';
import '../data/spins_functions_api.dart';
import '../data/spins_repo.dart';

class SpinDetailScreen extends StatefulWidget {
  final SpinModel spin;
  const SpinDetailScreen({super.key, required this.spin});

  @override
  State<SpinDetailScreen> createState() => _SpinDetailScreenState();
}

class _SpinDetailScreenState extends State<SpinDetailScreen>
    with TickerProviderStateMixin {
  final _repo = SpinsRepo();
  final _api = SpinsFunctionsApi();

  bool _loading = true;
  bool _joining = false;

  List<SpinEntryModel> _entries = [];
  int _totalCount = 0;

  Timer? _timer;
  Duration? _left;
  late SpinModel _spin;

  static const int _displayLimit = 50;
  static const int _hardLimit = 1000;

  Timer? _pollTimer;

  bool _winnerWasReady = false;
  bool _winnerFlowRunning = false;

  // ✅ New: If free slots become full (from API), disable Join Free like reg-closed
  bool _freeSlotsFull = false;

  // ✅ New: prevent "winner" showing on page before spin animation completes
  bool _revealInProgress = false;

  @override
  void initState() {
    super.initState();
    _spin = widget.spin;
    _startTimer();
    _loadAll();

    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_spin.status == 'finished') return;
      _loadAll(silent: true);
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final close = _spin.regCloseAt;
      if (close == null) return;
      final diff = close.difference(DateTime.now());
      if (!mounted) return;
      setState(() => _left = diff.isNegative ? Duration.zero : diff);
    });
  }

  bool get _regOpen {
    if (_spin.status != 'published') return false;
    final close = _spin.regCloseAt;
    if (close == null) return true;
    return DateTime.now().isBefore(close);
  }

  // ✅ ADD these helpers (below _regOpen)
  String get _todayCode {
    const map = {
      DateTime.monday: 'mon',
      DateTime.tuesday: 'tue',
      DateTime.wednesday: 'wed',
      DateTime.thursday: 'thu',
      DateTime.friday: 'fri',
      DateTime.saturday: 'sat',
      DateTime.sunday: 'sun',
    };
    return map[DateTime.now().weekday]!;
  }

  bool get _todayAllowedFree {
    final today = _todayCode.toLowerCase();
    final days = _spin.freeDays.map((e) => e.toLowerCase()).toList();
    return _spin.freeEnabled && days.contains(today);
  }

  // 🔁 REPLACE _canJoinFree
  bool get _canJoinFree =>
      !_joining &&
      _regOpen &&
      _spin.freeEnabled &&
      _spin.freeSlots > 0 &&
      _todayAllowedFree &&
      !_freeSlotsFull;

  bool get _canJoinPaid => !_joining && _regOpen;

  String _leftTextShort() {
    final d = _left;
    if (d == null) return '';
    if (d == Duration.zero) return 'Closed';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _friendlyError(String raw) {
    final m = raw.toUpperCase();

    if (m.contains('FREE_SLOTS_FULL')) return 'Free slots are full.';
    if (m.contains('FREE_NOT_AVAILABLE')) {
      return 'Free not available today.';
    }
    if (m.contains('ALREADY_JOINED_FREE')) return 'You already joined free.';
    if (m.contains('TOTAL_SLOTS_FULL')) return 'This spin is full.';
    if (m.contains('REG_CLOSED')) return 'Registration is closed.';
    if (m.contains('REG_NOT_STARTED')) {
      return 'Registration has not started yet.';
    }
    if (m.contains('SPIN_NOT_OPEN')) return 'Spin is not open.';
    if (m.contains('INSUFFICIENT_BALANCE')) {
      return 'Insufficient Mighty balance.';
    }
    if (m.contains('UNAUTHORIZED')) return 'Please login again.';

    if (m.contains('FUNCTIONEXCEPTION') || m.contains('RPC_ERROR')) {
      return 'Something went wrong. Please try again.';
    }
    return raw;
  }

  Future<void> _loadAll({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);

    try {
      final latestSpin = await _repo.getSpinById(_spin.id);
      final total = await _repo.participantsCount(_spin.id);
      final entries = await _repo.participants(_spin.id, limit: _displayLimit);

      if (!mounted) return;

      final prevWinnerReady =
          _spin.status == 'finished' && _spin.displayWinnerCode.isNotEmpty;

      final nextSpin = latestSpin ?? _spin;

      final nextWinnerReady =
          nextSpin.status == 'finished' && nextSpin.displayWinnerCode.isNotEmpty;

      setState(() {
        _spin = nextSpin;
        _totalCount = total;
        _entries = entries;
        _loading = false;
      });

      // ✅ Winner just became available -> spin animation first, then reveal
      if (!prevWinnerReady &&
          nextWinnerReady &&
          !_winnerWasReady &&
          !_winnerFlowRunning) {
        _winnerWasReady = true;
        _winnerFlowRunning = true;

        if (mounted) {
          setState(() => _revealInProgress = true);
          await _showSpinThenReveal(nextSpin.displayWinnerCode);
          if (mounted) setState(() => _revealInProgress = false);
        }

        _winnerFlowRunning = false;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _join({required bool paid}) async {
    if (!_regOpen) return;

    setState(() => _joining = true);

    try {
      final res = paid
          ? await _api.joinPaid(spinId: _spin.id)
          : await _api.joinFree(spinId: _spin.id);

      if ((res['ok'] == true)) {
        // ✅ if joined free successfully, clear "full" state
        if (!paid && mounted) setState(() => _freeSlotsFull = false);

        await _loadAll();
        if (mounted) _toast(paid ? 'Joined with Mighty ✅' : 'Joined FREE ✅');
      } else {
        final err = (res['error'] ?? 'Unknown').toString();
        final friendly = _friendlyError(err);

        // ✅ if free slots are full -> disable Join Free like reg-closed
        if (!paid && err.toUpperCase().contains('FREE_SLOTS_FULL')) {
          if (mounted) setState(() => _freeSlotsFull = true);
        }

        if (mounted) _toast(friendly);
      }
    } catch (e) {
      final friendly = _friendlyError(e.toString());

      if (!paid && e.toString().toUpperCase().contains('FREE_SLOTS_FULL')) {
        if (mounted) setState(() => _freeSlotsFull = true);
      }

      if (mounted) _toast(friendly);
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _showSpinThenReveal(String winnerCode) async {
    if (!mounted) return;

    // 1) lottie spin for 10s (full opaque background)
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (_) => const _FullScreenOpaqueDialog(
        dismissOnTap: false,
        child: _SpinLottieDialog(),
      ),
    );

    // 2) reveal winner (tap anywhere to close)
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (_) => _FullScreenOpaqueDialog(
        dismissOnTap: true, // ✅ tap anywhere closes
        child: _WinnerRevealDialog(winnerText: winnerCode),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final winnerReady =
        _spin.status == 'finished' && _spin.displayWinnerCode.isNotEmpty;

    // track initial winner state
    _winnerWasReady = _winnerWasReady || winnerReady;

    // ✅ If reveal flow is running, don't show winner card behind it
    final showWinnerCard = winnerReady && !_revealInProgress;

    // 🔁 REPLACE freeDisabledReason logic
    String? freeDisabledReason;
    if (!_regOpen) {
      freeDisabledReason = 'Registration is closed.';
    } else if (!_spin.freeEnabled) {
      // ✅ CHANGED: paid spin pe ye msg aata tha, ab new msg
      freeDisabledReason = 'No free slots available.';
    } else if (_spin.freeSlots <= 0 || _freeSlotsFull) {
      freeDisabledReason = 'Free slots are full.';
    } else if (!_todayAllowedFree) {
      freeDisabledReason =
          'Free available on: ${_spin.freeDays.map((e) => e.toUpperCase()).join(', ')}';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050A14),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Mighty Spin',
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(onPressed: () => _loadAll(), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Stack(
        children: [
          const _PlainDarkBackground(),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
            children: [
              _DealsLikeCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _spin.dealText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _MiniChip(icon: Icons.location_city, text: _spin.city),
                        _MiniChip(
                          icon: Icons.timer,
                          text: _spin.regCloseAt != null ? _leftTextShort() : 'No limit',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (showWinnerCard) ...[
                      _WinnerCard(winnerText: _spin.displayWinnerCode),
                    ] else if (!winnerReady) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _PrimaryButton(
                              text: 'Join Free',
                              loading: _joining,
                              onTap: _canJoinFree ? () => _join(paid: false) : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PrimaryButton(
                              text: 'Join (${_spin.paidCostPerSlot} Mighty)',
                              loading: _joining,
                              onTap: _canJoinPaid ? () => _join(paid: true) : null,
                            ),
                          ),
                        ],
                      ),

                      if (!_canJoinFree && freeDisabledReason != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          freeDisabledReason,
                          style: TextStyle(color: Colors.white.withOpacity(0.70)),
                        ),
                      ],

                      // ✅ FIX: duplicate "Registration is closed." remove (now only once)
                      // (freeDisabledReason already shows it when !_regOpen)
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _DealsLikeCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Participants',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '$_totalCount / $_hardLimit',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(18),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_entries.isEmpty)
                      Text(
                        'No participants yet.',
                        style: TextStyle(color: Colors.white.withOpacity(0.75)),
                      )
                    else ...[
                      Text(
                        'Showing latest $_displayLimit',
                        style: TextStyle(color: Colors.white.withOpacity(0.60)),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _entries
                            .take(_displayLimit)
                            .map((e) => _Pill(text: e.displayUserCode))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool loading;

  const _PrimaryButton({
    required this.text,
    required this.onTap,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null || loading;

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF10B7C7), Color(0xFF0B7C9D)],
            ),
          ),
          child: loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFD6F3FF),
                  ),
                )
              : Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFD6F3FF),
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WinnerCard extends StatelessWidget {
  final String winnerText;
  const _WinnerCard({required this.winnerText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.amber.withOpacity(0.12),
        border: Border.all(color: Colors.amber.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events, color: Colors.amber.withOpacity(0.95), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Winner!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  winnerText,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'See you next time',
                  style: TextStyle(color: Colors.white.withOpacity(0.75)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ✅ FULL-SCREEN opaque cover (and optional tap-to-close)
class _FullScreenOpaqueDialog extends StatelessWidget {
  final Widget child;
  final bool dismissOnTap;
  const _FullScreenOpaqueDialog({
    required this.child,
    required this.dismissOnTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF050A14),
      child: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: dismissOnTap ? () => Navigator.pop(context) : null,
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// ✅ Lottie spinner dialog (NOW 10s)  ✅
class _SpinLottieDialog extends StatefulWidget {
  const _SpinLottieDialog();

  @override
  State<_SpinLottieDialog> createState() => _SpinLottieDialogState();
}

class _SpinLottieDialogState extends State<_SpinLottieDialog> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(seconds: 10), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _GlassOverlay(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: Lottie.asset(
              'assets/lottie/spin.json',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Spinning...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.90),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Winner is being selected',
            style: TextStyle(
              color: Colors.white.withOpacity(0.70),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassOverlay extends StatelessWidget {
  final Widget child;
  const _GlassOverlay({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white.withOpacity(0.12),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
          boxShadow: [
            BoxShadow(
              blurRadius: 28,
              offset: const Offset(0, 14),
              color: Colors.black.withOpacity(0.45),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _WinnerRevealDialog extends StatefulWidget {
  final String winnerText;
  const _WinnerRevealDialog({required this.winnerText});

  @override
  State<_WinnerRevealDialog> createState() => _WinnerRevealDialogState();
}

class _WinnerRevealDialogState extends State<_WinnerRevealDialog>
    with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);

  late final Animation<double> _scale =
      Tween<double>(begin: 0.94, end: 1.0).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
  );

  late final AnimationController _particles = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    _particles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 320,
                height: 320,
                child: AnimatedBuilder(
                  animation: _particles,
                  builder: (_, __) => CustomPaint(
                    painter: _ConfettiPainter(t: _particles.value),
                  ),
                ),
              ),
              Container(
                width: 320,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Colors.white.withOpacity(0.14),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                      color: Colors.black.withOpacity(0.45),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: cs.primary.withOpacity(0.35)),
                        color: cs.primary.withOpacity(0.12),
                      ),
                      child: const Text(
                        '🎉 Winner Selected',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.winnerText,
                      style: const TextStyle(
                          fontSize: 34, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Congrats! Enjoy your deal.',
                      style: TextStyle(color: Colors.white.withOpacity(0.75)),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Awesome ✅'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap anywhere to close',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  _ConfettiPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(7);
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 60; i++) {
      final a = rnd.nextDouble() * pi * 2;
      final r = (rnd.nextDouble() * 0.45 + 0.15) * size.width;
      final drift = (t * 1.8) % 1.0;
      final dx = cos(a) * r * drift;
      final dy = sin(a) * r * drift;

      final p = center + Offset(dx, dy);
      final s = rnd.nextDouble() * 3 + 2;

      final paint = Paint()
        ..color = Colors.white.withOpacity(0.18 + rnd.nextDouble() * 0.18)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(p, s, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.t != t;
}

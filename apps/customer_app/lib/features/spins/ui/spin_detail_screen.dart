import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_models/spin_model.dart';
import 'package:shared_models/spin_entry_model.dart';
import '../data/spins_repo.dart';
import '../data/spins_functions_api.dart';

class SpinDetailScreen extends StatefulWidget {
  final SpinModel spin;
  const SpinDetailScreen({super.key, required this.spin});

  @override
  State<SpinDetailScreen> createState() => _SpinDetailScreenState();
}

class _SpinDetailScreenState extends State<SpinDetailScreen> {
  final _repo = SpinsRepo();
  final _api = SpinsFunctionsApi();

  bool _loading = true;
  bool _joining = false;
  List<SpinEntryModel> _entries = [];
  int _totalCount = 0; // ✅ NEW
  Timer? _timer;
  Duration? _left;
  late SpinModel _spin;

  static const int _displayLimit = 50; // ✅ NEW
  static const int _hardLimit = 1000;  // ✅ NEW

  @override
  void initState() {
    super.initState();
    _spin = widget.spin;
    _startTimer();
    _loadAll();
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

  bool get _isWeekday {
    final d = DateTime.now().weekday; // Mon=1..Sun=7
    return d >= 1 && d <= 5;
  }

  bool get _regOpen {
    if (_spin.status != 'published') return false;
    final close = _spin.regCloseAt;
    if (close == null) return true;
    return DateTime.now().isBefore(close);
  }

  String _leftText() {
    final d = _left;
    if (d == null) return '';
    if (d == Duration.zero) return 'Registration closed';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    return '${m}m ${s}s';
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      // 1) refresh spin (winner/status)
      final latestSpin = await _repo.getSpinById(_spin.id);

      // ✅ 2) total participants count (RPC)
      final total = await _repo.participantsCount(_spin.id);

      // 3) latest participants (limit)
      final entries = await _repo.participants(_spin.id, limit: _displayLimit);

      if (!mounted) return;
      setState(() {
        if (latestSpin != null) _spin = latestSpin;
        _totalCount = total;
        _entries = entries;
        _loading = false;
      });
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
        await _loadAll();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(paid ? 'Joined with Mighty ✅' : 'Joined FREE ✅')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${res['error'] ?? 'Unknown'}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final winnerReady = _spin.status == 'finished' && _spin.displayWinnerCode.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mighty Spin'),
        actions: [
          IconButton(onPressed: _loadAll, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_spin.dealText, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('City: ${_spin.city}'),
          const SizedBox(height: 8),
          if (_spin.regCloseAt != null) Text('Register ends in: ${_leftText()}'),
          const SizedBox(height: 16),

          if (winnerReady) ...[
            _WinnerCard(winnerText: _spin.displayWinnerCode),
            const SizedBox(height: 16),
          ] else ...[
            ElevatedButton(
              onPressed: (!_joining && _regOpen && _isWeekday) ? () => _join(paid: false) : null,
              child: const Text('Join Spin (Free)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: (!_joining && _regOpen) ? () => _join(paid: true) : null,
              child: Text('Use Mighty to Join (${_spin.paidCostPerSlot} Mighty)'),
            ),
            if (!_isWeekday) ...[
              const SizedBox(height: 8),
              Text(
                'Free option is only available on weekdays (Mon–Fri).',
                style: TextStyle(color: Colors.black.withOpacity(0.6)),
              ),
            ],
            if (!_regOpen) ...[
              const SizedBox(height: 8),
              Text(
                'Registration is closed.',
                style: TextStyle(color: Colors.black.withOpacity(0.6)),
              ),
            ],
            const SizedBox(height: 16),
          ],

          // ✅ Participants header with total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Participants', style: Theme.of(context).textTheme.titleLarge),
              Text(
                '$_totalCount / $_hardLimit',
                style: TextStyle(color: Colors.black.withOpacity(0.7)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_entries.isEmpty)
            const Text('No participants yet.')
          else ...[
            Text(
              'Showing latest $_displayLimit',
              style: TextStyle(color: Colors.black.withOpacity(0.6)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _entries.take(_displayLimit).map((e) => _Pill(text: e.displayUserCode)).toList(),
            ),
          ],
        ],
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
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Text(text),
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
        color: Colors.amber.withOpacity(0.15),
        border: Border.all(color: Colors.amber.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text('Winner!', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          Text(winnerText, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('See you next week'),
        ],
      ),
    );
  }
}

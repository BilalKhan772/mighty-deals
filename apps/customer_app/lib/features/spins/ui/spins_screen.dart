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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // get user's city from profiles (safe: user can read own profile)
    final uid = SB.client.auth.currentUser?.id;
    if (uid == null) {
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
      setState(() {
        _loading = false;
        _city = null;
        _spins = [];
      });
      return;
    }

    final spins = await _repo.listForCity(city);

    setState(() {
      _loading = false;
      _city = city;
      _spins = spins;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mighty Spin'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _city == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Please set your City in Profile to see spins.'),
                  ),
                )
              : _spins.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('No spins available for $_city right now.'),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _spins.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final s = _spins[i];
                        return _SpinCard(
                          spin: s,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => SpinDetailScreen(spin: s)),
                            );
                            // refresh after returning
                            await _load();
                          },
                        );
                      },
                    ),
    );
  }
}

class _SpinCard extends StatelessWidget {
  final SpinModel spin;
  final VoidCallback onTap;

  const _SpinCard({required this.spin, required this.onTap});

  String _timeLeftText(SpinModel s) {
    final close = s.regCloseAt;
    if (close == null) return '';
    final diff = close.difference(DateTime.now());
    if (diff.isNegative) return 'Registration closed';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h > 0) return 'Register ends in ${h}h ${m}m';
    return 'Register ends in ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final ends = _timeLeftText(spin);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mighty Spin', style: Theme.of(context).textTheme.titleLarge),
            if (ends.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(ends, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
              ),
              child: Text(spin.dealText, style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 10),
            Text('City: ${spin.city} • Free slots: ${spin.freeSlots} • Cost: ${spin.paidCostPerSlot} Mighty'),
            if (spin.status == 'finished' && (spin.winnerCode ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Winner: ${spin.displayWinnerCode}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }
}

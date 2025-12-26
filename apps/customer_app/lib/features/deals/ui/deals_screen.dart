import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/deals_controller.dart';

// Minimal debouncer
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
    'Street',
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
      appBar: AppBar(title: const Text('Deals')),
      body: Column(
        children: [
          // ---------------- Search ----------------
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search restaurant name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                          ref.read(dealsControllerProvider.notifier).setSearch('');
                        },
                      ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) {
                setState(() {});
                _debouncer.run(() {
                  ref.read(dealsControllerProvider.notifier).setSearch(v.trim());
                });
              },
            ),
          ),

          // ---------------- Category Chips ----------------
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = _categories[i];
                final selected = query.category == c;
                return ChoiceChip(
                  label: Text(c),
                  selected: selected,
                  onSelected: (_) =>
                      ref.read(dealsControllerProvider.notifier).setCategory(c),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // ---------------- City gate + List ----------------
          Expanded(
            child: cityAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (city) {
                final c = city.trim();
                if (c.isEmpty) {
                  return const Center(
                    child: Text('Please set your city in Profile first.'),
                  );
                }

                return dealsStateAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text(e.toString())),
                  data: (state) {
                    return RefreshIndicator(
                      onRefresh: () =>
                          ref.read(dealsControllerProvider.notifier).refresh(),
                      child: state.items.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 120),
                                Center(child: Text('No deals found')),
                              ],
                            )
                          : ListView.separated(
                              controller: _scroll,
                              itemCount: state.items.length + 1,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                if (i == state.items.length) {
                                  if (state.isLoadingMore) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  if (!state.hasMore) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child:
                                          Center(child: Text('No more deals')),
                                    );
                                  }
                                  return const SizedBox(height: 16);
                                }

                                final d = state.items[i];
                                final r = d.restaurant;
                                final restaurantName =
                                    (r?['name'] as String?) ?? '';

                                return ListTile(
                                  title: Text(d.title),
                                  subtitle: Text(
                                    '${restaurantName.isEmpty ? '' : '$restaurantName • '}${d.category} • ${d.priceMighty} Mighty',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Open deal: ${d.title}'),
                                      ),
                                    );
                                  },
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
    );
  }
}

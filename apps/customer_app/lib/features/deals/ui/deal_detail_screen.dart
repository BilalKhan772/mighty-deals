import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/deals_controller.dart';

class DealDetailScreen extends ConsumerWidget {
  final String dealId;
  const DealDetailScreen({super.key, required this.dealId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsStateAsync = ref.watch(dealsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Deal Detail')),
      body: dealsStateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (state) {
          final list = state.items;
          final d = list.firstWhere(
            (x) => x.id == dealId,
            orElse: () => throw Exception('Deal not found'),
          );

          final r = d.restaurant ?? {};
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(d.description ?? ''),
                const SizedBox(height: 12),
                Text('Restaurant: ${r['name'] ?? ''}'),
                Text('Price: ${d.priceMighty} Mighty'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pay with Mighty will be added via Edge Function next.'),
                      ),
                    );
                  },
                  child: const Text('Pay with Mighty'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

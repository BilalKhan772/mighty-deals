import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/deals_controller.dart';

class DealsScreen extends ConsumerWidget {
  const DealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsAsync = ref.watch(dealsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deals'),
      ),
      body: dealsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (deals) {
          if (deals.isEmpty) {
            return const Center(child: Text('No deals found'));
          }

          return ListView.separated(
            itemCount: deals.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final d = deals[i];
              return ListTile(
                title: Text(d.title),
                subtitle: Text('${d.category} • ${d.priceMighty} Mighty'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Later: open deal_detail_screen.dart with router
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Open deal: ${d.title}')),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

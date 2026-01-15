import 'package:flutter/material.dart';
import 'package:shared_models/order_model.dart';

import '../data/orders_repo.dart';
import '../logic/orders_controller.dart';
import 'widgets/orders_table.dart';

class OrdersScreen extends StatefulWidget {
  static const route = '/orders';
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late final AdminOrdersController controller;

  @override
  void initState() {
    super.initState();
    controller = AdminOrdersController(AdminOrdersRepo());
    controller.refresh();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _openDetail(OrderModel o) async {
    final userCode = controller.uniqueCodeFor(o.userId);

    String itemName() {
      final deal = o.deal;
      if (deal != null) return (deal['title'] as String?) ?? '(Deal)';
      final menu = o.menuItem;
      if (menu != null) return (menu['name'] as String?) ?? '(Menu Item)';
      return '(Unknown item)';
    }

    String restaurantName() {
      return (o.restaurant?['name'] as String?) ?? '(Restaurant)';
    }

    String? restaurantPhone() => o.restaurant?['phone'] as String?;
    String? restaurantWhatsApp() => o.restaurant?['whatsapp'] as String?;

    String fmt(DateTime dt) {
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$y-$m-$d  $hh:$mm';
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Order Details'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kv('Order ID', o.id),
                  _kv('Created At', fmt(o.createdAt.toLocal())),
                  const Divider(),
                  _kv('Customer Unique ID', userCode),
                  _kv('Customer Phone', o.phone ?? ''),
                  _kv('Customer WhatsApp', o.whatsapp ?? ''),
                  _kv('Customer Address', o.address ?? ''),
                  _kv('Customer City', o.city ?? ''),
                  const Divider(),
                  _kv('Restaurant', restaurantName()),
                  _kv('Restaurant Phone', restaurantPhone() ?? ''),
                  _kv('Restaurant WhatsApp', restaurantWhatsApp() ?? ''),
                  const Divider(),
                  _kv('Item', itemName()),
                  _kv('Coins Paid', '${o.coinsPaid}'),
                  _kv('Status', o.status),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await controller.markPending(o.id);
              },
              child: const Text('Mark Pending'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await controller.markCancelled(o.id);
              },
              child: const Text('Mark Cancelled'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await controller.markDone(o.id);
              },
              child: const Text('Mark Done'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await _confirm(
                  context,
                  'Delete this order?',
                  'This will permanently delete the order record.',
                );
                if (ok) await controller.deleteOrder(o.id);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _confirm(BuildContext context, String title, String msg) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Orders'),
            actions: [
              IconButton(
                onPressed: controller.refresh,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _FiltersBar(
                  status: controller.statusFilter,
                  city: controller.cityFilter,
                  onStatusChanged: (v) => controller.setStatusFilter(v),
                  onCityChanged: (v) => controller.setCityFilter(v),
                ),
                const SizedBox(height: 12),
                if (controller.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline),
                        const SizedBox(width: 8),
                        Expanded(child: Text(controller.error!)),
                      ],
                    ),
                  ),
                Expanded(
                  child: Stack(
                    children: [
                      OrdersTable(
                        orders: controller.orders,
                        uniqueCodeFor: controller.uniqueCodeFor,
                        onOpenDetail: _openDetail,
                      ),
                      if (controller.isLoading && controller.orders.isEmpty)
                        const Center(child: CircularProgressIndicator()),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ✅ mobile-friendly bottom bar too (Wrap)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 520;

                    final leftText = Text(
                      'Showing: ${controller.orders.length}'
                      '${controller.hasMore ? '' : ' (end)'}',
                    );

                    final btn = ElevatedButton.icon(
                      onPressed: (controller.isLoading || !controller.hasMore)
                          ? null
                          : controller.loadMore,
                      icon: const Icon(Icons.expand_more),
                      label: const Text('Load More'),
                    );

                    if (!isNarrow) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [leftText, btn],
                      );
                    }

                    return Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        leftText,
                        btn,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ✅ UPDATED Filters bar (FULL)
class _FiltersBar extends StatefulWidget {
  final String? status;
  final String? city;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onCityChanged;

  const _FiltersBar({
    required this.status,
    required this.city,
    required this.onStatusChanged,
    required this.onCityChanged,
  });

  @override
  State<_FiltersBar> createState() => _FiltersBarState();
}

class _FiltersBarState extends State<_FiltersBar> {
  late final TextEditingController _cityCtrl;

  @override
  void initState() {
    super.initState();
    _cityCtrl = TextEditingController(text: widget.city ?? '');
  }

  @override
  void didUpdateWidget(covariant _FiltersBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.city != widget.city) {
      _cityCtrl.text = widget.city ?? '';
    }
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            const Text('Status:'),
            DropdownButton<String>(
              value: widget.status,
              hint: const Text('All'),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('pending')),
                DropdownMenuItem(value: 'done', child: Text('done')),
                DropdownMenuItem(value: 'cancelled', child: Text('cancelled')),
              ],
              onChanged: widget.onStatusChanged,
            ),
            TextButton(
              onPressed: () => widget.onStatusChanged(null),
              child: const Text('Clear'),
            ),
            const SizedBox(width: 8),
            const Text('City:'),
            SizedBox(
              width: isNarrow
                  ? (constraints.maxWidth - 40).clamp(180, 420)
                  : 220,
              child: TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'e.g. Karachi',
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (v) =>
                    widget.onCityChanged(v.trim().isEmpty ? null : v.trim()),
              ),
            ),
            TextButton(
              onPressed: () {
                _cityCtrl.clear();
                widget.onCityChanged(null);
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }
}

Widget _kv(String k, String v) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(
            k,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(v.isEmpty ? '-' : v)),
      ],
    ),
  );
}

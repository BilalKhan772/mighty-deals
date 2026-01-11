import 'package:flutter/material.dart';
import 'package:shared_models/order_model.dart';

class OrdersTable extends StatelessWidget {
  final List<OrderModel> orders;
  final String Function(String userId) uniqueCodeFor;
  final void Function(OrderModel order) onOpenDetail;

  const OrdersTable({
    super.key,
    required this.orders,
    required this.uniqueCodeFor,
    required this.onOpenDetail,
  });

  String _titleFromOrder(OrderModel o) {
    final deal = o.deal;
    if (deal != null) return (deal['title'] as String?) ?? '(Deal)';
    final menu = o.menuItem;
    if (menu != null) return (menu['name'] as String?) ?? '(Menu Item)';
    return '(Unknown item)';
  }

  String _restaurantName(OrderModel o) {
    final r = o.restaurant;
    return (r?['name'] as String?) ?? '(Restaurant)';
  }

  String _fmtDateTime(DateTime dt) {
    // simple readable format
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d  $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: Text('No orders found'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 44,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 64,
        columns: const [
          DataColumn(label: Text('Time')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Coins')),
          DataColumn(label: Text('Customer')),
          DataColumn(label: Text('Restaurant')),
          DataColumn(label: Text('Item')),
          DataColumn(label: Text('City')),
          DataColumn(label: Text('Open')),
        ],
        rows: orders.map((o) {
          final userCode = uniqueCodeFor(o.userId);
          final time = _fmtDateTime(o.createdAt.toLocal());
          final rest = _restaurantName(o);
          final item = _titleFromOrder(o);

          return DataRow(
            cells: [
              DataCell(Text(time)),
              DataCell(_StatusChip(status: o.status)),
              DataCell(Text('${o.coinsPaid}')),
              DataCell(Text(userCode)),
              DataCell(Text(rest)),
              DataCell(
                SizedBox(
                  width: 240,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ),
              ),
              DataCell(Text((o.restaurant?['city'] as String?) ?? '')),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => onOpenDetail(o),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final label = s.isEmpty ? 'pending' : s;
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

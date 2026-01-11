import 'package:flutter/foundation.dart';
import 'package:shared_models/order_model.dart';
import '../data/orders_repo.dart';

class AdminOrdersController extends ChangeNotifier {
  final AdminOrdersRepo _repo;

  AdminOrdersController(this._repo);

  bool isLoading = false;
  String? error;

  final List<OrderModel> orders = [];
  Map<String, String> uniqueCodeByUserId = {};

  // Filters
  String? statusFilter; // pending/done/cancelled
  String? cityFilter;

  // Pagination
  int _offset = 0;
  static const int _limit = 50;
  bool hasMore = true;

  Future<void> refresh() async {
    _offset = 0;
    hasMore = true;
    orders.clear();
    uniqueCodeByUserId = {};
    error = null;
    notifyListeners();
    await loadMore();
  }

  Future<void> loadMore() async {
    if (isLoading || !hasMore) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final batch = await _repo.listOrders(
        limit: _limit,
        offset: _offset,
        status: statusFilter,
        city: cityFilter,
      );

      if (batch.isEmpty) {
        hasMore = false;
      } else {
        orders.addAll(batch);
        _offset += batch.length;

        // Fetch unique codes for any missing user ids (batched)
        final missingUserIds = orders
            .map((o) => o.userId)
            .where((id) => !uniqueCodeByUserId.containsKey(id))
            .toSet()
            .toList();

        if (missingUserIds.isNotEmpty) {
          final codes = await _repo.fetchUniqueCodes(missingUserIds);
          uniqueCodeByUserId.addAll(codes);
        }
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String uniqueCodeFor(String userId) {
    final c = uniqueCodeByUserId[userId];
    if (c == null || c.isEmpty) return '(no code)';
    return c;
  }

  Future<void> setStatusFilter(String? status) async {
    statusFilter = (status == null || status.isEmpty) ? null : status;
    await refresh();
  }

  Future<void> setCityFilter(String? city) async {
    cityFilter = (city == null || city.isEmpty) ? null : city;
    await refresh();
  }

  Future<void> markDone(String orderId) async {
    await _repo.updateOrderStatus(orderId: orderId, status: 'done');
    await refresh();
  }

  Future<void> markCancelled(String orderId) async {
    await _repo.updateOrderStatus(orderId: orderId, status: 'cancelled');
    await refresh();
  }

  Future<void> markPending(String orderId) async {
    await _repo.updateOrderStatus(orderId: orderId, status: 'pending');
    await refresh();
  }

  Future<void> deleteOrder(String orderId) async {
    await _repo.deleteOrder(orderId);
    await refresh();
  }
}

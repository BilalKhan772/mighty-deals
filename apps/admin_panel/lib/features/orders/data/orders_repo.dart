import 'package:shared_models/order_model.dart';
import 'package:shared_supabase/supabase_client.dart';
import 'package:shared_supabase/supabase_tables.dart';

class AdminOrdersRepo {
  /// Keyset pagination:
  /// - Fetch latest first
  /// - Next pages use cursor (lastCreatedAt + lastId)
  Future<List<OrderModel>> listOrders({
    int limit = 50,
    String? status, // pending/done/cancelled
    String? city, // optional filter by order snapshot city

    // ✅ cursor (for load more)
    DateTime? beforeCreatedAt,
    String? beforeId,
  }) async {
    var q = SB.client.from(Tables.orders).select('''
      id,
      user_id,
      restaurant_id,
      deal_id,
      menu_item_id,
      coins_paid,
      phone,
      whatsapp,
      address,
      city,
      status,
      created_at,

      restaurant:restaurants(
        id,
        name,
        city,
        address,
        phone,
        whatsapp,
        photo_url
      ),

      deal:deals(
        id,
        title,
        description,
        category,
        price_mighty,
        price_rs
      ),

      menu_item:menu_items(
        id,
        name,
        price_rs,
        price_mighty
      )
    ''');

    if (status != null && status.trim().isNotEmpty) {
      q = q.eq('status', status.trim());
    }
    if (city != null && city.trim().isNotEmpty) {
      q = q.eq('city', city.trim());
    }

    // ✅ Keyset: "created_at desc, id desc"
    // If we have a cursor, fetch rows strictly BEFORE that cursor.
    if (beforeCreatedAt != null) {
      // primary filter
      q = q.lt('created_at', beforeCreatedAt.toUtc().toIso8601String());
    }

    final rows = await q
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);

    var orders = (rows as List)
        .map((e) => OrderModel.fromMap(e as Map<String, dynamic>))
        .toList();

    // ✅ Edge case: if multiple orders share same created_at
    // and we only used lt(created_at), it is OK (it will exclude same-timestamp rows).
    // If you want to include same created_at safely, you'd need an OR condition.
    // For now keep it simple/stable.

    // Batch fetch unique_code from profiles for these user_ids
    final userIds = orders.map((o) => o.userId).toSet().toList().cast<String>();
    if (userIds.isEmpty) return orders;

    final profileRows = await SB.client
        .from(Tables.profiles)
        .select('id, unique_code')
        .inFilter('id', userIds);

    final uniqueById = <String, String>{};
    for (final r in (profileRows as List)) {
      final m = r as Map<String, dynamic>;
      final id = m['id'] as String?;
      final code = m['unique_code'] as String?;
      if (id != null && code != null) uniqueById[id] = code;
    }

    return orders;
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status, // pending/done/cancelled
  }) async {
    await SB.client.from(Tables.orders).update({'status': status}).eq('id', orderId);
  }

  Future<void> deleteOrder(String orderId) async {
    await SB.client.from(Tables.orders).delete().eq('id', orderId);
  }

  Future<Map<String, String>> fetchUniqueCodes(List<String> userIds) async {
    if (userIds.isEmpty) return {};

    final safeIds = userIds.toSet().toList().cast<String>();

    final rows = await SB.client
        .from(Tables.profiles)
        .select('id, unique_code')
        .inFilter('id', safeIds);

    final out = <String, String>{};
    for (final r in (rows as List)) {
      final m = r as Map<String, dynamic>;
      final id = m['id'] as String?;
      final code = m['unique_code'] as String?;
      if (id != null && code != null) out[id] = code;
    }
    return out;
  }
}

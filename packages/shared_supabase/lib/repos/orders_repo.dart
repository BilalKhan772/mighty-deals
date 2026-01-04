import 'package:shared_models/order_model.dart';
import '../supabase_client.dart';
import '../supabase_tables.dart';
import '../edge/edge_functions.dart';

class OrdersRepoSB {
  Future<Map<String, dynamic>> createOrderAndDeductCoins({
    String? dealId,
    String? menuItemId,
  }) {
    return EdgeFunctions.call(
      'create_order_and_deduct_coins',
      body: {
        if (dealId != null) 'deal_id': dealId,
        if (menuItemId != null) 'menu_item_id': menuItemId,
      },
    );
  }

  /// SAFE: no embedded joins (avoids RLS recursion)
  Future<List<OrderModel>> listMyOrders({int limit = 50}) async {
    final rows = await SB.client
        .from(Tables.orders)
        .select('''
          id,
          user_id,
          restaurant_id,
          deal_id,
          menu_item_id,
          coins_paid,
          status,
          created_at
        ''')
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List)
        .map((e) => OrderModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}

import 'package:shared_models/restaurant_model.dart';
import '../supabase_client.dart';
import '../supabase_tables.dart';

class RestaurantsRepo {
  Future<RestaurantModel> getRestaurant(String id) async {
    final data = await SB.client
        .from(Tables.restaurants)
        .select()
        .eq('id', id)
        .eq('is_deleted', false)
        .single();

    return RestaurantModel.fromMap(data);
  }

  Future<List<Map<String, dynamic>>> listMenuItems(String restaurantId) async {
    final rows = await SB.client
        .from(Tables.menuItems)
        .select('id, restaurant_id, name, price_rs, is_active')
        .eq('restaurant_id', restaurantId)
        .eq('is_deleted', false)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (rows as List).cast<Map<String, dynamic>>();
  }
}

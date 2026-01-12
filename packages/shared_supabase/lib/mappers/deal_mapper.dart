import 'package:shared_models/deal_model.dart';

class DealMapper {
  static DealModel fromRow(Map<String, dynamic> row) {
    // Supabase join can return restaurant under different keys.
    // We'll normalize: restaurant -> Map
    final restaurant = (row['restaurant'] is Map<String, dynamic>)
        ? row['restaurant'] as Map<String, dynamic>
        : (row['restaurants'] is Map<String, dynamic>)
            ? row['restaurants'] as Map<String, dynamic>
            : (row['restaurant_id'] is Map<String, dynamic>)
                ? row['restaurant_id'] as Map<String, dynamic>
                : null;

    // Ensure restaurant includes id if missing
    Map<String, dynamic>? normalizedRestaurant;
    if (restaurant != null) {
      normalizedRestaurant = Map<String, dynamic>.from(restaurant);
      normalizedRestaurant['id'] ??= row['restaurant_id'];
    }

    final normalizedRow = Map<String, dynamic>.from(row);
    normalizedRow['restaurant'] = normalizedRestaurant;

    return DealModel.fromMap(normalizedRow);
  }
}

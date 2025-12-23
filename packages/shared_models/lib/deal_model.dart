class DealModel {
  final String id;
  final String restaurantId;
  final String city;
  final String title;
  final String? description;
  final String category;
  final int priceMighty;
  final int? priceRs;
  final String? tag;

  // joined restaurant (optional)
  final Map<String, dynamic>? restaurant;

  DealModel({
    required this.id,
    required this.restaurantId,
    required this.city,
    required this.title,
    required this.description,
    required this.category,
    required this.priceMighty,
    required this.priceRs,
    required this.tag,
    required this.restaurant,
  });

  factory DealModel.fromMap(Map<String, dynamic> m) => DealModel(
        id: m['id'] as String,
        restaurantId: m['restaurant_id'] as String,
        city: (m['city'] as String?) ?? '',
        title: (m['title'] as String?) ?? '',
        description: m['description'] as String?,
        category: (m['category'] as String?) ?? 'All',
        priceMighty: (m['price_mighty'] as int?) ?? 0,
        priceRs: m['price_rs'] as int?,
        tag: m['tag'] as String?,
        restaurant: m['restaurant'] as Map<String, dynamic>?,
      );
}

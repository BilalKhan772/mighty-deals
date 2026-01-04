class MenuItemModel {
  final String id;
  final String restaurantId;
  final String name;
  final int? priceRs;
  final int priceMighty;
  final bool isActive;

  MenuItemModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.priceRs,
    required this.priceMighty,
    required this.isActive,
  });

  factory MenuItemModel.fromMap(Map<String, dynamic> m) => MenuItemModel(
        id: m['id'] as String,
        restaurantId: m['restaurant_id'] as String,
        name: (m['name'] as String?) ?? '',
        priceRs: m['price_rs'] as int?,
        priceMighty: (m['price_mighty'] as int?) ?? 0,
        isActive: (m['is_active'] as bool?) ?? true,
      );
}

class OrderModel {
  final String id;
  final String userId;
  final String restaurantId;
  final String? dealId;
  final String? menuItemId;
  final int coinsPaid;
  final String status;
  final DateTime createdAt;

  final Map<String, dynamic>? restaurant;
  final Map<String, dynamic>? deal;
  final Map<String, dynamic>? menuItem;

  OrderModel({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.dealId,
    required this.menuItemId,
    required this.coinsPaid,
    required this.status,
    required this.createdAt,
    required this.restaurant,
    required this.deal,
    required this.menuItem,
  });

  factory OrderModel.fromMap(Map<String, dynamic> m) => OrderModel(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        restaurantId: m['restaurant_id'] as String,
        dealId: m['deal_id'] as String?,
        menuItemId: m['menu_item_id'] as String?,
        coinsPaid: (m['coins_paid'] as int?) ?? 0,
        status: (m['status'] as String?) ?? 'pending',
        createdAt: DateTime.parse(m['created_at'] as String),
        restaurant: m['restaurant'] as Map<String, dynamic>?,
        deal: m['deal'] as Map<String, dynamic>?,
        menuItem: m['menu_item'] as Map<String, dynamic>?,
      );
}

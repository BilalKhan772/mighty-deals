class RestaurantModel {
  final String id;
  final String name;
  final String city;
  final String? address;
  final String? phone;
  final String? whatsapp;
  final String? photoUrl;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.phone,
    required this.whatsapp,
    required this.photoUrl,
  });

  factory RestaurantModel.fromMap(Map<String, dynamic> m) => RestaurantModel(
        id: m['id'] as String,
        name: (m['name'] as String?) ?? '',
        city: (m['city'] as String?) ?? '',
        address: m['address'] as String?,
        phone: m['phone'] as String?,
        whatsapp: m['whatsapp'] as String?,
        photoUrl: m['photo_url'] as String?,
      );
}

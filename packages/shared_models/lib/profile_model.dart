class ProfileModel {
  final String id;
  final String role;
  final String uniqueCode;
  final String? phone;
  final String? whatsapp;
  final String? address;
  final String? city;
  final bool isProfileComplete;

  ProfileModel({
    required this.id,
    required this.role,
    required this.uniqueCode,
    required this.phone,
    required this.whatsapp,
    required this.address,
    required this.city,
    required this.isProfileComplete,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> m) => ProfileModel(
        id: m['id'] as String,
        role: (m['role'] as String?) ?? 'customer',
        uniqueCode: (m['unique_code'] as String?) ?? '',
        phone: m['phone'] as String?,
        whatsapp: m['whatsapp'] as String?,
        address: m['address'] as String?,
        city: m['city'] as String?,
        isProfileComplete: (m['is_profile_complete'] as bool?) ?? false,
      );
}

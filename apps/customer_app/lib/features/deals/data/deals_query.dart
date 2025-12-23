class DealsQuery {
  final String city;
  final String category;
  final String search;

  const DealsQuery({
    required this.city,
    required this.category,
    required this.search,
  });

  DealsQuery copyWith({
    String? city,
    String? category,
    String? search,
  }) {
    return DealsQuery(
      city: city ?? this.city,
      category: category ?? this.category,
      search: search ?? this.search,
    );
  }
}

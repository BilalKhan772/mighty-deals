import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/deals_repo.dart';
import '../data/deals_query.dart';

final dealsRepoProvider = Provider<DealsRepo>((ref) => DealsRepo());

final dealsQueryProvider = StateProvider<DealsQuery>((ref) {
  return const DealsQuery(city: 'Peshawar', category: 'All', search: '');
});

final dealsListProvider = FutureProvider((ref) async {
  final q = ref.watch(dealsQueryProvider);
  return ref.read(dealsRepoProvider).listDeals(
        city: q.city,
        category: q.category,
        searchRestaurantName: q.search,
        limit: 20,
        offset: 0,
      );
});

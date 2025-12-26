import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/deal_model.dart';
import 'package:shared_supabase/shared_supabase.dart';

import '../data/deals_repo.dart';
import '../data/deals_query.dart';

// -------------------- Repo Providers --------------------

final dealsRepoProvider = Provider<DealsRepo>((ref) => DealsRepo());

// -------------------- Query (Filters) --------------------
// ✅ Only category + search are used from DealsQuery.
// ✅ City is ALWAYS taken from profile (currentUserCityProvider).

final dealsQueryProvider = StateProvider<DealsQuery>((ref) {
  return const DealsQuery(city: '', category: 'All', search: '');
});

// -------------------- City from Profile (Supabase) --------------------

final currentUserCityProvider = FutureProvider<String>((ref) async {
  final uid = SB.auth.currentUser?.id;
  if (uid == null) return '';

  final row = await SB.client
      .from(Tables.profiles)
      .select('city')
      .eq('id', uid)
      .maybeSingle();

  return (row?['city'] as String?)?.trim() ?? '';
});

// -------------------- Deals Controller (Pagination) --------------------

class DealsState {
  final List<DealModel> items;
  final bool isLoadingMore;
  final bool hasMore;
  final int offset;

  const DealsState({
    required this.items,
    required this.isLoadingMore,
    required this.hasMore,
    required this.offset,
  });

  factory DealsState.initial() => const DealsState(
        items: [],
        isLoadingMore: false,
        hasMore: true,
        offset: 0,
      );

  DealsState copyWith({
    List<DealModel>? items,
    bool? isLoadingMore,
    bool? hasMore,
    int? offset,
  }) {
    return DealsState(
      items: items ?? this.items,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
    );
  }
}

class DealsController extends AsyncNotifier<DealsState> {
  static const int pageSize = 20;

  DealsRepo get _repo => ref.read(dealsRepoProvider);

  @override
  Future<DealsState> build() async {
    // ✅ Rebuild when category/search changes
    final q = ref.watch(dealsQueryProvider);

    // ✅ Rebuild when profile city changes
    final city = (await ref.watch(currentUserCityProvider.future)).trim();

    if (city.isEmpty) {
      return DealsState.initial();
    }

    final firstPage = await _repo.listDeals(
      city: city,
      category: q.category,
      searchRestaurantName: q.search,
      limit: pageSize,
      offset: 0,
    );

    return DealsState(
      items: firstPage,
      isLoadingMore: false,
      hasMore: firstPage.length == pageSize,
      offset: firstPage.length,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => await build());
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    final q = ref.read(dealsQueryProvider);
    final city = (await ref.read(currentUserCityProvider.future)).trim();

    if (city.isEmpty) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
      return;
    }

    final next = await _repo.listDeals(
      city: city,
      category: q.category,
      searchRestaurantName: q.search,
      limit: pageSize,
      offset: current.offset,
    );

    final merged = [...current.items, ...next];
    final hasMore = next.length == pageSize;

    state = AsyncData(
      current.copyWith(
        items: merged,
        isLoadingMore: false,
        hasMore: hasMore,
        offset: merged.length,
      ),
    );
  }

  void setCategory(String category) {
    final q = ref.read(dealsQueryProvider);
    ref.read(dealsQueryProvider.notifier).state =
        q.copyWith(category: category);
    refresh();
  }

  void setSearch(String search) {
    final q = ref.read(dealsQueryProvider);
    ref.read(dealsQueryProvider.notifier).state = q.copyWith(search: search);
    refresh();
  }
}

final dealsControllerProvider =
    AsyncNotifierProvider<DealsController, DealsState>(DealsController.new);

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../core/network/graphql_service.dart';
import '../graphql/queries/tour_queries.dart';
import '../graphql/mutations/tour_mutations.dart';
import '../models/tour.dart';

class TourProvider with ChangeNotifier {
  List<Tour> _allTours = [];
  List<Tour> _filteredTours = [];
  List<Tour> get tours => _filteredTours;

  bool isLoading = false;

  // Filter states
  String _search = '';
  String _category = '';
  String _priceRange = '';
  int _page = 1;
  final int _pageSize = 6;

  int get totalPages => (_filteredTours.length / _pageSize).ceil().clamp(1, 999);
  int get currentPage => _page;

  // ✅ Fetch all tours
  Future<void> fetchTours() async {
    final client = GraphQLService.clientNotifier?.value;
    if (client == null) throw Exception('GraphQL client chưa được khởi tạo');

    isLoading = true;
    notifyListeners();

    try {
      final result = await client.query(
        QueryOptions(document: gql(queryTours)),
      );

      if (result.hasException) throw result.exception!;

      _allTours = (result.data?['tours'] as List)
          .map((e) => Tour.fromJson(e))
          .toList();

      applyFilters();
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Create a new tour
  Future<void> createTour(Map<String, dynamic> input) async {
    final client = GraphQLService.clientNotifier?.value;
    if (client == null) throw Exception('GraphQL client chưa được khởi tạo');

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutationCreateTour),
        variables: {'input': input},
      ),
    );

    if (result.hasException) throw result.exception!;
    await fetchTours();
  }

  // ✅ Update tour
  Future<void> updateTour(String id, Map<String, dynamic> input) async {
    final client = GraphQLService.clientNotifier?.value;
    if (client == null) throw Exception('GraphQL client chưa được khởi tạo');

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutationUpdateTour),
        variables: {
          'id': id,
          'input': input,
        },
      ),
    );

    if (result.hasException) throw result.exception!;
    await fetchTours();
  }

  // ✅ Delete tour
  Future<void> deleteTour(String id) async {
    final client = GraphQLService.clientNotifier?.value;
    if (client == null) throw Exception('GraphQL client chưa được khởi tạo');

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutationDeleteTour),
        variables: {'id': id},
      ),
    );

    if (result.hasException) throw result.exception!;
    await fetchTours();
  }

  Future<List<Tour>> searchToursByLocation(String location) async {
    final client = GraphQLService.clientNotifier?.value;
    if (client == null) return [];

    try {
      final result = await client.query(QueryOptions(
        document: gql(searchToursByLocationQuery),
        variables: {'location': location},
      ));

      if (result.hasException) {
        print('❌ Tour query error: ${result.exception}');
        return [];
      }

      final List toursData = result.data?['searchTours'] ?? [];
      return toursData.map((e) => Tour.fromJson(e)).toList();
    } catch (e) {
      print('❌ Exception in searchToursByLocation: $e');
      return [];
    }
  }

  // ✅ Filter logic
  void applyFilters() {
    final result = _allTours.where((tour) {
      final matchesSearch = tour.title
          .toLowerCase()
          .contains(_search.toLowerCase()) ||
          (tour.location ?? '').toLowerCase().contains(_search.toLowerCase());

      final matchesCategory =
          _category.isEmpty || (tour.category?.name ?? '') == _category;

      final matchesPrice = _priceRange == 'low'
          ? tour.price <= 500
          : _priceRange == 'medium'
          ? tour.price > 500 && tour.price <= 1000
          : _priceRange == 'high'
          ? tour.price > 1000
          : true;

      return matchesSearch && matchesCategory && matchesPrice;
    }).toList();

    _filteredTours = result;
    _page = 1;
    notifyListeners();
  }

  // ✅ Get paginated result
  List<Tour> get paginatedTours {
    final start = (_page - 1) * _pageSize;
    final end = (_page * _pageSize).clamp(0, _filteredTours.length);
    return _filteredTours.sublist(start, end);
  }

  // ✅ Filter setters
  void setSearch(String val) {
    _search = val;
    applyFilters();
  }

  void setCategory(String val) {
    _category = val;
    applyFilters();
  }

  void setPriceRange(String val) {
    _priceRange = val;
    applyFilters();
  }

  void setPage(int val) {
    _page = val.clamp(1, totalPages);
    notifyListeners();
  }

  // ✅ Extract available categories from tours
  List<String> get categories => _allTours
      .map((t) => t.category?.name ?? '')
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList();
}
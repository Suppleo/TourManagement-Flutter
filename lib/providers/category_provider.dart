import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../core/network/graphql_service.dart';
import '../graphql/queries/category_queries.dart';
import '../graphql/mutations/category_mutations.dart';
import '../models/category.dart';

class CategoryProvider with ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      final client = GraphQLService.clientNotifier?.value;
      if (client == null) throw Exception('GraphQL client chưa được khởi tạo');

      final result = await client.query(
        QueryOptions(document: gql(queryCategories)),
      );

      if (result.hasException) throw result.exception!;

      final data = result.data;
      _categories = data?['categories'] != null
          ? (data!['categories'] as List)
          .map((e) => Category.fromJson(e))
          .toList()
          : [];
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCategory({
    required String name,
    String? description,
  }) async {
    final client = GraphQLService.clientNotifier?.value;
    if (client == null) throw Exception('GraphQL client chưa được khởi tạo');

    await client.mutate(
      MutationOptions(
        document: gql(mutationCreateCategory),
        variables: {
          'name': name,
          'description': description,
        },
      ),
    );
    await fetchCategories();
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    String? description,
  }) async {
    final client = GraphQLService.clientNotifier?.value;
    if (client == null) throw Exception('GraphQL client chưa được khởi tạo');

    await client.mutate(
      MutationOptions(
        document: gql(mutationUpdateCategory),
        variables: {
          'id': id,
          'name': name,
          'description': description,
        },
      ),
    );
    await fetchCategories();
  }

  Future<void> deleteCategory(String id) async {
    final client = GraphQLService.clientNotifier?.value;
    if (client == null) throw Exception('GraphQL client chưa được khởi tạo');

    await client.mutate(
      MutationOptions(
        document: gql(mutationDeleteCategory),
        variables: {'id': id},
      ),
    );
    await fetchCategories();
  }
}

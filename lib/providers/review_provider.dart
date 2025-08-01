import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../core/network/graphql_service.dart';
import '../graphql/queries/review_queries.dart';
import '../graphql/mutations/review_mutations.dart';
import '../models/review.dart';

class ReviewProvider with ChangeNotifier {
  List<Review> _reviews = [];
  List<Review> get reviews => _reviews;

  /// Fetch all reviews or reviews by specific tourId
  Future<void> fetchReviews({String? tourId}) async {
    final client = GraphQLService.clientNotifier.value;
    if (client == null) throw Exception('GraphQL client chưa được khởi tạo');

    final result = await client.query(
      QueryOptions(
        document: gql(queryReviews),
        variables: tourId != null ? {'tour': tourId} : {},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      print('❌ GraphQL fetchReviews exception: ${result.exception}');
      throw result.exception!;
    }

    final raw = result.data?['reviews'] as List<dynamic>? ?? [];
    _reviews = raw.map((e) => Review.fromJson(e)).toList();
    notifyListeners();
  }

  /// Create a review
  Future<void> createReview({
    required String tourId,
    required int rating,
    required String comment,
    List<String>? images,
  }) async {
    final client = GraphQLService.clientNotifier.value;
    if (client == null) throw Exception('GraphQL client chưa được khởi tạo');

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutationCreateReview),
        variables: {
          'tour': tourId,
          'rating': rating,
          'comment': comment,
          'images': images ?? [],
        },
      ),
    );

    if (result.hasException) {
      print('❌ GraphQL createReview exception: ${result.exception}');
      throw result.exception!;
    }

    final newReview = Review.fromJson(result.data!['createReview']);
    _reviews.insert(0, newReview);
    notifyListeners();
  }

  /// Admin reply to review
  Future<void> replyReview(String reviewId, String reply) async {
    final client = GraphQLService.clientNotifier.value;
    if (client == null) throw Exception('GraphQL client chưa được khởi tạo');

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutationReplyReview),
        variables: {
          'id': reviewId,
          'reply': reply,
        },
      ),
    );

    if (result.hasException) {
      print('❌ GraphQL replyReview exception: ${result.exception}');
      throw result.exception!;
    }

    final updated = Review.fromJson(result.data!['replyReview']);
    final index = _reviews.indexWhere((r) => r.id == reviewId);
    if (index != -1) {
      _reviews[index] = updated;
      notifyListeners();
    }
  }

  /// Update review (status, rating, comment, images)
  Future<void> updateReview(
      String reviewId, {
        int? rating,
        String? comment,
        String? status,
        List<String>? images,
      }) async {
    final client = GraphQLService.clientNotifier.value;
    if (client == null) throw Exception('GraphQL client chưa được khởi tạo');

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutationUpdateReview),
        variables: {
          'id': reviewId,
          if (rating != null) 'rating': rating,
          if (comment != null) 'comment': comment,
          if (status != null) 'status': status,
          if (images != null) 'images': images,
        },
      ),
    );

    if (result.hasException) {
      print('❌ GraphQL updateReview exception: ${result.exception}');
      throw result.exception!;
    }

    final updated = Review.fromJson(result.data!['updateReview']);
    final index = _reviews.indexWhere((r) => r.id == reviewId);
    if (index != -1) {
      _reviews[index] = updated;
      notifyListeners();
    }
  }

  /// Delete a review
  Future<void> deleteReview(String reviewId) async {
    final client = GraphQLService.clientNotifier.value;
    if (client == null) throw Exception('GraphQL client chưa được khởi tạo');

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutationDeleteReview),
        variables: {
          'id': reviewId,
        },
      ),
    );

    if (result.hasException) {
      print('❌ GraphQL deleteReview exception: ${result.exception}');
      throw result.exception!;
    }

    _reviews.removeWhere((r) => r.id == reviewId);
    notifyListeners();
  }
}

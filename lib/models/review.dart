import 'package:flutter/cupertino.dart';

import 'tour.dart';
import 'user.dart';

class Review {
  final String id;
  final Tour tour;
  final User user;
  final int rating;
  final String? comment;
  final List<String> images;
  final String reply;
  final String status;
  final bool isDeleted;
  final String? createdAt;
  final String? updatedAt;

  Review({
    required this.id,
    required this.tour,
    required this.user,
    required this.rating,
    this.comment,
    required this.images,
    required this.reply,
    required this.status,
    required this.isDeleted,
    this.createdAt,
    this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    try {
      return Review(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? 'unknown',
        tour: Tour.fromJson(json['tour'] ?? {}),
        user: User.fromJson(json['user'] ?? {}),
        rating: json['rating'] is int ? json['rating'] : int.tryParse('${json['rating']}') ?? 0,
        comment: json['comment']?.toString(),
        images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
        reply: json['reply']?.toString() ?? '',
        status: json['status']?.toString() ?? 'pending',
        isDeleted: json['isDeleted'] as bool? ?? false,
        createdAt: json['createdAt']?.toString(),
        updatedAt: json['updatedAt']?.toString(),
      );
    } catch (e, stack) {
      debugPrint('❌ Error parsing Review: $e');
      debugPrintStack(stackTrace: stack);
      debugPrint('🧩 JSON bị lỗi: $json');
      rethrow;
    }
  }
}

import 'category.dart';

class Tour {
  final String id;
  final String title;
  final double price;
  final String? itinerary;
  final List<String>? servicesIncluded;
  final List<String>? servicesExcluded;
  final String? cancelPolicy;
  final List<String>? images;
  final List<String>? videos;
  final String? location;
  final Category? category;
  final String? status;
  final bool? isDeleted;
  final int? version;
  final String? createdAt;
  final String? updatedAt;

  Tour({
    required this.id,
    required this.title,
    required this.price,
    this.itinerary,
    this.servicesIncluded,
    this.servicesExcluded,
    this.cancelPolicy,
    this.images,
    this.videos,
    this.location,
    this.category,
    this.status,
    this.isDeleted,
    this.version,
    this.createdAt,
    this.updatedAt,
  });

  factory Tour.fromJson(Map<String, dynamic> json) {
    return Tour(
      id: json['id']?.toString() ?? 'unknown',
      title: json['title']?.toString() ?? 'Chưa có tiêu đề',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      itinerary: json['itinerary']?.toString(),
      servicesIncluded: (json['servicesIncluded'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      servicesExcluded: (json['servicesExcluded'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      cancelPolicy: json['cancelPolicy']?.toString(),
      images: (json['images'] as List?)?.map((e) => e.toString()).toList(),
      videos: (json['videos'] as List?)?.map((e) => e.toString()).toList(),
      location: json['location']?.toString(),
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,
      status: json['status']?.toString(),
      isDeleted: json['isDeleted'] as bool?,
      version: json['version'] as int?,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}

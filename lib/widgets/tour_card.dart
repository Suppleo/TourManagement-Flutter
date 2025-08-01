import 'package:flutter/material.dart';
import '../models/tour.dart';
import '../core/network/api_config.dart';

class TourCard extends StatelessWidget {
  final Tour tour;
  final VoidCallback? onTap;

  const TourCard({super.key, required this.tour, this.onTap});

  // Blue color scheme
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color lightBlue = Color(0xFF64B5F6);

  /// Hàm xây URL ảnh an toàn
  String get imageUrl {
    final firstImage = (tour.images?.isNotEmpty ?? false) ? tour.images!.first : null;

    if (firstImage == null || firstImage.trim().isEmpty || firstImage == 'null') {
      return 'https://via.placeholder.com/400x200.png?text=No+Image';
    }

    if (firstImage.startsWith('http')) return firstImage;

    // Nếu firstImage đã bắt đầu bằng "uploads/", ta loại bỏ nó
    String cleanedPath = firstImage.replaceFirst(RegExp(r'^/+'), '');
    if (ApiConfig.staticBaseUrl.contains('/uploads/') && cleanedPath.startsWith('uploads/')) {
      cleanedPath = cleanedPath.replaceFirst('uploads/', '');
    }

    return '${ApiConfig.staticBaseUrl}$cleanedPath';
  }

  /// Lấy thông tin dịch vụ nổi bật từ servicesIncluded
  List<String> get highlightedServices {
    if (tour.servicesIncluded == null || tour.servicesIncluded!.isEmpty) {
      return [];
    }

    // Lấy tối đa 2 dịch vụ đầu tiên để hiển thị
    return tour.servicesIncluded!.take(2).toList();
  }

  /// Format giá tiền theo USD
  String get formattedPrice {
    if (tour.price == null) return 'Liên hệ';

    // Hiển thị giá theo USD với format đẹp
    final price = tour.price!.toInt();

    // Format với dấu phẩy cho số lớn
    return '\$${price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},'
    )}';
  }

  /// Lấy trạng thái tour
  String get tourStatus {
    if (tour.status == null) return '';

    switch (tour.status!.toLowerCase()) {
      case 'active':
        return 'Đang hoạt động';
      case 'inactive':
        return 'Tạm dừng';
      case 'full':
        return 'Hết chỗ';
      default:
        return tour.status!;
    }
  }

  /// Kiểm tra tour có khả dụng không
  bool get isAvailable {
    return tour.status?.toLowerCase() == 'active' &&
        (tour.isDeleted == null || tour.isDeleted == false);
  }

  @override
  Widget build(BuildContext context) {
    print('[TourCard] title: ${tour.title} | price: ${tour.price} | status: ${tour.status}');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isAvailable ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section với overlay
              Container(
                height: 200,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Stack(
                  children: [
                    // Main Image
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: Image.network(
                        imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primaryBlue.withOpacity(0.3),
                                lightBlue.withOpacity(0.3),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.landscape,
                                  size: 48,
                                  color: primaryBlue,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Không có ảnh',
                                  style: TextStyle(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.grey[200]!,
                                  Colors.grey[100]!,
                                ],
                              ),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Gradient overlay
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),

                    // Price tag
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          formattedPrice,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                    // Status badge (nếu không available)
                    if (!isAvailable)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tourStatus,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                    // Category badge (nếu có)
                    if (tour.category != null && tour.category!.name != null)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tour.category!.name!,
                            style: const TextStyle(
                              color: primaryBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Content Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      tour.title ?? 'Tên tour không có',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Location
                    if (tour.location != null && tour.location!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              tour.location!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    // Services included (nếu có)
                    if (highlightedServices.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: highlightedServices.map((service) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              service,
                              style: const TextStyle(
                                fontSize: 11,
                                color: primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Bottom row với thông tin thật
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tour ID và ngày tạo
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (tour.id != null)
                                Text(
                                  'ID: ${tour.id}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (tour.createdAt != null)
                                Text(
                                  'Tạo: ${_formatDate(tour.createdAt!)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Book button
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isAvailable
                                ? const LinearGradient(colors: [primaryBlue, lightBlue])
                                : LinearGradient(colors: [Colors.grey[400]!, Colors.grey[300]!]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isAvailable ? 'Xem chi tiết' : 'Không khả dụng',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Format ngày tháng
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

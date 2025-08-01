import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../models/tour.dart';
import '../../../models/booking.dart';
import '../../../providers/tour_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/review_provider.dart';
import '../../../core/network/api_config.dart';
import '../../../widgets/booking_form.dart';
import '../../../widgets/review_card.dart';

class TourDetailScreen extends StatefulWidget {
  final String tourId;

  const TourDetailScreen({super.key, required this.tourId});

  @override
  State<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends State<TourDetailScreen> {
  List<Booking> relatedBookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    // Trì hoãn mọi thứ sau 1 khung hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRelatedBookings();
      Provider.of<ReviewProvider>(context, listen: false).fetchReviews(tourId: widget.tourId);
    });
  }

  Future<void> _loadRelatedBookings() async {
    try {
      final bookingProvider =
      Provider.of<BookingProvider>(context, listen: false);
      await bookingProvider.fetchBookings();

      final filtered = bookingProvider.bookings
          .where((b) => b.tour?.id == widget.tourId)
          .toList();

      setState(() {
        relatedBookings = filtered;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Lỗi khi load bookings: $e');
      setState(() => isLoading = false);
    }
  }

  String formatList(List<String>? items) {
    if (items == null || items.isEmpty) return 'Không có dữ liệu';
    return items.map((e) => '• $e').join('\n');
  }

  String formatDateTime(String? iso) {
    if (iso == null) return 'Không rõ';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('dd/MM/yyyy – HH:mm').format(dt);
  }

  String getImageUrl(String? path) {
    if (path == null || path.trim().isEmpty || path == 'null') {
      return 'https://via.placeholder.com/800x300.png?text=No+Image';
    }
    if (path.startsWith('http')) return Uri.encodeFull(path);
    String cleaned = path.replaceFirst(RegExp(r'^/+'), '');
    if (ApiConfig.staticBaseUrl.contains('/uploads/') &&
        cleaned.startsWith('uploads/')) {
      cleaned = cleaned.replaceFirst('uploads/', '');
    }
    return Uri.encodeFull('${ApiConfig.staticBaseUrl}$cleaned');
  }

  @override
  Widget build(BuildContext context) {
    final tourProvider = Provider.of<TourProvider>(context);
    final tour = tourProvider.tours.firstWhere(
          (t) => t.id == widget.tourId,
      orElse: () => Tour(id: widget.tourId, title: 'Không tìm thấy', price: 0),
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Hero App Bar với hình ảnh
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(25),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.white),
                  onPressed: () {},
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (tour.images != null && tour.images!.isNotEmpty)
                    Image.network(
                      getImageUrl(tour.images!.first),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                      ),
                    )
                  else
                    Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                    ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Nội dung chính
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header thông tin tour
                    _buildTourHeader(tour),

                    const SizedBox(height: 24),

                    // Tabs cho nội dung
                    DefaultTabController(
                      length: 3,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: TabBar(
                              indicator: BoxDecoration(
                                color: Colors.deepPurple,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepPurple.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.grey[700],
                              indicatorSize: TabBarIndicatorSize.tab,
                              tabs: const [
                                Tab(text: 'Chi tiết'),
                                Tab(text: 'Đặt tour'),
                                Tab(text: 'Đánh giá'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 800,
                            child: TabBarView(
                              children: [
                                _buildDetailTab(tour),
                                _buildBookingTab(),
                                _buildReviewTab(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTourHeader(Tour tour) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề và rating
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                tour.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('4.5', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Vị trí
        if (tour.location != null)
          Row(
            children: [
              Icon(Icons.location_on, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tour.location!,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),

        const SizedBox(height: 16),

        // Giá và trạng thái
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giá tour',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '\$${tour.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            if (tour.status != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor(tour.status!),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tour.status!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Danh mục
        if (tour.category != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.category, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 6),
                Text(
                  tour.category!.name,
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDetailTab(Tour tour) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tour.itinerary != null) ...[
            _buildInfoCard(
              icon: Icons.route,
              title: 'Hành trình',
              content: tour.itinerary!,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
          ],

          _buildInfoCard(
            icon: Icons.check_circle,
            title: 'Dịch vụ bao gồm',
            content: formatList(tour.servicesIncluded),
            color: Colors.green,
          ),

          const SizedBox(height: 16),

          _buildInfoCard(
            icon: Icons.cancel,
            title: 'Dịch vụ không bao gồm',
            content: formatList(tour.servicesExcluded),
            color: Colors.red,
          ),

          const SizedBox(height: 16),

          if (tour.cancelPolicy != null) ...[
            _buildInfoCard(
              icon: Icons.policy,
              title: 'Chính sách hủy',
              content: tour.cancelPolicy!,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
          ],

          // Thông tin thời gian
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Thông tin thêm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTimeInfo('Ngày tạo', formatDateTime(tour.createdAt)),
                const SizedBox(height: 8),
                _buildTimeInfo('Cập nhật lần cuối', formatDateTime(tour.updatedAt)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: BookingForm(tourId: widget.tourId),
      ),
    );
  }

  Widget _buildReviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 20),
      child: Consumer<ReviewProvider>(
        builder: (context, reviewProvider, _) {
          final reviews = reviewProvider.reviews.where((r) {
            try {
              return r.tour.id == widget.tourId;
            } catch (e) {
              debugPrint('⚠️ Review missing tour.id: ${r.id}');
              return false;
            }
          }).toList();

          if (reviews.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.star_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có đánh giá nào',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hãy là người đầu tiên đánh giá tour này!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Review summary
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 32),
                    const SizedBox(width: 12),
                    Text(
                      '${reviews.length} đánh giá',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Review list
              ...reviews.map((review) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ReviewCard(review: review),
              )).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(String label, String value) {
    return Row(
      children: [
        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.black87),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'hoạt động':
        return Colors.green;
      case 'inactive':
      case 'không hoạt động':
        return Colors.red;
      case 'pending':
      case 'chờ duyệt':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

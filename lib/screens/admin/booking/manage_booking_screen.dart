import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/booking_provider.dart';

class ManageBookingScreen extends StatefulWidget {
  const ManageBookingScreen({super.key});

  @override
  State<ManageBookingScreen> createState() => _ManageBookingScreenState();
}

class _ManageBookingScreenState extends State<ManageBookingScreen>
    with TickerProviderStateMixin {
  String statusFilter = 'all';
  String paymentFilter = 'all';
  String searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    Future.microtask(() {
      Provider.of<BookingProvider>(context, listen: false).fetchBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'Invalid date';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentColor(String paymentStatus) {
    switch (paymentStatus) {
      case 'paid':
        return Colors.blue;
      case 'unpaid':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);
    final allBookings = provider.bookings;

    final filtered = allBookings.where((b) {
      final matchesSearch = b.tour?.title.toLowerCase().contains(searchQuery.toLowerCase()) == true ||
          b.user?.email.toLowerCase().contains(searchQuery.toLowerCase()) == true;
      final matchesStatus = statusFilter == 'all' || b.status == statusFilter;
      final matchesPayment = paymentFilter == 'all' || b.paymentStatus == paymentFilter;
      return matchesSearch && matchesStatus && matchesPayment;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        title: const Text(
          "Quản lý Booking",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin/dashboard');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.fetchBookings(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header với statistics cards
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF2196F3),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Statistics Cards
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(child: _modernStatCard('Tổng số', allBookings.length, Icons.receipt_long, Colors.white)),
                      const SizedBox(width: 12),
                      Expanded(child: _modernStatCard('Đã xác nhận', allBookings.where((b) => b.status == 'confirmed').length, Icons.check_circle, Colors.green.shade100)),
                      const SizedBox(width: 12),
                      Expanded(child: _modernStatCard('Chờ xử lý', allBookings.where((b) => b.status == 'pending').length, Icons.access_time, Colors.orange.shade100)),
                      const SizedBox(width: 12),
                      Expanded(child: _modernStatCard('Đã thanh toán', allBookings.where((b) => b.paymentStatus == 'paid').length, Icons.payment, Colors.blue.shade100)),
                    ],
                  ),
                ),

                // Search và Filters
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    children: [
                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Tìm kiếm theo tour hoặc email...',
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (value) => setState(() => searchQuery = value),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Filter buttons
                      Row(
                        children: [
                          Expanded(
                            child: _filterDropdown(
                              'Trạng thái',
                              statusFilter,
                              [
                                {'value': 'all', 'label': 'Tất cả'},
                                {'value': 'pending', 'label': 'Chờ xử lý'},
                                {'value': 'confirmed', 'label': 'Đã xác nhận'},
                                {'value': 'cancelled', 'label': 'Đã hủy'},
                              ],
                                  (value) => setState(() => statusFilter = value!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _filterDropdown(
                              'Thanh toán',
                              paymentFilter,
                              [
                                {'value': 'all', 'label': 'Tất cả'},
                                {'value': 'unpaid', 'label': 'Chưa thanh toán'},
                                {'value': 'paid', 'label': 'Đã thanh toán'},
                              ],
                                  (value) => setState(() => paymentFilter = value!),
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

          // Content
          Expanded(
            child: provider.isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải dữ liệu...'),
                ],
              ),
            )
                : filtered.isEmpty
                ? _emptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final b = filtered[index];
                return _modernBookingCard(context, b, provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernStatCard(String label, int value, IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF2196F3), size: 24),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2196F3),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown(String label, String value, List<Map<String, String>> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(label, style: const TextStyle(color: Colors.grey)),
          items: items.map((item) => DropdownMenuItem(
            value: item['value'],
            child: Text(item['label']!, style: const TextStyle(fontSize: 14)),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _modernBookingCard(BuildContext context, booking, provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/admin/bookings/${booking.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.tour?.title ?? 'Tour chưa xác định',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Xác nhận xóa'),
                            content: const Text('Bạn có chắc chắn muốn xóa booking này?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Hủy'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Xóa'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await provider.deleteBooking(booking.id);
                        }
                      } else if (value == 'toggle') {
                        final newStatus = booking.status == 'confirmed' ? 'pending' : 'confirmed';
                        await provider.updateBookingStatus(booking.id, newStatus);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(Icons.swap_horiz, size: 20),
                            SizedBox(width: 8),
                            Text('Đổi trạng thái'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      booking.user?.email ?? 'Email ẩn',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Ngày tạo: ${formatDate(booking.createdAt)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  _statusChip(booking.status, _getStatusColor(booking.status)),
                  const SizedBox(width: 8),
                  _statusChip(booking.paymentStatus, _getPaymentColor(booking.paymentStatus)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status, Color color) {
    String displayText;
    switch (status) {
      case 'confirmed':
        displayText = 'Đã xác nhận';
        break;
      case 'pending':
        displayText = 'Chờ xử lý';
        break;
      case 'cancelled':
        displayText = 'Đã hủy';
        break;
      case 'paid':
        displayText = 'Đã thanh toán';
        break;
      case 'unpaid':
        displayText = 'Chưa thanh toán';
        break;
      default:
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Không có booking nào',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hiện tại chưa có booking nào phù hợp với bộ lọc',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

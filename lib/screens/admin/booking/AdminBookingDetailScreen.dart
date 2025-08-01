import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../models/booking.dart';
import '../../../providers/booking_provider.dart';

class AdminBookingDetailScreen extends StatefulWidget {
  final String bookingId;
  const AdminBookingDetailScreen({super.key, required this.bookingId});

  @override
  State<AdminBookingDetailScreen> createState() => _AdminBookingDetailScreenState();
}

class _AdminBookingDetailScreenState extends State<AdminBookingDetailScreen>
    with TickerProviderStateMixin {
  Booking? booking;
  bool isEditing = false;
  bool _isLoading = false;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> validStatuses = [
    {
      'value': 'pending',
      'label': 'Chờ xử lý',
      'color': Colors.orange,
      'icon': Icons.access_time_filled,
      'gradient': [Colors.orange, Colors.deepOrange]
    },
    {
      'value': 'confirmed',
      'label': 'Đã xác nhận',
      'color': Colors.green,
      'icon': Icons.check_circle,
      'gradient': [Colors.green, Colors.teal]
    },
    {
      'value': 'cancelled',
      'label': 'Đã hủy',
      'color': Colors.red,
      'icon': Icons.cancel,
      'gradient': [Colors.red, Colors.pink]
    },
  ];

  final List<Map<String, dynamic>> validPayments = [
    {
      'value': 'unpaid',
      'label': 'Chưa thanh toán',
      'color': Colors.red,
      'icon': Icons.money_off,
      'gradient': [Colors.red, Colors.deepOrange]
    },
    {
      'value': 'paid',
      'label': 'Đã thanh toán',
      'color': Colors.blue,
      'icon': Icons.payment,
      'gradient': [Colors.blue, Colors.indigo]
    },
  ];

  String? selectedStatus;
  String? selectedPayment;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _fetchBooking();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchBooking() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<BookingProvider>(context, listen: false);
    try {
      final result = await provider.fetchBookingById(widget.bookingId);
      setState(() {
        booking = result;
        selectedStatus = booking?.status;
        selectedPayment = booking?.paymentStatus;
      });

      // Start animations
      _fadeController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      _slideController.forward();

    } catch (e) {
      if (mounted) {
        _showCustomSnackBar('❌ Lỗi khi tải booking: $e', isError: true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSave() async {
    if (booking == null) return;

    // Show confirmation dialog
    final confirm = await _showConfirmDialog(
      'Xác nhận cập nhật',
      'Bạn có chắc chắn muốn cập nhật trạng thái booking này?',
    );

    if (!confirm) return;

    setState(() => _isLoading = true);
    final provider = Provider.of<BookingProvider>(context, listen: false);
    try {
      await provider.updateBookingStatus(
        booking!.id,
        selectedStatus ?? booking?.status ?? 'pending',
        paymentStatus: selectedPayment ?? booking?.paymentStatus,
      );
      if (mounted) {
        _showCustomSnackBar('✅ Đã cập nhật booking thành công!', isSuccess: true);
        setState(() => isEditing = false);
        _fetchBooking();
      }
    } catch (e) {
      if (mounted) {
        _showCustomSnackBar('❌ Lỗi cập nhật: $e', isError: true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCustomSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : isSuccess ? Icons.check_circle : Icons.info,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : isSuccess ? Colors.green[600] : Colors.blue[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    ) ?? false;
  }

  Map<String, dynamic> _getStatusData(String status, bool isPayment) {
    final list = isPayment ? validPayments : validStatuses;
    return list.firstWhere(
          (item) => item['value'] == status,
      orElse: () => {
        'value': status,
        'label': status,
        'color': Colors.grey,
        'icon': Icons.help,
        'gradient': [Colors.grey, Colors.blueGrey]
      },
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: _isLoading
                ? _buildLoadingState()
                : booking == null
                ? _buildErrorState()
                : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), // 👈 Tăng bottom padding
                  child: Column(
                    children: [
                      _buildHeroCard(),
                      const SizedBox(height: 20),
                      _buildInfoCard(),
                      const SizedBox(height: 16),
                      _buildPassengerCard(),
                      const SizedBox(height: 16),
                      _buildStatusCard(),
                      const SizedBox(height: 16),
                      _buildTimeCard(),
                      const SizedBox(height: 80), // 👈 Tăng spacing cuối
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF2196F3),
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => context.pop(),
      ),
      title: Text(
        isEditing ? 'Chỉnh sửa Booking' : 'Chi tiết Booking',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      actions: [
        if (!isEditing && booking != null) ...[
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => isEditing = true),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ] else if (isEditing) ...[
          TextButton.icon(
            onPressed: () => setState(() => isEditing = false),
            icon: const Icon(Icons.close, color: Colors.white),
            label: const Text('Hủy', style: TextStyle(color: Colors.white)),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16, left: 8),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleSave,
              icon: _isLoading
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
                  : const Icon(Icons.save),
              label: const Text('Lưu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2196F3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
            ),
            SizedBox(height: 20),
            Text(
              'Đang tải chi tiết booking...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            ),
            const SizedBox(height: 20),
            Text(
              'Không tìm thấy booking',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Booking này có thể đã bị xóa hoặc không tồn tại',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchBooking,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    final statusData = _getStatusData(booking!.status ?? 'pending', false);
    final paymentData = _getStatusData(booking!.paymentStatus ?? 'unpaid', true);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tour, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    booking!.tour?.title ?? 'Tour chưa xác định',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.person_outline, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking!.user?.email ?? 'Email ẩn',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildHeroStatusChip(
                  statusData['label'],
                  statusData['icon'],
                  statusData['gradient'],
                ),
                const SizedBox(width: 12),
                _buildHeroStatusChip(
                  paymentData['label'],
                  paymentData['icon'],
                  paymentData['gradient'],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStatusChip(String label, IconData icon, List<Color> gradient) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return _buildModernCard(
      title: 'Thông Tin Chung',
      icon: Icons.info_outline,
      gradient: [Colors.blue, Colors.indigo],
      children: [
        _buildInfoTile('Tour', booking!.tour?.title ?? 'Chưa có', Icons.tour, Colors.purple),
        _buildInfoTile('Khách hàng', booking!.user?.email ?? 'Ẩn', Icons.person_outline, Colors.green),
        _buildInfoTile('Phương thức', booking!.paymentMethod ?? 'Không rõ', Icons.credit_card, Colors.orange),
        _buildInfoTile('Mã giảm giá', booking!.voucher ?? 'Không có', Icons.local_offer, Colors.red),
      ],
    );
  }

  Widget _buildPassengerCard() {
    final passengers = booking!.passengers ?? [];
    return _buildModernCard(
      title: 'Hành Khách (${passengers.length})',
      icon: Icons.people_outline,
      gradient: [Colors.green, Colors.teal],
      children: passengers.isEmpty
          ? [
        Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.person_off_outlined, size: 48, color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              Text(
                'Không có hành khách',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )
      ]
          : passengers
          .asMap()
          .entries
          .map((entry) => _buildPassengerTile(entry.value, entry.key))
          .toList(),
    );
  }

  Widget _buildPassengerTile(Map<String, dynamic> passenger, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[50]!, Colors.grey[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[600]!],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${passenger['name']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${passenger['type']}',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tuổi: ${passenger['age']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return _buildModernCard(
      title: 'Trạng Thái',
      icon: Icons.assignment_turned_in_outlined,
      gradient: [Colors.orange, Colors.deepOrange],
      children: [
        isEditing ? _buildEditingForm() : _buildStatusDisplay(),
      ],
    );
  }

  Widget _buildEditingForm() {
    return Column(
      children: [
        _buildModernDropdown(
          label: 'Trạng thái booking',
          value: validStatuses.any((s) => s['value'] == selectedStatus) ? selectedStatus : null,
          items: validStatuses,
          onChanged: (value) => setState(() => selectedStatus = value),
          icon: Icons.flag_outlined,
        ),
        const SizedBox(height: 20),
        _buildModernDropdown(
          label: 'Trạng thái thanh toán',
          value: validPayments.any((p) => p['value'] == selectedPayment) ? selectedPayment : null,
          items: validPayments,
          onChanged: (value) => setState(() => selectedPayment = value),
          icon: Icons.payment_outlined,
        ),
      ],
    );
  }

  Widget _buildModernDropdown({
    required String label,
    required String? value,
    required List<Map<String, dynamic>> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[50]!, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF2196F3)),
          ),
        ),
        items: items
            .map<DropdownMenuItem<String>>((item) => DropdownMenuItem<String>( // 👈 Thêm explicit type
          value: item['value'] as String, // 👈 Cast về String
          child: Row(
            children: [
              Icon(item['icon'], color: item['color'], size: 20),
              const SizedBox(width: 12),
              Text(
                item['label'] as String, // 👈 Cast về String
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }


  Widget _buildStatusDisplay() {
    final statusData = _getStatusData(booking!.status ?? 'pending', false);
    final paymentData = _getStatusData(booking!.paymentStatus ?? 'unpaid', true);

    return Column(
      children: [
        _buildInfoTile(
          'Trạng thái',
          statusData['label'],
          statusData['icon'],
          statusData['color'],
        ),
        _buildInfoTile(
          'Thanh toán',
          paymentData['label'],
          paymentData['icon'],
          paymentData['color'],
        ),
      ],
    );
  }

  Widget _buildTimeCard() {
    return _buildModernCard(
      title: 'Lịch Sử',
      icon: Icons.schedule_outlined,
      gradient: [Colors.purple, Colors.deepPurple],
      children: [
        _buildInfoTile('Ngày tạo', _formatDate(booking!.createdAt), Icons.add_circle_outline, Colors.green),
        _buildInfoTile('Cập nhật', _formatDate(booking!.updatedAt), Icons.update_outlined, Colors.blue),
      ],
    );
  }

  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[50]!, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 16),
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return 'Không rõ';
    try {
      final date = DateTime.parse(raw).toLocal();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Không hợp lệ';
    }
  }
}

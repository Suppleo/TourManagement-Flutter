import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/voucher_provider.dart';
import '../../../models/voucher.dart';

class ManageVoucherScreen extends StatefulWidget {
  const ManageVoucherScreen({super.key});

  @override
  State<ManageVoucherScreen> createState() => _ManageVoucherScreenState();
}

class _ManageVoucherScreenState extends State<ManageVoucherScreen>
    with TickerProviderStateMixin {
  late Future<void> _fetchFuture;
  String _statusFilter = 'all';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void initState() {
    super.initState();
    _fetchFuture = Provider.of<VoucherProvider>(context, listen: false).fetchVouchers();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scaffoldMessenger = null;
    super.dispose();
  }

  void _refreshData() {
    if (!mounted) return;
    setState(() {
      _fetchFuture = Provider.of<VoucherProvider>(context, listen: false).fetchVouchers();
    });
  }

  void _showModernSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    if (!mounted || _scaffoldMessenger == null) return;

    try {
      _scaffoldMessenger!.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : isSuccess ? Icons.check_circle : Icons.info,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: isError
              ? Colors.red[600]
              : isSuccess
              ? Colors.green[600]
              : Colors.blue[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Cannot show SnackBar: $e');
    }
  }

  void _showDeleteConfirm(String id) async {
    if (!mounted) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[600]),
            const SizedBox(width: 8),
            const Text('Xác nhận xóa'),
          ],
        ),
        content: const Text('Bạn có chắc chắn muốn xóa voucher này không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (!mounted || shouldDelete != true) return;

    try {
      await Provider.of<VoucherProvider>(context, listen: false).deleteVoucher(id);
      if (mounted) {
        _refreshData();
        _showModernSnackBar('✅ Xóa voucher thành công', isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        _showModernSnackBar('❌ Không thể xóa voucher: $e', isError: true);
      }
    }
  }

  void _showEditVoucherDialog({Voucher? voucher}) {
    if (!mounted) return;

    final isEdit = voucher != null;
    final codeController = TextEditingController(text: voucher?.code ?? '');
    final valueController = TextEditingController(text: voucher?.value.toString() ?? '');
    final conditionController = TextEditingController(text: voucher?.conditions ?? '');
    final validFromController = TextEditingController(text: voucher?.validFrom ?? '');
    final validToController = TextEditingController(text: voucher?.validTo ?? '');
    String type = voucher?.type ?? 'percentage';
    String status = voucher?.status ?? 'active';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isEdit ? Icons.edit : Icons.add_circle_outline,
                      color: const Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(isEdit ? 'Chỉnh sửa Voucher' : 'Thêm Voucher'),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDialogTextField(
                        controller: codeController,
                        label: 'Mã voucher',
                        icon: Icons.confirmation_number,
                      ),
                      const SizedBox(height: 16),
                      _buildDialogTextField(
                        controller: valueController,
                        label: 'Giá trị',
                        icon: Icons.monetization_on,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildDialogTextField(
                        controller: conditionController,
                        label: 'Điều kiện',
                        icon: Icons.rule,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      _buildDialogTextField(
                        controller: validFromController,
                        label: 'Hiệu lực từ (yyyy-mm-dd)',
                        icon: Icons.date_range,
                      ),
                      const SizedBox(height: 16),
                      _buildDialogTextField(
                        controller: validToController,
                        label: 'Hết hạn (yyyy-mm-dd)',
                        icon: Icons.event_busy,
                      ),
                      const SizedBox(height: 16),
                      _buildDialogDropdown(
                        value: type,
                        label: 'Loại giảm',
                        icon: Icons.category,
                        items: const [
                          DropdownMenuItem(value: 'percentage', child: Text('Phần trăm')),
                          DropdownMenuItem(value: 'fixed', child: Text('Giảm cố định')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() => type = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDialogDropdown(
                        value: status,
                        label: 'Trạng thái',
                        icon: Icons.toggle_on,
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('Đang hoạt động')),
                          DropdownMenuItem(value: 'inactive', child: Text('Tạm dừng')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() => status = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final input = {
                      'code': codeController.text.trim(),
                      'value': double.tryParse(valueController.text) ?? 0,
                      'conditions': conditionController.text.trim(),
                      'validFrom': validFromController.text.trim().isEmpty ? null : validFromController.text.trim(),
                      'validTo': validToController.text.trim().isEmpty ? null : validToController.text.trim(),
                      'type': type,
                      'status': status,
                    };

                    if (input['code'].toString().isEmpty) {
                      _showModernSnackBar('❌ Vui lòng nhập mã voucher', isError: true);
                      return;
                    }

                    if ((input['value'] as double) <= 0) {
                      _showModernSnackBar('❌ Giá trị phải lớn hơn 0', isError: true);
                      return;
                    }

                    try {
                      final provider = Provider.of<VoucherProvider>(context, listen: false);
                      if (isEdit) {
                        await provider.updateVoucher(voucher!.id, input);
                      } else {
                        await provider.createVoucher(input);
                      }

                      Navigator.of(dialogContext).pop();

                      if (mounted) {
                        _refreshData();
                        _showModernSnackBar(
                          isEdit ? '✅ Cập nhật voucher thành công' : '✅ Tạo voucher thành công',
                          isSuccess: true,
                        );
                      }
                    } catch (e) {
                      Navigator.of(dialogContext).pop();

                      if (mounted) {
                        _showModernSnackBar(
                          e.toString().contains('duplicate')
                              ? '❌ Mã voucher đã tồn tại'
                              : '❌ Lỗi: $e',
                          isError: true,
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(isEdit ? 'Cập nhật' : 'Tạo mới'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      codeController.dispose();
      valueController.dispose();
      conditionController.dispose();
      validFromController.dispose();
      validToController.dispose();
    });
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF2196F3), size: 20),
          ),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildDialogDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF2196F3), size: 20),
          ),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getDisplayStatus(String status) {
    switch (status) {
      case 'active':
        return 'Hoạt động';
      case 'inactive':
        return 'Tạm dừng';
      default:
        return status;
    }
  }

  String _getDisplayType(String type) {
    switch (type) {
      case 'percentage':
        return 'Phần trăm';
      case 'fixed':
        return 'Giảm cố định';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Safe bottom padding
            sliver: SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FutureBuilder(
                    future: _fetchFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingState();
                      }

                      if (snapshot.hasError) {
                        return _buildErrorState();
                      }

                      return _buildContent();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditVoucherDialog(),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm Voucher'),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF2196F3),
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Quản lý Voucher',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
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
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _refreshData,
        ),
      ],
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
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
            ),
            SizedBox(height: 20),
            Text(
              'Đang tải danh sách voucher...',
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
              'Có lỗi xảy ra',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Không thể tải danh sách voucher',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<VoucherProvider>(
      builder: (context, provider, _) {
        final all = provider.vouchers;
        final filtered = _statusFilter == 'all'
            ? all
            : all.where((v) => v.status == _statusFilter).toList();

        return Column(
          children: [
            _buildStatisticsCard(all),
            const SizedBox(height: 16),
            _buildFilterCard(),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
              _buildEmptyState()
            else
              _buildVoucherList(filtered),
          ],
        );
      },
    );
  }

  Widget _buildStatisticsCard(List<Voucher> vouchers) {
    final activeCount = vouchers.where((v) => v.status == 'active').length;
    final inactiveCount = vouchers.where((v) => v.status == 'inactive').length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('Tổng số', vouchers.length, Icons.confirmation_number),
          ),
          Container(width: 1, height: 40, color: Colors.white30),
          Expanded(
            child: _buildStatItem('Hoạt động', activeCount, Icons.check_circle),
          ),
          Container(width: 1, height: 40, color: Colors.white30),
          Expanded(
            child: _buildStatItem('Tạm dừng', inactiveCount, Icons.pause_circle),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: Color(0xFF2196F3)),
          const SizedBox(width: 8),
          const Text(
            'Lọc theo trạng thái:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _statusFilter,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                DropdownMenuItem(value: 'active', child: Text('Đang hoạt động')),
                DropdownMenuItem(value: 'inactive', child: Text('Tạm dừng')),
              ],
              onChanged: (val) {
                if (val != null && mounted) {
                  setState(() => _statusFilter = val);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          Text(
            'Không có voucher nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy tạo voucher đầu tiên để bắt đầu',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherList(List<Voucher> vouchers) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vouchers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final voucher = vouchers[index];
        return _buildVoucherCard(voucher);
      },
    );
  }

  Widget _buildVoucherCard(Voucher voucher) {
    return Container(
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
      child: Column(
        children: [
          // Header với mã voucher và actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(voucher.status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(voucher.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.confirmation_number,
                    color: _getStatusColor(voucher.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voucher.code,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(voucher.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getDisplayStatus(voucher.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () => _showEditVoucherDialog(voucher: voucher),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _showDeleteConfirm(voucher.id),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Loại',
                        _getDisplayType(voucher.type),
                        Icons.category_outlined,
                        Colors.purple,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'Giá trị',
                        voucher.type == 'percentage'
                            ? '${voucher.value}%'
                            : '${NumberFormat('#,###').format(voucher.value)} VND',
                        Icons.monetization_on_outlined,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                if (voucher.conditions != null && voucher.conditions!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    'Điều kiện',
                    voucher.conditions!,
                    Icons.rule_outlined,
                    Colors.orange,
                    isFullWidth: true,
                  ),
                ],
                if (voucher.validFrom != null || voucher.validTo != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (voucher.validFrom != null)
                        Expanded(
                          child: _buildInfoItem(
                            'Từ ngày',
                            _formatDate(voucher.validFrom),
                            Icons.date_range,
                            Colors.blue,
                          ),
                        ),
                      if (voucher.validFrom != null && voucher.validTo != null)
                        const SizedBox(width: 12),
                      if (voucher.validTo != null)
                        Expanded(
                          child: _buildInfoItem(
                            'Đến ngày',
                            _formatDate(voucher.validTo),
                            Icons.event_busy,
                            Colors.red,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
      String label,
      String value,
      IconData icon,
      Color color, {
        bool isFullWidth = false,
      }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: isFullWidth
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      )
          : Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

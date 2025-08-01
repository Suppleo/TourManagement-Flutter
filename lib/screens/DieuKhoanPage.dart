import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DieuKhoanPage extends StatefulWidget {
  const DieuKhoanPage({super.key});

  @override
  State<DieuKhoanPage> createState() => _DieuKhoanPageState();
}

class _DieuKhoanPageState extends State<DieuKhoanPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      _buildHeroCard(),
                      const SizedBox(height: 24),
                      _buildPurposeSection(),
                      const SizedBox(height: 16),
                      _buildAccountSection(),
                      const SizedBox(height: 16),
                      _buildPrivacySection(),
                      const SizedBox(height: 16),
                      _buildBookingSection(),
                      const SizedBox(height: 16),
                      _buildPaymentSection(),
                      const SizedBox(height: 16),
                      _buildResponsibilitySection(),
                      const SizedBox(height: 16),
                      _buildUpdateSection(),
                      const SizedBox(height: 24),
                      _buildFooterCard(),
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
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF2196F3),
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Điều khoản & Quy định',
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
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.gavel, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Điều khoản & Quy định',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng đọc kỹ trước khi sử dụng dịch vụ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPurposeSection() {
    return _buildModernCard(
      title: 'Mục đích sử dụng',
      icon: Icons.flag_outlined,
      gradient: [Colors.blue, Colors.indigo],
      content: 'Ứng dụng được thiết kế nhằm hỗ trợ người dùng tìm kiếm, đặt tour và quản lý hành trình du lịch một cách tiện lợi, an toàn và minh bạch. Người dùng không được sử dụng ứng dụng vào các mục đích vi phạm pháp luật, gian lận hoặc gây ảnh hưởng tiêu cực đến hệ thống và các người dùng khác.',
    );
  }

  Widget _buildAccountSection() {
    return _buildModernCard(
      title: 'Quy định về tài khoản',
      icon: Icons.account_circle_outlined,
      gradient: [Colors.green, Colors.teal],
      content: '',
      children: [
        _buildBulletPoint('Người dùng cần cung cấp thông tin chính xác khi đăng ký tài khoản.'),
        _buildBulletPoint('Mỗi người dùng chỉ nên sử dụng một tài khoản cá nhân.'),
        _buildBulletPoint('Việc chia sẻ tài khoản hoặc sử dụng tài khoản người khác là vi phạm chính sách bảo mật.'),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return _buildModernCard(
      title: 'Bảo mật thông tin cá nhân',
      icon: Icons.security_outlined,
      gradient: [Colors.purple, Colors.deepPurple],
      content: 'Chúng tôi cam kết bảo mật mọi thông tin cá nhân bạn cung cấp. Dữ liệu của bạn sẽ chỉ được sử dụng cho mục đích vận hành ứng dụng như xử lý đặt tour, thanh toán, chăm sóc khách hàng và cải tiến trải nghiệm người dùng. Thông tin sẽ không được chia sẻ cho bên thứ ba nếu không có sự đồng ý của bạn.',
    );
  }

  Widget _buildBookingSection() {
    return _buildModernCard(
      title: 'Chính sách đặt tour',
      icon: Icons.tour_outlined,
      gradient: [Colors.orange, Colors.deepOrange],
      content: '',
      children: [
        _buildBulletPoint('Việc đặt tour được xem là hoàn tất khi người dùng nhận được xác nhận đặt chỗ từ hệ thống.'),
        _buildBulletPoint('Thông tin về tour, giá cả, thời gian và điều kiện áp dụng sẽ được hiển thị rõ ràng trước khi đặt.'),
        _buildBulletPoint('Người dùng cần kiểm tra kỹ thông tin trước khi thanh toán.'),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return _buildModernCard(
      title: 'Thanh toán & Hoàn tiền',
      icon: Icons.payment_outlined,
      gradient: [Colors.teal, Colors.cyan],
      content: '',
      children: [
        _buildBulletPoint('Mọi giao dịch thanh toán được thực hiện qua các cổng thanh toán bảo mật.'),
        _buildBulletPoint('Trường hợp hủy tour, người dùng cần tham khảo chính sách hoàn tiền cụ thể của từng tour.'),
        _buildBulletPoint('Một số khoản phí có thể không được hoàn lại (phí dịch vụ, phí chuyển khoản, v.v.)'),
      ],
    );
  }

  Widget _buildResponsibilitySection() {
    return _buildModernCard(
      title: 'Trách nhiệm người dùng',
      icon: Icons.assignment_ind_outlined,
      gradient: [Colors.red, Colors.pink],
      content: '',
      children: [
        _buildBulletPoint('Không được sử dụng nội dung trong ứng dụng để sao chép, phân phối hoặc sử dụng trái phép.'),
        _buildBulletPoint('Không gửi nội dung xấu, gây hại, spam hoặc giả mạo trong bất kỳ phần nào của ứng dụng.'),
        _buildBulletPoint('Mọi hành vi vi phạm sẽ bị xử lý theo quy định pháp luật và có thể dẫn đến khóa tài khoản vĩnh viễn.'),
      ],
    );
  }

  Widget _buildUpdateSection() {
    return _buildModernCard(
      title: 'Cập nhật và thay đổi',
      icon: Icons.update_outlined,
      gradient: [Colors.indigo, Colors.blue],
      content: 'Chúng tôi có quyền thay đổi, chỉnh sửa hoặc cập nhật nội dung của các điều khoản này mà không cần thông báo trước. Việc tiếp tục sử dụng ứng dụng sau khi có sự thay đổi đồng nghĩa với việc bạn đã đồng ý với các điều khoản mới nhất.',
    );
  }

  Widget _buildFooterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          const Text(
            'Cảm ơn bạn!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cảm ơn bạn đã sử dụng ứng dụng Tour Du Lịch.\nChúng tôi luôn nỗ lực mang lại trải nghiệm tốt nhất cho bạn!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required String content,
    List<Widget>? children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
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
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (content.isNotEmpty)
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                if (children != null) ...[
                  if (content.isNotEmpty) const SizedBox(height: 12),
                  ...children,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF2196F3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

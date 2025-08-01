import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

import '../../../providers/tour_provider.dart';
import '../../../providers/category_provider.dart';

const String uploadServer = 'http://172.27.145.10:4000';

class CreateTourScreen extends StatefulWidget {
  const CreateTourScreen({super.key});

  @override
  State<CreateTourScreen> createState() => _CreateTourScreenState();
}

class _CreateTourScreenState extends State<CreateTourScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String title = '';
  String location = '';
  double price = 0;
  String itinerary = '';
  String servicesIncluded = '';
  String servicesExcluded = '';
  String cancelPolicy = '';
  String? categoryId;

  List<String> images = [];
  List<String> videos = [];
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<CategoryProvider>().fetchCategories();

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
    _scrollController.dispose();
    super.dispose();
  }

  void _showModernSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
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
  }

  Future<List<String>> pickAndUploadMedia({required bool isImage}) async {
    if (!mounted) return [];

    setState(() => _isUploading = true);

    try {
      List<XFile>? files;

      if (isImage) {
        files = await _picker.pickMultiImage();
      } else {
        final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
        if (video != null) files = [video];
      }

      if (files == null || files.isEmpty) {
        if (mounted) setState(() => _isUploading = false);
        return [];
      }

      List<String> urls = [];
      List<String> failedFiles = [];

      for (var file in files) {
        if (!mounted) break;

        try {
          final response = await _uploadWithRetry(file.path, file.name);

          if (response != null && response.statusCode == 200) {
            final urlsFromServer = response.data['urls'];
            if (urlsFromServer is List && urlsFromServer.isNotEmpty) {
              final uploadedUrl = urlsFromServer.first.toString();
              urls.add(uploadedUrl);
              debugPrint('✅ Upload thành công: $uploadedUrl');
            } else {
              failedFiles.add(file.name);
            }
          } else {
            failedFiles.add(file.name);
          }
        } catch (fileError) {
          debugPrint('❌ Upload file ${file.name} failed: $fileError');
          failedFiles.add(file.name);
        }
      }

      if (mounted) {
        if (urls.isNotEmpty) {
          _showModernSnackBar('✅ Upload thành công ${urls.length} file', isSuccess: true);
        }
        if (failedFiles.isNotEmpty) {
          _showModernSnackBar('⚠️ ${failedFiles.length} file upload thất bại', isError: true);
        }
        if (urls.isEmpty && failedFiles.isEmpty) {
          _showModernSnackBar('❌ Không có file nào được upload', isError: true);
        }
      }

      return urls;
    } catch (e) {
      debugPrint('❌ Upload failed: $e');
      if (mounted) {
        _showModernSnackBar('Lỗi upload: ${_getErrorMessage(e)}', isError: true);
      }
      return [];
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  MediaType? _lookupMimeType(String path) {
    final mime = lookupMimeType(path);
    if (mime != null) {
      final parts = mime.split('/');
      return MediaType(parts[0], parts[1]);
    }
    return null;
  }

  Future<Response?> _uploadWithRetry(String filePath, String fileName, {int maxRetries = 2}) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('🔄 Upload attempt ${attempt + 1} for $fileName');

        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            filePath,
            filename: fileName,
            contentType: _lookupMimeType(filePath),
          ),
        });

        final response = await Dio().post(
          '$uploadServer/api/upload',
          data: formData,
          options: Options(
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            headers: {
              'Connection': 'keep-alive',
            },
          ),
        );

        return response;
      } catch (e) {
        debugPrint('❌ Upload attempt ${attempt + 1} failed for $fileName: $e');
        if (attempt == maxRetries) rethrow;
        await Future.delayed(Duration(seconds: (attempt + 1) * 2));
      }
    }
    return null;
  }

  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Kết nối timeout. Server có thể đang chậm.';
        case DioExceptionType.connectionError:
          return 'Server không phản hồi. Kiểm tra server có đang chạy?';
        case DioExceptionType.badResponse:
          return 'Server lỗi: ${error.response?.statusCode ?? 'Không rõ'}';
        default:
          return 'Lỗi mạng không xác định';
      }
    }
    return error.toString().length > 100 ? '${error.toString().substring(0, 100)}...' : error.toString();
  }

  String buildImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return 'https://via.placeholder.com/400x200.png?text=No+Image';
    }
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    final baseUrl = uploadServer;
    final cleanPath = imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;

    if (cleanPath.startsWith('uploads/')) {
      return '$baseUrl/$cleanPath';
    } else {
      return '$baseUrl/uploads/$cleanPath';
    }
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    final tourProvider = context.read<TourProvider>();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
            ),
            const SizedBox(height: 20),
            Text(
              'Đang tạo tour...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      await tourProvider.createTour({
        'title': title,
        'location': location,
        'price': price,
        'itinerary': itinerary,
        'servicesIncluded': servicesIncluded.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'servicesExcluded': servicesExcluded.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'cancelPolicy': cancelPolicy,
        'images': images,
        'videos': videos,
        'category': {'id': categoryId},
      });

      if (mounted) {
        Navigator.of(context).pop();
        _showModernSnackBar('✅ Tạo tour thành công', isSuccess: true);
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showModernSnackBar('❌ Lỗi khi tạo tour: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // 👈 Safe bottom padding
            sliver: SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildHeroCard(),
                        const SizedBox(height: 20),
                        _buildBasicInfoCard(),
                        const SizedBox(height: 16),
                        _buildDetailsCard(),
                        const SizedBox(height: 16),
                        _buildMediaSection(),
                        const SizedBox(height: 16),
                        _buildCategoryCard(),
                        const SizedBox(height: 24),
                        _buildSubmitButton(),
                      ],
                    ),
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
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Tạo Tour Mới',
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
            child: const Icon(Icons.tour, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tạo trải nghiệm du lịch tuyệt vời',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Điền thông tin chi tiết để tạo tour hấp dẫn',
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

  Widget _buildBasicInfoCard() {
    return _buildModernCard(
      title: 'Thông Tin Cơ Bản',
      icon: Icons.info_outline,
      gradient: [Colors.blue, Colors.indigo],
      children: [
        _buildModernTextField(
          label: 'Tên tour',
          icon: Icons.tour,
          required: true,
          onSave: (val) => title = val,
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          label: 'Địa điểm',
          icon: Icons.location_on,
          onSave: (val) => location = val,
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          label: 'Giá (USD)',
          icon: Icons.attach_money,
          keyboardType: TextInputType.number,
          onSave: (val) => price = double.tryParse(val) ?? 0,
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return _buildModernCard(
      title: 'Chi Tiết Tour',
      icon: Icons.description_outlined,
      gradient: [Colors.green, Colors.teal],
      children: [
        _buildModernTextField(
          label: 'Lịch trình',
          icon: Icons.schedule,
          maxLines: 3,
          onSave: (val) => itinerary = val,
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          label: 'Dịch vụ bao gồm (cách nhau bằng dấu phẩy)',
          icon: Icons.check_circle_outline,
          maxLines: 2,
          onSave: (val) => servicesIncluded = val,
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          label: 'Dịch vụ không bao gồm',
          icon: Icons.cancel_outlined,
          maxLines: 2,
          onSave: (val) => servicesExcluded = val,
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          label: 'Chính sách hủy',
          icon: Icons.policy_outlined,
          maxLines: 2,
          onSave: (val) => cancelPolicy = val,
        ),
      ],
    );
  }

  Widget _buildMediaSection() {
    return Column(
      children: [
        _buildModernCard(
          title: 'Hình Ảnh',
          icon: Icons.image_outlined,
          gradient: [Colors.purple, Colors.deepPurple],
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildModernButton(
                    icon: Icons.add_photo_alternate,
                    label: _isUploading ? 'Đang tải...' : 'Chọn ảnh',
                    count: images.length,
                    isLoading: _isUploading,
                    onPressed: () async {
                      final result = await pickAndUploadMedia(isImage: true);
                      if (mounted) {
                        setState(() => images.addAll(result));
                      }
                    },
                  ),
                ),
              ],
            ),
            if (images.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildMediaPreview(images, isImage: true),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _buildModernCard(
          title: 'Video',
          icon: Icons.videocam_outlined,
          gradient: [Colors.orange, Colors.deepOrange],
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildModernButton(
                    icon: Icons.video_library,
                    label: _isUploading ? 'Đang tải...' : 'Chọn video',
                    count: videos.length,
                    isLoading: _isUploading,
                    onPressed: () async {
                      final result = await pickAndUploadMedia(isImage: false);
                      if (mounted) {
                        setState(() => videos.addAll(result));
                      }
                    },
                  ),
                ),
              ],
            ),
            if (videos.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildMediaPreview(videos, isImage: false),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard() {
    final categories = context.watch<CategoryProvider>().categories;

    return _buildModernCard(
      title: 'Danh Mục',
      icon: Icons.category_outlined,
      gradient: [Colors.indigo, Colors.blue],
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonFormField<String>(
            value: categoryId,
            decoration: const InputDecoration(
              labelText: 'Chọn danh mục',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              prefixIcon: Icon(Icons.category, color: Color(0xFF2196F3)),
            ),
            items: categories.map((cat) {
              return DropdownMenuItem(
                value: cat.id,
                child: Text(cat.name),
              );
            }).toList(),
            onChanged: (val) => setState(() => categoryId = val),
            validator: (val) => val == null ? 'Hãy chọn danh mục' : null,
          ),
        ),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required String label,
    required IconData icon,
    required Function(String) onSave,
    bool required = false,
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
        onSaved: (val) => onSave(val ?? ''),
        validator: required
            ? (val) => val == null || val.isEmpty ? 'Không được bỏ trống' : null
            : null,
      ),
    );
  }

  Widget _buildModernButton({
    required IconData icon,
    required String label,
    required int count,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : Icon(icon),
        label: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview(List<String> urls, {required bool isImage}) {
    if (urls.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final url = urls[index];
          return _buildMediaTile(url, index, urls, isImage);
        },
      ),
    );
  }

  Widget _buildMediaTile(String url, int index, List<String> urls, bool isImage) {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isImage
                ? Image.network(
              buildImageUrl(url),
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildErrorTile(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildLoadingTile();
              },
            )
                : _buildVideoTile(),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => urls.removeAt(index)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorTile() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.grey[600], size: 32),
          const SizedBox(height: 4),
          Text(
            'Lỗi ảnh',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingTile() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildVideoTile() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[300]!, Colors.grey[400]!],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_outline, size: 40, color: Colors.white),
          SizedBox(height: 4),
          Text('Video', style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _handleSubmit,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text(
          'Tạo Tour',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../../models/tour.dart';
import '../../../providers/tour_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../core/network/api_config.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class AdminTourDetailScreen extends StatefulWidget {
  final String tourId;
  const AdminTourDetailScreen({super.key, required this.tourId});

  @override
  State<AdminTourDetailScreen> createState() => _AdminTourDetailScreenState();
}

class _AdminTourDetailScreenState extends State<AdminTourDetailScreen>
    with SingleTickerProviderStateMixin {
  bool isEditing = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  late TextEditingController titleController;
  late TextEditingController locationController;
  late TextEditingController priceController;
  late TextEditingController itineraryController;
  late TextEditingController servicesIncludedController;
  late TextEditingController servicesExcludedController;
  late TextEditingController cancelPolicyController;
  String? categoryId;

  List<String> images = [];
  List<String> videos = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    titleController.dispose();
    locationController.dispose();
    priceController.dispose();
    itineraryController.dispose();
    servicesIncludedController.dispose();
    servicesExcludedController.dispose();
    cancelPolicyController.dispose();
    super.dispose();
  }

  void _initializeData() {
    final tour = context.read<TourProvider>().tours.firstWhere(
          (t) => t.id == widget.tourId,
      orElse: () => Tour(id: '', title: '', price: 0),
    );

    context.read<CategoryProvider>().fetchCategories();

    titleController = TextEditingController(text: tour.title);
    locationController = TextEditingController(text: tour.location ?? '');
    priceController = TextEditingController(text: tour.price.toString());
    itineraryController = TextEditingController(text: tour.itinerary ?? '');
    servicesIncludedController = TextEditingController(
      text: tour.servicesIncluded?.join(', ') ?? '',
    );
    servicesExcludedController = TextEditingController(
      text: tour.servicesExcluded?.join(', ') ?? '',
    );
    cancelPolicyController = TextEditingController(text: tour.cancelPolicy ?? '');
    categoryId = tour.category?.id;
    images = List.from(tour.images ?? []);
    videos = List.from(tour.videos ?? []);
  }

  Future<List<String>> pickAndUploadMedia({required bool isImage}) async {
    setState(() => _isLoading = true);

    try {
      final picker = ImagePicker();
      final picked = isImage
          ? await picker.pickMultiImage()
          : [await picker.pickVideo(source: ImageSource.gallery)];

      List<String> uploadedUrls = [];

      for (var file in picked.whereType<XFile>()) {
        final mime = lookupMimeType(file.path);
        final mediaType = mime != null ? MediaType.parse(mime) : null;

        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            file.path,
            filename: file.name,
            contentType: mediaType,
          ),
        });

        final res = await Dio().post(
          'http://172.27.145.10:4000/api/upload',
          data: formData,
        );

        if (res.statusCode == 200) {
          final urls = res.data['urls'];
          if (urls is List && urls.isNotEmpty) {
            uploadedUrls.addAll(urls.cast<String>());
          }
        }
      }

      return uploadedUrls;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi upload: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String buildImageUrl(String? imageUrl) {
    const baseUrl = 'http://172.27.145.10:4000';

    if (imageUrl == null || imageUrl.trim().isEmpty || imageUrl == 'null') {
      return '';
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    final cleanPath = imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;

    if (cleanPath.startsWith('uploads/')) {
      return '$baseUrl/$cleanPath';
    } else {
      return '$baseUrl/uploads/$cleanPath';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tourProvider = context.read<TourProvider>();
    final tour = tourProvider.tours.firstWhere(
          (t) => t.id == widget.tourId,
      orElse: () => Tour(id: '', title: '', price: 0),
    );

    if (tour.id.isEmpty) {
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(tour, tourProvider), // ✅ Đổi về AppBar thường
      body: isEditing ? _buildEditForm(tourProvider) : _buildReadOnlyView(tour),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Tour không tồn tại'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/tours'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.error.withOpacity(0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Không tìm thấy tour',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Tour có thể đã bị xóa hoặc không tồn tại trong hệ thống',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/admin/tours'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại danh sách'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ AppBar thường thay vì SliverAppBar
  PreferredSizeWidget _buildAppBar(Tour tour, TourProvider tourProvider) {
    return AppBar(
      title: Container(
        width: double.infinity,
        child: Text(
          isEditing ? 'Chỉnh Sửa Tour' : tour.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 2, // ✅ Cho phép 2 dòng
          overflow: TextOverflow.ellipsis,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/admin/tours'),
      ),
      actions: [
        if (!isEditing) ...[
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Chỉnh sửa',
            onPressed: () => setState(() => isEditing = true),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete(context, tourProvider);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Xóa tour',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                ),
              ),
            ],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ] else ...[
          TextButton(
            onPressed: () => setState(() => isEditing = false),
            child: const Text('Hủy'),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _handleSave(tourProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text('Lưu'),
            ),
          ),
        ],
      ],
      bottom: isEditing
          ? PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start, // ✅ Align start để tránh overflow
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), // ✅ Smaller font
            unselectedLabelStyle: const TextStyle(fontSize: 14),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 18),
                    SizedBox(width: 6),
                    Text('Thông tin'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.description_outlined, size: 18),
                    SizedBox(width: 6),
                    Text('Chi tiết'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_library_outlined, size: 18),
                    SizedBox(width: 6),
                    Text('Media'),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
          : null,
    );
  }

  Widget _buildEditForm(TourProvider provider) {
    return Form(
      key: _formKey,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildBasicInfoTab(),
          _buildDetailsTab(),
          _buildMediaTab(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    final categories = context.watch<CategoryProvider>().categories;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16), // ✅ Giảm padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Thông Tin Cơ Bản',
            icon: Icons.info_outline,
            color: Colors.blue,
            children: [
              _buildTextField(
                'Tên Tour *',
                titleController,
                required: true,
                icon: Icons.tour,
              ),
              const SizedBox(height: 16), // ✅ Giảm spacing
              _buildTextField(
                'Địa Điểm',
                locationController,
                icon: Icons.location_on,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Giá (USD) *',
                priceController,
                keyboardType: TextInputType.number,
                required: true,
                icon: Icons.attach_money,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: categoryId,
                decoration: _buildInputDecoration('Danh Mục *', Icons.category),
                items: categories
                    .map((cat) => DropdownMenuItem(
                  value: cat.id,
                  child: Text(
                    cat.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
                    .toList(),
                onChanged: (val) => setState(() => categoryId = val),
                validator: (val) => val == null ? 'Vui lòng chọn danh mục' : null,
                isExpanded: true,
                dropdownColor: Theme.of(context).colorScheme.surface,
              ),
            ],
          ),
          const SizedBox(height: 80), // ✅ Extra space để tránh bottom overflow
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionCard(
            title: 'Lịch Trình & Dịch Vụ',
            icon: Icons.schedule,
            color: Colors.green,
            children: [
              _buildTextField(
                'Lịch Trình',
                itineraryController,
                maxLines: 3, // ✅ Giảm maxLines
                icon: Icons.map,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Dịch Vụ Bao Gồm (phân cách bằng dấu phẩy)',
                servicesIncludedController,
                maxLines: 2, // ✅ Giảm maxLines
                icon: Icons.check_circle,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Dịch Vụ Không Bao Gồm (phân cách bằng dấu phẩy)',
                servicesExcludedController,
                maxLines: 2, // ✅ Giảm maxLines
                icon: Icons.cancel,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Chính Sách Hủy',
                cancelPolicyController,
                maxLines: 2, // ✅ Giảm maxLines
                icon: Icons.policy,
              ),
            ],
          ),
          const SizedBox(height: 80), // ✅ Extra space
        ],
      ),
    );
  }

  Widget _buildMediaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionCard(
            title: 'Hình Ảnh',
            icon: Icons.photo_library,
            color: Colors.purple,
            children: [
              _buildMediaPicker('Ảnh', images, isImage: true),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Video',
            icon: Icons.videocam,
            color: Colors.orange,
            children: [
              _buildMediaPicker('Video', videos, isImage: false),
            ],
          ),
          const SizedBox(height: 80), // ✅ Extra space
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8), // ✅ Thêm margin bottom
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12), // ✅ Giảm border radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, // ✅ Giảm blur
            offset: const Offset(0, 2), // ✅ Giảm offset
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16), // ✅ Giảm padding
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6), // ✅ Giảm padding
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18), // ✅ Giảm icon size
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith( // ✅ Smaller title
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16), // ✅ Giảm padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        bool required = false,
        TextInputType? keyboardType,
        int maxLines = 1,
        IconData? icon,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: _buildInputDecoration(label, icon),
      validator: required
          ? (val) => val == null || val.isEmpty ? 'Không được để trống' : null
          : null,
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14), // ✅ Smaller label
      prefixIcon: icon != null
          ? Container(
        margin: const EdgeInsets.all(6), // ✅ Giảm margin
        padding: const EdgeInsets.all(6), // ✅ Giảm padding
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18), // ✅ Giảm icon size
      )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), // ✅ Giảm border radius
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // ✅ Giảm padding
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      isDense: true, // ✅ Make input more compact
    );
  }

  Widget _buildMediaPicker(String label, List<String> urls, {required bool isImage}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () async {
                  final result = await pickAndUploadMedia(isImage: isImage);
                  setState(() => urls.addAll(result));
                },
                icon: _isLoading
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Icon(isImage ? Icons.add_photo_alternate : Icons.videocam, size: 18), // ✅ Smaller icon
                label: Text('Thêm ${isImage ? 'ảnh' : 'video'}', style: const TextStyle(fontSize: 14)), // ✅ Smaller text
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // ✅ Smaller padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // ✅ Smaller padding
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${urls.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12, // ✅ Smaller font
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (urls.isNotEmpty)
          Container(
            height: 100, // ✅ Giảm height
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              scrollDirection: Axis.horizontal,
              itemCount: urls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                return Stack(
                  children: [
                    _buildMediaItem(urls[i], isImage),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => setState(() => urls.removeAt(i)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 12, // ✅ Smaller close icon
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMediaItem(String url, bool isImage) {
    if (isImage) {
      final imageUrl = buildImageUrl(url);
      if (imageUrl.isEmpty) {
        return Container(
          width: 80, // ✅ Smaller size
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: const Center(
            child: Icon(Icons.image_not_supported, color: Colors.grey, size: 20), // ✅ Smaller icon
          ),
        );
      }
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lỗi',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
          ),
        ),
      );
    } else {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_outlined,
              size: 20,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 2),
            Text(
              'Video',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildReadOnlyView(Tour tour) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(tour),
          const SizedBox(height: 16),
          _buildDetailsCard(tour),
          const SizedBox(height: 16),
          _buildMediaCard(tour),
          const SizedBox(height: 16),
          _buildMetadataCard(tour),
          const SizedBox(height: 60), // ✅ Extra bottom padding
        ],
      ),
    );
  }

  // ... Các widget còn lại giữ nguyên như trước với các adjustments tương tự để giảm kích thước và tránh overflow

  Widget _buildInfoCard(Tour tour) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Thông Tin Cơ Bản',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('Địa điểm', tour.location ?? 'Không rõ', Icons.location_on_outlined),
                _buildInfoRow('Giá', '\$${tour.price.toStringAsFixed(0)}', Icons.attach_money_outlined),
                _buildInfoRow('Danh mục', tour.category?.name ?? 'Chưa có', Icons.category_outlined),
                _buildInfoRow('Trạng thái', tour.status ?? 'Không rõ', Icons.info_outlined, isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {bool isLast = false}) {
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tiếp tục với các methods còn lại...
  void _handleSave(TourProvider provider) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final price = double.tryParse(priceController.text) ?? 0;
        await provider.updateTour(widget.tourId, {
          'title': titleController.text,
          'location': locationController.text,
          'price': price,
          'itinerary': itineraryController.text,
          'servicesIncluded': servicesIncludedController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          'servicesExcluded': servicesExcludedController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          'cancelPolicy': cancelPolicyController.text,
          'images': images,
          'videos': videos,
          'category': categoryId,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Cập nhật tour thành công!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          setState(() => isEditing = false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Lỗi cập nhật: $e')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmDelete(BuildContext context, TourProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_outlined,
                color: Theme.of(context).colorScheme.error,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Xác Nhận Xóa', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa tour này không?\n\nHành động này không thể hoàn tác!',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await provider.deleteTour(widget.tourId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Xóa tour thành công!'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  context.go('/admin/tours');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Lỗi xóa tour: $e')),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(Tour tour) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
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
                    color: Colors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.description_outlined, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Chi Tiết Tour',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildDetailSection('Lịch trình', tour.itinerary, Icons.map_outlined),
                _buildDetailSection('Dịch vụ bao gồm', null, Icons.check_circle_outline,
                    items: tour.servicesIncluded),
                _buildDetailSection('Dịch vụ không bao gồm', null, Icons.cancel_outlined,
                    items: tour.servicesExcluded),
                _buildDetailSection('Chính sách hủy', tour.cancelPolicy, Icons.policy_outlined, isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCard(Tour tour) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
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
                    color: Colors.purple.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: Colors.purple, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hình Ảnh & Video',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tour.images != null && tour.images!.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.image_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Hình ảnh (${tour.images!.length})',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      scrollDirection: Axis.horizontal,
                      itemCount: tour.images!.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => _buildMediaItem(tour.images![i], true),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (tour.videos != null && tour.videos!.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.videocam_outlined, size: 18, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Video (${tour.videos!.length})',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: tour.videos!
                        .map((url) => Container(
                      width: 80,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Icon(
                        Icons.videocam_outlined,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 20,
                      ),
                    ))
                        .toList(),
                  ),
                ],
                if ((tour.images?.isEmpty ?? true) && (tour.videos?.isEmpty ?? true))
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 32,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chưa có hình ảnh hoặc video nào',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard(Tour tour) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
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
                    color: Colors.orange.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.schedule_outlined, color: Colors.orange, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Thông Tin Thời Gian',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoRow('Ngày tạo', tour.createdAt ?? 'Không rõ', Icons.add_circle_outline),
                _buildInfoRow('Cập nhật lần cuối', tour.updatedAt ?? 'Không rõ', Icons.update_outlined, isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(
      String title,
      String? content,
      IconData icon, {
        List<String>? items,
        bool isLast = false,
      }) {
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items != null && items.isNotEmpty)
            ...items.map((item) => Container(
              margin: const EdgeInsets.only(left: 30, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 8, right: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ))
          else if (content != null && content.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 30),
              child: Text(
                content,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(left: 30),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Không có thông tin',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/review_provider.dart';

class MyReviewScreen extends StatefulWidget {
  const MyReviewScreen({super.key});

  @override
  State<MyReviewScreen> createState() => _MyReviewScreenState();
}

class _MyReviewScreenState extends State<MyReviewScreen> {
  String? selectedTourId;
  int rating = 5;
  String comment = '';
  List<File> images = [];

  bool isSubmitting = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final bookingProvider = context.read<BookingProvider>();
      final reviewProvider = context.read<ReviewProvider>();

      await Future.wait([
        bookingProvider.fetchBookings(),
        reviewProvider.fetchReviews(),
      ]);
    } catch (e) {
      debugPrint('❌ Error loading data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        images.addAll(picked.map((e) => File(e.path)));
      });
    }
  }

  void removeImage(int index) {
    setState(() {
      images.removeAt(index);
    });
  }

  Future<List<String>> uploadImages(List<File> files) async {
    List<String> urls = [];

    for (var file in files) {
      final fileName = file.path.split('/').last;

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await Dio().post(
        'http://10.0.2.2:4000/api/upload', // 🔁 Đổi nếu dùng server thật
        data: formData,
      );

      if (response.statusCode == 200) {
        final url = response.data['url'] ?? response.data['path'];
        urls.add(url);
      }
    }

    return urls;
  }

  Future<void> handleSubmit() async {
    if (selectedTourId == null) {
      _showSnackbar('Hãy chọn tour cần đánh giá');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final reviewProvider = context.read<ReviewProvider>();

    final alreadyReviewed = reviewProvider.reviews.any((r) =>
    r.user?.id == authProvider.user?.id &&
        r.tour?.id == selectedTourId);

    if (alreadyReviewed) {
      _showSnackbar('Bạn đã đánh giá tour này rồi');
      return;
    }

    try {
      setState(() => isSubmitting = true);

      final uploadedUrls = await uploadImages(images);

      await reviewProvider.createReview(
        tourId: selectedTourId!,
        rating: rating,
        comment: comment,
        images: uploadedUrls,
      );

      await reviewProvider.fetchReviews();

      setState(() {
        selectedTourId = null;
        comment = '';
        rating = 5;
        images.clear();
      });

      _showSnackbar('✅ Đánh giá thành công');
    } catch (e) {
      _showSnackbar('❌ Lỗi khi gửi đánh giá: $e');
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _showSnackbar(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final bookingProvider = context.watch<BookingProvider>();
    final reviewProvider = context.watch<ReviewProvider>();

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final reviewedTourIds = reviewProvider.reviews
        .where((r) => r.user?.id == authProvider.user?.id && r.tour?.id != null)
        .map((r) => r.tour!.id)
        .toSet();

    final toursToReview = bookingProvider.bookings
        .where((b) =>
    b.user?.id == authProvider.user?.id &&
        b.paymentStatus == 'completed' &&
        b.tour?.id != null &&
        !reviewedTourIds.contains(b.tour!.id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('📝 Viết đánh giá')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chọn tour', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedTourId,
              hint: const Text('-- Chọn tour đã thanh toán --'),
              items: toursToReview.map((b) {
                final id = b.tour!.id;
                return DropdownMenuItem(
                  value: id,
                  child: Text(b.tour?.title ?? 'Unnamed Tour'),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedTourId = value),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            if (toursToReview.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '✔️ Bạn đã đánh giá tất cả tour đã thanh toán.',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            const SizedBox(height: 20),

            Text('Đánh giá sao', style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    Icons.star,
                    color: index < rating ? Colors.amber : Colors.grey.shade400,
                  ),
                  onPressed: () => setState(() => rating = index + 1),
                );
              }),
            ),
            const SizedBox(height: 20),

            Text('Viết đánh giá', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Hãy chia sẻ trải nghiệm của bạn...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => comment = value,
            ),
            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: pickImages,
              icon: const Icon(Icons.image),
              label: const Text('Chọn ảnh'),
            ),
            const SizedBox(height: 8),
            if (images.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: images.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: -8,
                        top: -8,
                        child: IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => removeImage(index),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),

            const SizedBox(height: 30),
            FilledButton.icon(
              onPressed: isSubmitting || toursToReview.isEmpty ? null : handleSubmit,
              icon: const Icon(Icons.send),
              label: Text(isSubmitting ? 'Đang gửi...' : 'Gửi đánh giá'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }
}

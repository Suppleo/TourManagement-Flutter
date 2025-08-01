import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/tour_provider.dart';
import '../../../widgets/tour_card.dart';

class ManageTourScreen extends StatefulWidget {
  const ManageTourScreen({super.key});

  @override
  State<ManageTourScreen> createState() => _ManageTourScreenState();
}

class _ManageTourScreenState extends State<ManageTourScreen> {
  final TextEditingController _searchController = TextEditingController();
  String search = '';
  int page = 1;
  final int pageSize = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TourProvider>().fetchTours();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tourProvider = context.watch<TourProvider>();
    final allTours = tourProvider.tours;

    final filteredTours = allTours
        .where((tour) => tour.title.toLowerCase().contains(search.toLowerCase()))
        .toList();

    final totalPages = (filteredTours.length / pageSize).ceil().clamp(1, 999);
    final paginatedTours = filteredTours
        .skip((page - 1) * pageSize)
        .take(pageSize)
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Quản Lý Tours',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: () => context.read<TourProvider>().fetchTours(),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/admin/tours/create'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tạo Tour'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tour theo tên...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: search.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      search = '';
                      page = 1;
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) => setState(() {
                search = value;
                page = 1;
              }),
            ),
          ),

          // Stats Bar
          if (allTours.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Tổng: ${allTours.length} tours',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (search.isNotEmpty) ...[
                    const Text(' • '),
                    Text(
                      'Hiển thị: ${filteredTours.length}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (totalPages > 1)
                    Text(
                      'Trang $page/$totalPages',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: tourProvider.isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải danh sách tours...'),
                ],
              ),
            )
                : filteredTours.isEmpty
                ? _buildEmptyState()
                : Column( // ✅ Đổi lại thành Column
              children: [
                // Tour List
                Expanded( // ✅ Wrap ListView trong Expanded
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120), // hoặc MediaQuery.of(context).padding.bottom + 64
                    // ✅ Bỏ bottom padding
                    itemCount: paginatedTours.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final tour = paginatedTours[index];
                      return TourCard(
                        tour: tour,
                        onTap: () => context.push('/admin/tours/${tour.id}'),
                      );
                    },
                  ),
                ),

                // Pagination - ✅ Đặt ở cuối Column
                if (totalPages > 1)
                  _buildPagination(totalPages),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              search.isNotEmpty ? Icons.search_off : Icons.tour_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              search.isNotEmpty ? 'Không tìm thấy tour nào' : 'Chưa có tour nào',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              search.isNotEmpty
                  ? 'Thử thay đổi từ khóa tìm kiếm'
                  : 'Tạo tour đầu tiên để bắt đầu',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            if (search.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push('/admin/tours/create'),
                icon: const Icon(Icons.add),
                label: const Text('Tạo Tour Đầu Tiên'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      width: double.infinity, // ✅ Đảm bảo full width
      padding: const EdgeInsets.all(16), // ✅ Consistent padding
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: page > 1 ? () => setState(() => page--) : null,
            icon: const Icon(Icons.chevron_left, size: 18), // ✅ Smaller icon
            label: const Text('Trước'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // ✅ Compact padding
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Trang $page / $totalPages',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 14, // ✅ Consistent font size
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: page < totalPages ? () => setState(() => page++) : null,
            icon: const Icon(Icons.chevron_right, size: 18), // ✅ Smaller icon
            label: const Text('Sau'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // ✅ Compact padding
            ),
          ),
        ],
      ),
    );
  }
}

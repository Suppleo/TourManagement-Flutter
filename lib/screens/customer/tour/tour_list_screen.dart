import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/tour_provider.dart';
import '../../../models/tour.dart';
import '../../../widgets/tour_card.dart';

class TourListScreen extends StatefulWidget {
  const TourListScreen({super.key});

  @override
  State<TourListScreen> createState() => _TourListScreenState();
}

class _TourListScreenState extends State<TourListScreen>
    with TickerProviderStateMixin {
  String search = '';
  String categoryFilter = '';
  String priceFilter = '';
  String locationFilter = '';
  String statusFilter = '';
  int page = 1;
  final int pageSize = 6;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  bool _isFilterExpanded = false;

  // Blue color scheme
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color lightBlue = Color(0xFF64B5F6);
  static const Color darkBlue = Color(0xFF1976D2);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();

    // ✅ Thêm vào đây để delay gọi sau khi widget đã render xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TourProvider>(context, listen: false).fetchTours();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Tour> _filterTours(List<Tour> tours) {
    var filteredTours = tours.where((tour) {
      // Search filter
      final matchesSearch = search.isEmpty ||
          tour.title.toLowerCase().contains(search.toLowerCase()) ||
          tour.location?.toLowerCase().contains(search.toLowerCase()) == true ||
          tour.category?.name?.toLowerCase().contains(search.toLowerCase()) == true;

      // Category filter
      final matchesCategory = categoryFilter.isEmpty || tour.category?.name == categoryFilter;

      // Location filter
      final matchesLocation = locationFilter.isEmpty ||
          tour.location?.toLowerCase().contains(locationFilter.toLowerCase()) == true;

      // Status filter
      final matchesStatus = statusFilter.isEmpty ||
          (statusFilter == 'active' && tour.status?.toLowerCase() == 'active') ||
          (statusFilter == 'inactive' && tour.status?.toLowerCase() != 'active') ||
          (statusFilter == 'available' && tour.status?.toLowerCase() == 'active' && (tour.isDeleted == null || tour.isDeleted == false));

      // Price filter
      final matchesPrice = priceFilter.isEmpty ||
          (priceFilter == 'free' && (tour.price == null || tour.price == 0)) ||
          (priceFilter == 'low' && tour.price != null && tour.price! > 0 && tour.price! <= 500) ||
          (priceFilter == 'medium' && tour.price != null && tour.price! > 500 && tour.price! <= 1000) ||
          (priceFilter == 'high' && tour.price != null && tour.price! > 1000 && tour.price! <= 2000) ||
          (priceFilter == 'premium' && tour.price != null && tour.price! > 2000);

      return matchesSearch && matchesCategory && matchesLocation && matchesStatus && matchesPrice;
    }).toList();

    return filteredTours;
  }

  void _clearFilters() {
    setState(() {
      search = '';
      categoryFilter = '';
      priceFilter = '';
      locationFilter = '';
      statusFilter = '';
      page = 1;
      _searchController.clear();
    });
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (search.isNotEmpty) count++;
    if (categoryFilter.isNotEmpty) count++;
    if (priceFilter.isNotEmpty) count++;
    if (locationFilter.isNotEmpty) count++;
    if (statusFilter.isNotEmpty) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TourProvider>(context);
    final allTours = provider.tours;
    final categories = allTours.map((e) => e.category?.name).whereType<String>().toSet().toList();
    final locations = allTours.map((e) => e.location).whereType<String>().toSet().toList();
    final filteredTours = _filterTours(allTours);
    final totalPages = (filteredTours.length / pageSize).ceil();
    final paginatedTours = filteredTours.skip((page - 1) * pageSize).take(pageSize).toList();
    final activeFilterCount = _getActiveFilterCount();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: CustomScrollView(
        slivers: [
          // === CUSTOM APP BAR ===
          _buildSliverAppBar(filteredTours.length, activeFilterCount),

          // === MAIN CONTENT ===
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // === SEARCH & FILTER SECTION ===
                    _buildSearchAndFilterSection(categories, locations),

                    // === ACTIVE FILTERS DISPLAY ===
                    if (activeFilterCount > 0) _buildActiveFilters(),

                    // === RESULTS HEADER ===
                    _buildResultsHeader(filteredTours.length),

                    // === TOUR LIST ===
                    _buildTourList(provider, filteredTours, paginatedTours),

                    // === PAGINATION ===
                    if (totalPages > 1) _buildPagination(totalPages),

                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === CUSTOM APP BAR ===
  Widget _buildSliverAppBar(int totalResults, int activeFilterCount) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryBlue, lightBlue],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.explore,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Khám phá Tour',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '$totalResults tours được tìm thấy',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.travel_explore,
              color: primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Tours',
            style: TextStyle(
              color: primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: activeFilterCount > 0
                      ? const LinearGradient(colors: [primaryBlue, lightBlue])
                      : null,
                  color: activeFilterCount > 0 ? null : primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: activeFilterCount > 0 ? [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ] : null,
                ),
                child: IconButton(
                  icon: Icon(
                    _isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
                    color: activeFilterCount > 0 ? Colors.white : primaryBlue,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isFilterExpanded = !_isFilterExpanded;
                    });
                  },
                ),
              ),
              if (activeFilterCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$activeFilterCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // === SEARCH & FILTER SECTION ===
  Widget _buildSearchAndFilterSection(List<String> categories, List<String> locations) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tour, địa điểm, danh mục...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search, color: primaryBlue, size: 24),
                suffixIcon: search.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
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
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
              onChanged: (value) => setState(() {
                search = value;
                page = 1;
              }),
            ),
          ),

          // Filter Section
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isFilterExpanded ? null : 0,
            child: _isFilterExpanded
                ? Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    primaryBlue.withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: primaryBlue.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.tune,
                              color: primaryBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Bộ lọc nâng cao',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: TextButton(
                          onPressed: _clearFilters,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Xóa tất cả',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Filter Grid
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildFilterDropdown(
                              label: 'Danh mục',
                              value: categoryFilter,
                              hint: 'Chọn danh mục',
                              icon: Icons.category_outlined,
                              items: [
                                const DropdownMenuItem(value: '', child: Text('Tất cả danh mục')),
                                ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                              ],
                              onChanged: (value) => setState(() {
                                categoryFilter = value ?? '';
                                page = 1;
                              }),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFilterDropdown(
                              label: 'Địa điểm',
                              value: locationFilter,
                              hint: 'Chọn địa điểm',
                              icon: Icons.location_on_outlined,
                              items: [
                                const DropdownMenuItem(value: '', child: Text('Tất cả địa điểm')),
                                ...locations.map((l) => DropdownMenuItem(value: l, child: Text(l))),
                              ],
                              onChanged: (value) => setState(() {
                                locationFilter = value ?? '';
                                page = 1;
                              }),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: _buildFilterDropdown(
                              label: 'Khoảng giá',
                              value: priceFilter,
                              hint: 'Chọn khoảng giá',
                              icon: Icons.attach_money_outlined,
                              items: const [
                                DropdownMenuItem(value: '', child: Text('Tất cả mức giá')),
                                DropdownMenuItem(value: 'free', child: Text('🆓 Miễn phí')),
                                DropdownMenuItem(value: 'low', child: Text('💰 \$1 - \$500')),
                                DropdownMenuItem(value: 'medium', child: Text('💰💰 \$500 - \$1000')),
                                DropdownMenuItem(value: 'high', child: Text('💰💰💰 \$1000 - \$2000')),
                                DropdownMenuItem(value: 'premium', child: Text('💎 > \$2000')),
                              ],
                              onChanged: (value) => setState(() {
                                priceFilter = value ?? '';
                                page = 1;
                              }),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFilterDropdown(
                              label: 'Trạng thái',
                              value: statusFilter,
                              hint: 'Chọn trạng thái',
                              icon: Icons.check_circle_outline,
                              items: const [
                                DropdownMenuItem(value: '', child: Text('Tất cả trạng thái')),
                                DropdownMenuItem(value: 'available', child: Text('✅ Có thể đặt')),
                                DropdownMenuItem(value: 'active', child: Text('🟢 Đang hoạt động')),
                                DropdownMenuItem(value: 'inactive', child: Text('🔴 Tạm dừng')),
                              ],
                              onChanged: (value) => setState(() {
                                statusFilter = value ?? '';
                                page = 1;
                              }),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: primaryBlue),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryBlue.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value.isEmpty ? null : value,
              hint: Text(
                hint,
                style: TextStyle(color: Colors.grey[500]),
              ),
              isExpanded: true,
              onChanged: onChanged,
              items: items,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // === ACTIVE FILTERS DISPLAY ===
  Widget _buildActiveFilters() {
    List<Widget> filterChips = [];

    if (search.isNotEmpty) {
      filterChips.add(_buildFilterChip('Tìm kiếm: "$search"', Icons.search, () {
        setState(() {
          search = '';
          _searchController.clear();
          page = 1;
        });
      }));
    }

    if (categoryFilter.isNotEmpty) {
      filterChips.add(_buildFilterChip('Danh mục: $categoryFilter', Icons.category, () {
        setState(() {
          categoryFilter = '';
          page = 1;
        });
      }));
    }

    if (locationFilter.isNotEmpty) {
      filterChips.add(_buildFilterChip('Địa điểm: $locationFilter', Icons.location_on, () {
        setState(() {
          locationFilter = '';
          page = 1;
        });
      }));
    }

    if (priceFilter.isNotEmpty) {
      String priceText = '';
      switch (priceFilter) {
        case 'free': priceText = 'Miễn phí'; break;
        case 'low': priceText = '\$1-500'; break;
        case 'medium': priceText = '\$500-1000'; break;
        case 'high': priceText = '\$1000-2000'; break;
        case 'premium': priceText = '>\$2000'; break;
      }
      filterChips.add(_buildFilterChip('Giá: $priceText', Icons.attach_money, () {
        setState(() {
          priceFilter = '';
          page = 1;
        });
      }));
    }

    if (statusFilter.isNotEmpty) {
      String statusText = '';
      switch (statusFilter) {
        case 'available': statusText = 'Có thể đặt'; break;
        case 'active': statusText = 'Đang hoạt động'; break;
        case 'inactive': statusText = 'Tạm dừng'; break;
      }
      filterChips.add(_buildFilterChip('Trạng thái: $statusText', Icons.check_circle, () {
        setState(() {
          statusFilter = '';
          page = 1;
        });
      }));
    }

    if (filterChips.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryBlue.withOpacity(0.05),
            lightBlue.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.filter_alt,
                      size: 16,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Bộ lọc đang áp dụng:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text(
                  'Xóa tất cả',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filterChips,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryBlue, lightBlue],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === RESULTS HEADER ===
  Widget _buildResultsHeader(int totalResults) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.search_outlined,
              color: primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kết quả tìm kiếm',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalResults tours được tìm thấy',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === TOUR LIST ===
  Widget _buildTourList(TourProvider provider, List<Tour> filteredTours, List<Tour> paginatedTours) {
    if (provider.isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                ),
              ),
            );
          }),
        ),
      );
    }

    if (filteredTours.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                size: 48,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Không tìm thấy tour nào',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy thử thay đổi từ khóa tìm kiếm hoặc bộ lọc',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _clearFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Xóa bộ lọc',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: paginatedTours.map((tour) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: TourCard(
              tour: tour,
              onTap: () {
                context.pushNamed(
                  'tourDetail',
                  pathParameters: {'id': tour.id!},
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // === PAGINATION ===
  Widget _buildPagination(int totalPages) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          Text(
            'Trang $page / $totalPages',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              // Previous button
              if (page > 1)
                _buildPaginationButton(
                  onPressed: () => setState(() => page--),
                  child: const Icon(Icons.chevron_left, size: 20),
                  isSelected: false,
                ),

              // Page numbers
              ...List.generate(totalPages, (i) {
                final pageNumber = i + 1;
                final isSelected = pageNumber == page;

                // Show first, last, current and adjacent pages
                if (pageNumber == 1 ||
                    pageNumber == totalPages ||
                    (pageNumber >= page - 1 && pageNumber <= page + 1)) {
                  return _buildPaginationButton(
                    onPressed: () => setState(() => page = pageNumber),
                    child: Text(
                      '$pageNumber',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : primaryBlue,
                      ),
                    ),
                    isSelected: isSelected,
                  );
                } else if (pageNumber == page - 2 || pageNumber == page + 2) {
                  return Text(
                    '...',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // Next button
              if (page < totalPages)
                _buildPaginationButton(
                  onPressed: () => setState(() => page++),
                  child: const Icon(Icons.chevron_right, size: 20),
                  isSelected: false,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required VoidCallback onPressed,
    required Widget child,
    required bool isSelected,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(colors: [primaryBlue, lightBlue])
            : null,
        color: isSelected ? null : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? null : Border.all(color: primaryBlue),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: child,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminItems = [
      {
        'label': 'Users',
        'icon': Icons.people_rounded,
        'route': '/admin/users',
        'color': Colors.blue,
      },
      {
        'label': 'Bookings',
        'icon': Icons.book_online_rounded,
        'route': '/admin/bookings',
        'color': Colors.green,
      },
      {
        'label': 'Tours',
        'icon': Icons.travel_explore_rounded,
        'route': '/admin/tours',
        'color': Colors.orange,
      },
      {
        'label': 'Categories',
        'icon': Icons.category_rounded,
        'route': '/admin/categories',
        'color': Colors.purple,
      },
      {
        'label': 'Vouchers',
        'icon': Icons.card_giftcard_rounded,
        'route': '/admin/vouchers',
        'color': Colors.red,
      },
      {
        'label': 'Reviews',
        'icon': Icons.reviews_rounded,
        'route': '/admin/reviews',
        'color': Colors.teal,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: adminItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final item = adminItems[index];
            return _AdminCard(
              item: item,
              onTap: () => context.go(item['route'] as String),
            );
          },
        ),
      ),
    );
  }
}

class _AdminCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const _AdminCard({
    required this.item,
    required this.onTap,
  });

  @override
  State<_AdminCard> createState() => _AdminCardState();
}

class _AdminCardState extends State<_AdminCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final itemColor = widget.item['color'] as Color;
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()
          ..scale(_isPressed ? 0.95 : 1.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: itemColor.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: itemColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: itemColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.item['icon'] as IconData,
                size: 32,
                color: itemColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.item['label'] as String,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

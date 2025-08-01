import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class CommonHomeScreen extends StatefulWidget {
  final Widget child;
  const CommonHomeScreen({super.key, required this.child});

  @override
  State<CommonHomeScreen> createState() => _CommonHomeScreenState();
}

class _CommonHomeScreenState extends State<CommonHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Blue color scheme
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color lightBlue = Color(0xFF64B5F6);
  static const Color darkBlue = Color(0xFF1976D2);
  static const Color accentBlue = Color(0xFF03DAC6);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int _calculateIndex(BuildContext context, bool isAdmin) {
    final location = GoRouterState.of(context).uri.toString();

    if (location.startsWith('/customer/tours')) return 1;
    if (location.startsWith('/customer/bookings') || location.startsWith('/admin/dashboard')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0; // Home
  }

  void _onItemTapped(int index, bool isAdmin) {
    // Animation khi tap
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Navigation
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/customer/tours');
        break;
      case 2:
        isAdmin
            ? context.go('/admin/dashboard')
            : context.go('/customer/bookings');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final isAdmin = user?.role == 'admin';
    final index = _calculateIndex(context, isAdmin);

    return Scaffold(
      body: widget.child,
      extendBody: true,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.95),
                ],
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: index,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: primaryBlue,
              unselectedItemColor: Colors.grey[400],
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              onTap: (i) => _onItemTapped(i, isAdmin),
              items: [
                _buildBottomNavigationBarItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  isSelected: index == 0,
                ),
                _buildBottomNavigationBarItem(
                  icon: Icons.travel_explore_outlined,
                  activeIcon: Icons.travel_explore,
                  label: 'Tours',
                  isSelected: index == 1,
                ),
                isAdmin
                    ? _buildBottomNavigationBarItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Dashboard',
                  isSelected: index == 2,
                )
                    : _buildBottomNavigationBarItem(
                  icon: Icons.book_online_outlined,
                  activeIcon: Icons.book_online,
                  label: 'Booking',
                  isSelected: index == 2,
                ),
                _buildBottomNavigationBarItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  isSelected: index == 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavigationBarItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
  }) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryBlue.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isSelected ? activeIcon : icon,
            key: ValueKey(isSelected),
            size: 24,
          ),
        ),
      ),
      label: label,
    );
  }
}

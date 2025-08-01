import 'package:final_mobile/screens/admin/tour/CreateTourScreen.dart';
import 'package:final_mobile/screens/customer/booking/booking_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/CommonHomeScreen.dart';
import 'screens/HomeWelcomeScreen.dart';
import 'screens/ProfileScreen.dart';
import 'screens/customer/tour/tour_detail_screen.dart';

// Admin Screens
import 'screens/admin/dashboard_screen.dart';
import 'screens/admin/user/manage_user_screen.dart';
import 'screens/admin/booking/manage_booking_screen.dart';
import 'screens/admin/tour/manage_tour_screen.dart';
import 'package:final_mobile/screens/admin/tour/AdminTourDetailScreen.dart';
import 'screens/admin/category/manage_category_screen.dart';
import 'screens/admin/voucher/manage_voucher_screen.dart';
import 'screens/admin/review/manage_review_screen.dart';
import 'screens/admin/log/log_screen.dart';
import 'screens/admin/booking/AdminBookingDetailScreen.dart';

// Customer Screens
import 'screens/customer/tour/tour_list_screen.dart';
import 'screens/customer/booking/my_booking_screen.dart';
import 'screens/customer/review/my_review_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/ChatBotScreen.dart';
import 'screens/DieuKhoanPage.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final router = GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider,
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

        ShellRoute(
          builder: (context, state, child) => CommonHomeScreen(child: child),
          routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeWelcomeScreen()),

            // Admin
            GoRoute(path: '/admin/dashboard', builder: (_, __) => const DashboardScreen()),
            GoRoute(path: '/admin/users', builder: (_, __) => const ManageUserScreen()),
            GoRoute(path: '/admin/bookings', builder: (_, __) => const ManageBookingScreen()),
            GoRoute(path: '/admin/tours', builder: (_, __) => const ManageTourScreen()),
            GoRoute(path: '/admin/categories', builder: (_, __) => const ManageCategoryScreen()),
            GoRoute(path: '/admin/vouchers', builder: (_, __) => const ManageVoucherScreen()),
            GoRoute(path: '/admin/reviews', builder: (_, __) => const ManageReviewScreen()),
            GoRoute(path: '/admin/logs', builder: (_, __) => const LogScreen()),

            // Customer
            GoRoute(path: '/customer/tours', builder: (_, __) => const TourListScreen()),
            GoRoute(path: '/customer/bookings', builder: (_, __) => const MyBookingScreen()),
            GoRoute(path: '/customer/reviews', builder: (_, __) => const MyReviewScreen()),

            // 📍 Tour detail
            GoRoute(
              path: '/tour/:id',
              name: 'tourDetail',
              builder: (context, state) {
                final tourId = state.pathParameters['id']!;
                return TourDetailScreen(tourId: tourId);
              },
            ),

            GoRoute(
              path: '/booking/:id',
              builder: (context, state) {
                final bookingId = state.pathParameters['id']!;
                return BookingDetailScreen(bookingId: bookingId);
              },
            ),


            GoRoute(
              path: '/booking/:id',
              name: 'bookingDetail',
              builder: (context, state) {
                final bookingId = state.pathParameters['id']!;
                return AdminBookingDetailScreen(bookingId: bookingId);
              },
            ),

            GoRoute(
              path: '/review/create',
              name: 'createReview',
              builder: (context, state) => const MyReviewScreen(),
            ),

            GoRoute(
              path: '/admin/tours/create',
              builder: (_, __) => const CreateTourScreen(),
            ),


            GoRoute(
              path: '/admin/tours/:id',
              name: 'adminTourDetail',
              builder: (context, state) {
                final tourId = state.pathParameters['id']!;
                return AdminTourDetailScreen(tourId: tourId); // 🛑 lỗi ở đây nếu chưa import
              },
            ),

            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),

            GoRoute(
              path: '/edit-profile',
              builder: (context, state) => const EditProfileScreen(),
            ),

            GoRoute(
              path: '/admin/bookings/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return AdminBookingDetailScreen(bookingId: id);
              },
            ),

            GoRoute(
              path: '/chatbot',
              builder: (context, state) => const ChatBotScreen(),
            ),

            GoRoute(
              path: '/terms',
              builder: (context, state) => const DieuKhoanPage(),
            ),


          ],
        ),
      ],
      redirect: (context, state) {
        final user = authProvider.user;
        final path = state.uri.toString();
        final loggingIn = path == '/login' || path == '/register';

        if (user == null && !loggingIn) return '/login';
        if (user != null && loggingIn) return '/home';

        return null;
      },
      errorBuilder: (_, __) => const Scaffold(
        body: Center(child: Text('404 - Trang không tồn tại')),
      ),
    );

    return MaterialApp.router(
      title: 'Final Mobile',
      theme: ThemeData.light(),
      routerConfig: router,
    );
  }
}

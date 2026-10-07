import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/auth/presentation/01_welcome_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/verify_email_screen.dart';
import '../features/booking/presentation/booking_details_screen.dart';
import '../features/booking/presentation/booking_screen.dart';
import '../features/booking/presentation/bookings_list_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/messaging/presentation/chat_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/profile/presentation/add_edit_service_screen.dart';
import '../features/profile/presentation/my_services_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/profile_setup_screen.dart';
import '../features/profile/presentation/provider_profile_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/search/presentation/service_details_screen.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/main_shell.dart';

GoRouter createRouter(AuthService authService) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authService,
    redirect: (context, state) {
      final user = authService.currentUserModel;
      final path = state.uri.toString();

      final isWelcome = path == '/welcome';
      final isAuthPath = path == '/login' || path == '/signup' || isWelcome;
      final isSplash = path == '/';
      final isVerifying = path == '/verify-email';
      final isProfileSetup = path == '/profile-setup';

      if (!authService.isInitialized) {
        return isSplash ? null : '/';
      }

      if (user == null) {
        if (isSplash) return '/welcome';
        if (isAuthPath) return null;
        return '/welcome';
      }

      if (!user.isVerified) {
        if (isVerifying) return null;
        return '/verify-email';
      }

      if (isAuthPath || isSplash || isVerifying) {
        if (user.role == UserRole.admin) return '/admin';
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
      GoRoute(path: '/verify-email', builder: (context, state) => const VerifyEmailScreen()),
      GoRoute(path: '/profile-setup', builder: (context, state) => const ProfileSetupScreen()),
      GoRoute(path: '/admin', builder: (context, state) => const AdminDashboardScreen()),

      // Shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
          GoRoute(path: '/bookings', builder: (context, state) => const BookingsListScreen()),
          GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        ],
      ),

      // Detail routes (no shell)
      GoRoute(path: '/service/:id', builder: (context, state) => ServiceDetailsScreen(serviceId: state.pathParameters['id']!)),
      GoRoute(path: '/provider/:id', builder: (context, state) => ProviderProfileScreen(userId: state.pathParameters['id']!)),
      GoRoute(path: '/profile/edit', builder: (context, state) => const ProfileSetupScreen(isEditing: true)),
      GoRoute(path: '/services', builder: (context, state) => const MyServicesScreen()),
      GoRoute(path: '/services/add', builder: (context, state) => const AddEditServiceScreen()),
      GoRoute(path: '/services/edit/:id', builder: (context, state) => AddEditServiceScreen(serviceId: state.pathParameters['id']!)),
      GoRoute(path: '/book/:providerId', builder: (context, state) => BookingScreen(providerId: state.pathParameters['providerId']!)),
      GoRoute(path: '/chat/:bookingId', builder: (context, state) => ChatScreen(bookingId: state.pathParameters['bookingId']!)),
      GoRoute(path: '/booking/:id', builder: (context, state) => BookingDetailsScreen(bookingId: state.pathParameters['id']!)),
    ],
  );
}

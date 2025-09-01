import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../ui/admin/admin_dashboard_screen.dart';
import '../../ui/admin/pending_companies_screen.dart';
import '../../ui/auth/auth_selector_screen.dart';
import '../../ui/auth/login_screen.dart';
import '../../ui/auth/register_screen.dart';
import '../../ui/company/applicants/applicant_detail_screen.dart';
import '../../ui/company/applicants/applicants_screen.dart';
import '../../ui/company/dashboard/dashboard_screen.dart';
import '../../ui/company/post/post_internship_screen.dart';
import '../../ui/company/profile/company_profile_screen.dart';
import '../../ui/onboarding/onboarding_screen.dart';
import '../../ui/user/applications/applications_screen.dart';
import '../../ui/user/home/home_screen.dart';
import '../../ui/user/home/internship_detail_screen.dart';
import '../../ui/user/profile/profile_screen.dart';

class AppRouter {
  static final _refreshListenable = _AuthRefreshListenable();

  static final GoRouter router = GoRouter(
    refreshListenable: _refreshListenable,
    initialLocation: '/onboarding',
    redirect: _redirect,
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth-selector',
        builder: (context, state) => const AuthSelectorScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final role =
              state.uri.queryParameters['role'] ?? AppConstants.roleUser;
          return LoginScreen(role: role);
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final role =
              state.uri.queryParameters['role'] ?? AppConstants.roleUser;
          return RegisterScreen(role: role);
        },
      ),

      // User
      GoRoute(
        path: '/user',
        builder: (context, state) => const UserMainScreen(),
        routes: [
          GoRoute(
            path: 'internship/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return InternshipDetailScreen(internshipId: id);
            },
          ),
        ],
      ),

      // Company
      GoRoute(
        path: '/company',
        builder: (context, state) => const CompanyMainScreen(),
        routes: [
          GoRoute(
            path: 'post',
            builder: (context, state) => const PostInternshipScreen(),
          ),
          GoRoute(
            path: 'applicants/:jobId',
            builder: (context, state) {
              final jobId = state.pathParameters['jobId']!;
              return ApplicantsScreen(jobId: jobId);
            },
          ),
          GoRoute(
            path: 'applicant/:applicationId',
            builder: (context, state) {
              final applicationId = state.pathParameters['applicationId']!;
              return ApplicantDetailScreen(applicationId: applicationId);
            },
          ),
        ],
      ),

      // Admin
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminMainScreen(),
        routes: [
          GoRoute(
            path: 'pending-companies',
            builder: (context, state) => const PendingCompaniesScreen(),
          ),
        ],
      ),
    ],
  );

  static String? _redirect(BuildContext context, GoRouterState state) {
    final authProvider = context.read<AuthProvider>();
    final isAuthenticated = AuthService.currentUser != null;
    final user = authProvider.user;

    final isOnboarding = state.uri.toString() == '/onboarding';
    final isAuthFlow = state.uri.toString().startsWith('/auth') ||
        state.uri.toString().startsWith('/login') ||
        state.uri.toString().startsWith('/register');

    if (!isAuthenticated) {
      if (isOnboarding || isAuthFlow) return null;
      return '/onboarding';
    }

    if (isOnboarding || isAuthFlow) {
      if (user == null) return null;
      switch (user.role) {
        case AppConstants.roleUser:
          return '/user';
        case AppConstants.roleCompany:
          return '/company';
        case AppConstants.roleAdmin:
          return '/admin';
        default:
          return '/user';
      }
    }

    final location = state.uri.toString();
    if (location.startsWith('/user') && user?.role != AppConstants.roleUser) {
      return _getHomeForRole(user?.role);
    }
    if (location.startsWith('/company') &&
        user?.role != AppConstants.roleCompany) {
      return _getHomeForRole(user?.role);
    }
    if (location.startsWith('/admin') && user?.role != AppConstants.roleAdmin) {
      return _getHomeForRole(user?.role);
    }
    return null;
  }

  static String _getHomeForRole(String? role) {
    switch (role) {
      case AppConstants.roleUser:
        return '/user';
      case AppConstants.roleCompany:
        return '/company';
      case AppConstants.roleAdmin:
        return '/admin';
      default:
        return '/user';
    }
  }
}

class _AuthRefreshListenable extends ChangeNotifier {
  late final StreamSubscription _sub;
  _AuthRefreshListenable() {
    scheduleMicrotask(() {
      try {
        _sub = AuthService.authStateChanges.listen((_) => notifyListeners());
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    try {
      _sub.cancel();
    } catch (_) {}
    super.dispose();
  }

  @override
  void notifyListeners() {
    final phase = WidgetsBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      super.notifyListeners();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        super.notifyListeners();
      });
    }
  }
}

// Bottom nav shells
class UserMainScreen extends StatefulWidget {
  const UserMainScreen({super.key});
  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const ApplicationsScreen(),
    const ProfileScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.work), label: 'Applications'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class CompanyMainScreen extends StatefulWidget {
  const CompanyMainScreen({super.key});
  @override
  State<CompanyMainScreen> createState() => _CompanyMainScreenState();
}

class _CompanyMainScreenState extends State<CompanyMainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const DashboardScreen(),
    const PostInternshipScreen(),
    const CompanyProfileScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Post'),
          BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Profile'),
        ],
      ),
    );
  }
}

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});
  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const PendingCompaniesScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.pending_actions), label: 'Pending Approvals'),
        ],
      ),
    );
  }
}

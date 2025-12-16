import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/dashboard/presentation/admin_dashboard_screen.dart';
import '../../features/worker_job/presentation/worker_main_screen.dart';
import '../../features/client/presentation/client_home_screen.dart';
import '../../features/agency/presentation/agency_register_screen.dart';
import '../../features/agency/data/agency_repository.dart';

final _supabase = Supabase.instance.client;

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final session = _supabase.auth.currentSession;
    final isLoggedIn = session != null;
    final currentLocation = state.matchedLocation;
    final isLoginRoute = currentLocation == '/login';
    final isSignupRoute = currentLocation == '/signup';
    final isRoleSelectionRoute = currentLocation == '/role-selection';

    // 로그인/회원가입/역할선택 페이지는 로그인 상태와 관계없이 접근 가능
    if (isLoginRoute || isSignupRoute || isRoleSelectionRoute) {
      // 이미 로그인한 경우 역할 확인 후 적절한 페이지로 리다이렉트
      if (isLoggedIn) {
        try {
          final authRepository = AuthRepository();
          final profile = await authRepository.getCurrentProfile();
          final role = profile?['role'] as String?;

          if (role == null || role.isEmpty) {
            // 역할이 없으면 역할 선택 화면으로
            if (!isRoleSelectionRoute) {
              return '/role-selection';
            }
            return null;
          }

          // 역할이 있으면 역할별 홈으로 리다이렉트
          switch (role) {
            case 'manager':
              // 소장님은 회사 등록 여부 확인
              final agencyRepository = AgencyRepository();
              final user = _supabase.auth.currentUser;
              if (user != null) {
                final agency = await agencyRepository.getAgencyByOwner(user.id);
                if (agency == null) {
                  // 회사 정보가 없으면 회사 등록 화면으로
                  if (currentLocation != '/agency-register') {
                    return '/agency-register';
                  }
                } else {
                  // 회사 정보가 있으면 대시보드로
                  if (currentLocation != '/admin-dashboard') {
                    return '/admin-dashboard';
                  }
                }
              }
              break;
            case 'worker':
              if (currentLocation != '/worker-home') {
                return '/worker-home';
              }
              break;
            case 'client':
              if (currentLocation != '/client-home') {
                return '/client-home';
              }
              break;
          }
        } catch (e) {
          // 프로필 조회 실패 시 역할 선택 화면으로
          if (!isRoleSelectionRoute) {
            return '/role-selection';
          }
        }
      }
      return null;
    }

    // 로그인하지 않은 경우 로그인 페이지로
    if (!isLoggedIn) {
      return '/login';
    }

    // 로그인했지만 역할이 없는 경우 역할 선택 화면으로
    try {
      final authRepository = AuthRepository();
      final profile = await authRepository.getCurrentProfile();
      final role = profile?['role'] as String?;

      if (role == null || role.isEmpty) {
        return '/role-selection';
      }

      // 역할이 있으면 역할별 홈으로 리다이렉트
      switch (role) {
        case 'manager':
          // 소장님은 회사 등록 여부 확인
          final agencyRepository = AgencyRepository();
          final user = _supabase.auth.currentUser;
          if (user != null) {
            final agency = await agencyRepository.getAgencyByOwner(user.id);
            if (agency == null) {
              // 회사 정보가 없으면 회사 등록 화면으로
              return '/agency-register';
            } else {
              // 회사 정보가 있으면 대시보드로
              return '/admin-dashboard';
            }
          }
          return '/agency-register';
        case 'worker':
          return '/worker-home';
        case 'client':
          return '/client-home';
      }
    } catch (e) {
      // 프로필 조회 실패 시 역할 선택 화면으로
      return '/role-selection';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/role-selection',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/admin-dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/worker-home',
      builder: (context, state) => const WorkerMainScreen(),
    ),
    GoRoute(
      path: '/client-home',
      builder: (context, state) => const ClientHomeScreen(),
    ),
    GoRoute(
      path: '/agency-register',
      builder: (context, state) => const AgencyRegisterScreen(),
      redirect: (context, state) async {
        // 소장님이 아니면 접근 불가
        final user = _supabase.auth.currentUser;
        if (user == null) return '/login';

        final authRepository = AuthRepository();
        final profile = await authRepository.getCurrentProfile();
        final role = profile?['role'] as String?;

        if (role != 'manager') {
          return '/login';
        }

        // 이미 회사 정보가 있으면 대시보드로
        final agencyRepository = AgencyRepository();
        final agency = await agencyRepository.getAgencyByOwner(user.id);
        if (agency != null) {
          return '/admin-dashboard';
        }

        return null;
      },
    ),
    // 하위 호환성을 위해 /worker 경로도 유지
    GoRoute(
      path: '/worker',
      builder: (context, state) => const WorkerMainScreen(),
    ),
  ],
);

/// Riverpod Provider로 GoRouter 제공 (로그인 상태 변경 시 자동 리다이렉트)
final goRouterProvider = Provider<GoRouter>((ref) {
  return appRouter;
});


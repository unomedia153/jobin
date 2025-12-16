import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

/// 대시보드 통계 데이터
class DashboardStats {
  final int pendingOrders;
  final int todayAttendance;
  final int pendingPlacements;
  final int totalWorkers;

  DashboardStats({
    required this.pendingOrders,
    required this.todayAttendance,
    required this.pendingPlacements,
    required this.totalWorkers,
  });
}

/// 대시보드 컨트롤러
class DashboardController extends AsyncNotifier<DashboardStats> {
  @override
  Future<DashboardStats> build() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final repository = ref.read(dashboardRepositoryProvider);
    final agencyId = await repository.getAgencyIdByOwner(user.id);
    if (agencyId == null) {
      throw Exception('회사 정보를 찾을 수 없습니다.');
    }

    // 초기 데이터 로드
    final stats = await _loadStats(repository, agencyId);

    // Realtime 구독 설정
    _setupRealtimeSubscription(agencyId);

    return stats;
  }

  Future<DashboardStats> _loadStats(
    DashboardRepository repository,
    String agencyId,
  ) async {
    final pendingOrders = await repository.getPendingJobOrdersCount(agencyId);
    final todayAttendance = await repository.getTodayAttendanceCount(agencyId);
    final pendingPlacements = await repository.getPendingPlacementsCount(agencyId);
    final totalWorkers = await repository.getTotalWorkersCount();

    return DashboardStats(
      pendingOrders: pendingOrders,
      todayAttendance: todayAttendance,
      pendingPlacements: pendingPlacements,
      totalWorkers: totalWorkers,
    );
  }

  void _setupRealtimeSubscription(String agencyId) {
    final repository = ref.read(dashboardRepositoryProvider);

    // job_orders 변경 감지
    repository.watchJobOrders(agencyId).listen((_) {
      // 데이터 변경 시 통계 다시 로드
      _refreshStats(agencyId);
    });

    // placements 변경 감지
    repository.watchPlacements(agencyId).listen((_) {
      // 데이터 변경 시 통계 다시 로드
      _refreshStats(agencyId);
    });
  }

  Future<void> _refreshStats(String agencyId) async {
    final repository = ref.read(dashboardRepositoryProvider);
    final stats = await _loadStats(repository, agencyId);
    state = AsyncData(stats);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final repository = ref.read(dashboardRepositoryProvider);
    final agencyId = await repository.getAgencyIdByOwner(user.id);
    if (agencyId == null) return;

    state = AsyncData(await _loadStats(repository, agencyId));
  }
}

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardStats>(() {
  return DashboardController();
});

/// 회사명 Provider
final agencyNameProvider = FutureProvider<String?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;

  final repository = ref.read(dashboardRepositoryProvider);
  return await repository.getAgencyNameByOwner(user.id);
});

/// 진행 중인 오더 목록 Provider
final activeJobOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  final repository = ref.read(dashboardRepositoryProvider);
  final agencyId = await repository.getAgencyIdByOwner(user.id);
  if (agencyId == null) return [];

  return await repository.getActiveJobOrders(agencyId);
});

/// 최근 활동 Provider
final recentActivitiesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  final repository = ref.read(dashboardRepositoryProvider);
  final agencyId = await repository.getAgencyIdByOwner(user.id);
  if (agencyId == null) return [];

  return await repository.getRecentActivities(agencyId);
});


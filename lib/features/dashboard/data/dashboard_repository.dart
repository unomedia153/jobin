import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 소장님의 회사 ID 조회
  Future<String?> getAgencyIdByOwner(String ownerId) async {
    try {
      final response = await _supabase
          .from('agencies')
          .select('id')
          .eq('owner_id', ownerId)
          .isFilter('deleted_at', null)
          .maybeSingle();

      return response?['id'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// 소장님의 회사명 조회
  Future<String?> getAgencyNameByOwner(String ownerId) async {
    try {
      final response = await _supabase
          .from('agencies')
          .select('name')
          .eq('owner_id', ownerId)
          .isFilter('deleted_at', null)
          .maybeSingle();

      return response?['name'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// 신규 주문 수 조회 (처리되지 않은 주문)
  /// TODO: job_orders 테이블에 status 컬럼 추가 시 'pending' 상태 필터링
  Future<int> getPendingJobOrdersCount(String agencyId) async {
    try {
      final siteIds = await _getSiteIdsByAgency(agencyId);
      if (siteIds.isEmpty) return 0;

      final response = await _supabase
          .from('job_orders')
          .select('id')
          .inFilter('site_id', siteIds)
          .isFilter('deleted_at', null);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// 오늘 출근 인원 수 조회
  Future<int> getTodayAttendanceCount(String agencyId) async {
    try {
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final siteIds = await _getSiteIdsByAgency(agencyId);
      if (siteIds.isEmpty) return 0;

      final jobOrderResponse = await _supabase
          .from('job_orders')
          .select('id')
          .inFilter('site_id', siteIds)
          .eq('work_date', todayStr)
          .isFilter('deleted_at', null);

      if (jobOrderResponse.isEmpty) return 0;

      final jobOrderIds = (jobOrderResponse as List).map((e) => e['id'] as String).toList();

      final placementResponse = await _supabase
          .from('placements')
          .select('id')
          .inFilter('job_order_id', jobOrderIds)
          .eq('status', 'accepted')
          .isFilter('deleted_at', null);

      return (placementResponse as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// 배치 대기 건수 조회 (오더는 있으나 작업자 미확정)
  Future<int> getPendingPlacementsCount(String agencyId) async {
    try {
      final siteIds = await _getSiteIdsByAgency(agencyId);
      if (siteIds.isEmpty) return 0;

      final jobOrderResponse = await _supabase
          .from('job_orders')
          .select('id')
          .inFilter('site_id', siteIds)
          .isFilter('deleted_at', null);

      if (jobOrderResponse.isEmpty) return 0;

      final jobOrderIds = (jobOrderResponse as List).map((e) => e['id'] as String).toList();

      // 각 job_order에 대해 배치가 하나도 없는 경우를 카운트
      int count = 0;
      for (final jobOrderId in jobOrderIds) {
        final placementResponse = await _supabase
            .from('placements')
            .select('id')
            .eq('job_order_id', jobOrderId)
            .isFilter('deleted_at', null)
            .limit(1);

        if (placementResponse.isEmpty) {
          count++;
        }
      }

      return count;
    } catch (e) {
      return 0;
    }
  }

  /// 총 작업자 수 조회
  Future<int> getTotalWorkersCount() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('role', 'worker')
          .isFilter('deleted_at', null);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// 진행 중인 오더 목록 조회
  Future<List<Map<String, dynamic>>> getActiveJobOrders(String agencyId) async {
    try {
      final siteIds = await _getSiteIdsByAgency(agencyId);
      if (siteIds.isEmpty) return [];

      final response = await _supabase
          .from('job_orders')
          .select('''
            *,
            sites (
              name,
              lat,
              lng
            ),
            placements (
              id,
              worker_id,
              status,
              profiles!placements_worker_id_fkey (
                name
              )
            )
          ''')
          .inFilter('site_id', siteIds)
          .isFilter('deleted_at', null)
          .order('work_date', ascending: true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// 최근 알림/로그 조회 (주문 생성, 배치 수락 등)
  Future<List<Map<String, dynamic>>> getRecentActivities(String agencyId) async {
    try {
      final siteIds = await _getSiteIdsByAgency(agencyId);
      if (siteIds.isEmpty) return [];

      // 최근 job_orders와 placements를 합쳐서 시간순으로 정렬
      final jobOrders = await _supabase
          .from('job_orders')
          .select('id, created_at, sites!inner(name)')
          .inFilter('site_id', siteIds)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(10);

      final placements = await _supabase
          .from('placements')
          .select('''
            id,
            status,
            created_at,
            updated_at,
            job_orders!inner (
              sites!inner (
                name
              )
            ),
            profiles!placements_worker_id_fkey (
              name
            )
          ''')
          .inFilter('job_orders.site_id', siteIds)
          .isFilter('deleted_at', null)
          .order('updated_at', ascending: false)
          .limit(10);

      final activities = <Map<String, dynamic>>[];

      // job_orders를 활동으로 변환
      for (final order in jobOrders) {
        activities.add({
          'type': 'job_order_created',
          'message': '${order['sites']['name']}에 새로운 주문이 등록되었습니다.',
          'timestamp': order['created_at'],
        });
      }

      // placements를 활동으로 변환
      for (final placement in placements) {
        final jobOrder = placement['job_orders'] as Map<String, dynamic>;
        final site = jobOrder['sites'] as Map<String, dynamic>;
        final profile = placement['profiles'] as Map<String, dynamic>?;
        final status = placement['status'] as String;

        String message = '';
        if (status == 'accepted') {
          message = '${profile?['name'] ?? '작업자'}님이 ${site['name']} 배치를 수락했습니다.';
        } else if (status == 'offered') {
          message = '${site['name']}에 배치의향서가 발송되었습니다.';
        }

        if (message.isNotEmpty) {
          activities.add({
            'type': 'placement_$status',
            'message': message,
            'timestamp': placement['updated_at'] ?? placement['created_at'],
          });
        }
      }

      // 시간순 정렬
      activities.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] as String);
        final bTime = DateTime.parse(b['timestamp'] as String);
        return bTime.compareTo(aTime);
      });

      return activities.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  /// job_orders 테이블 Realtime 스트림
  Stream<List<Map<String, dynamic>>> watchJobOrders(String agencyId) async* {
    final siteIds = await _getSiteIdsByAgency(agencyId);
    if (siteIds.isEmpty) {
      yield [];
      return;
    }

    yield* _supabase
        .from('job_orders')
        .stream(primaryKey: ['id'])
        .inFilter('site_id', siteIds)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// placements 테이블 Realtime 스트림
  Stream<List<Map<String, dynamic>>> watchPlacements(String agencyId) async* {
    final siteIds = await _getSiteIdsByAgency(agencyId);
    if (siteIds.isEmpty) {
      yield [];
      return;
    }

    // job_order_id를 통해 필터링
    final jobOrderResponse = await _supabase
        .from('job_orders')
        .select('id')
        .inFilter('site_id', siteIds)
        .isFilter('deleted_at', null);

    if (jobOrderResponse.isEmpty) {
      yield [];
      return;
    }

    final jobOrderIds = (jobOrderResponse as List).map((e) => e['id'] as String).toList();

    yield* _supabase
        .from('placements')
        .stream(primaryKey: ['id'])
        .inFilter('job_order_id', jobOrderIds)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// 회사 소속 현장 ID 목록 조회
  Future<List<String>> _getSiteIdsByAgency(String agencyId) async {
    try {
      final response = await _supabase
          .from('sites')
          .select('id')
          .eq('agency_id', agencyId)
          .isFilter('deleted_at', null);

      return (response as List<dynamic>).map((e) => e['id'] as String).toList();
    } catch (e) {
      return [];
    }
  }
}


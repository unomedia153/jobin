import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

/// 가용 작업자 목록 조회 결과 (통계 정보 포함)
class AvailableWorkersResult {
  final List<Map<String, dynamic>> workers;
  final int totalWorkers;
  final int availableCount;

  AvailableWorkersResult({
    required this.workers,
    required this.totalWorkers,
    required this.availableCount,
  });
}

class DispatchRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 가용 작업자 목록 조회 (해당 날짜에 배정되지 않고 휴무가 아닌 작업자만)
  /// 
  /// [date] 작업 날짜
  /// [searchQuery] 검색어 (이름 또는 전화번호)
  Future<AvailableWorkersResult> getAvailableWorkers({
    required DateTime date,
    String? searchQuery,
  }) async {
    try {
      // Step 1: 날짜 정규화 (시간 정보 제거, yyyy-MM-dd 형식)
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      // Step 2: 데이터 조회 (3가지 병렬 조회)
      // 2-1. 전체 작업자 목록 조회
      final allWorkersResponse = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'worker')
          .isFilter('deleted_at', null)
          .order('name', ascending: true);

      final allWorkers = List<Map<String, dynamic>>.from(allWorkersResponse);
      final totalWorkers = allWorkers.length;

      // 2-2. 휴무자 목록 조회
      // 조건: start_date <= dateStr AND end_date >= dateStr
      Set<String> onLeaveWorkerIds = {};
      try {
        final leavesResponse = await _supabase
            .from('worker_leaves')
            .select('worker_id')
            .lte('start_date', dateStr) // start_date <= dateStr
            .gte('end_date', dateStr) // end_date >= dateStr
            .isFilter('deleted_at', null);

        onLeaveWorkerIds = (leavesResponse as List)
            .map((l) => l['worker_id'] as String)
            .toSet();
      } catch (e) {
        // worker_leaves 테이블이 아직 생성되지 않았을 수 있음
        // 에러를 무시하고 계속 진행
      }

      // 2-3. 기배차자 목록 조회 (placements와 job_orders 조인)
      // placements status가 'accepted'이고, 연결된 job_orders의 work_date가 dateStr인 경우
      Set<String> assignedWorkerIds = {};
      try {
        final placementsResponse = await _supabase
            .from('placements')
            .select('''
              worker_id,
              job_orders!inner (
                work_date
              )
            ''')
            .eq('status', 'accepted')
            .eq('job_orders.work_date', dateStr)
            .isFilter('deleted_at', null);

        assignedWorkerIds = (placementsResponse as List)
            .map((p) => p['worker_id'] as String)
            .toSet();
      } catch (e) {
        // 조인 쿼리가 실패할 경우 대체 방법 사용
        // job_orders를 먼저 조회하고 placements 조회
        try {
          final jobOrdersResponse = await _supabase
              .from('job_orders')
              .select('id')
              .eq('work_date', dateStr)
              .isFilter('deleted_at', null);

          final jobOrderIds = (jobOrdersResponse as List)
              .map((jo) => jo['id'] as String)
              .toList();

          if (jobOrderIds.isNotEmpty) {
            final placementsResponse = await _supabase
                .from('placements')
                .select('worker_id')
                .inFilter('job_order_id', jobOrderIds)
                .eq('status', 'accepted')
                .isFilter('deleted_at', null);

            assignedWorkerIds = (placementsResponse as List)
                .map((p) => p['worker_id'] as String)
                .toSet();
          }
        } catch (_) {
          // 에러 발생 시 빈 Set 유지
        }
      }

      // Step 3: 필터링 (Dart 메모리 연산)
      // 전체 작업자 리스트에서 휴무자와 기배차자 제거
      final unavailableWorkerIds = onLeaveWorkerIds.union(assignedWorkerIds);
      
      var availableWorkers = allWorkers
          .where((worker) {
            final workerId = worker['id'] as String;
            return !unavailableWorkerIds.contains(workerId);
          })
          .toList();

      // 검색어가 있으면 추가 필터링 (대소문자 구분 없이)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        availableWorkers = availableWorkers.where((worker) {
          final name = (worker['name'] as String? ?? '').toLowerCase();
          final phone = (worker['phone'] as String? ?? '').toLowerCase();
          return name.contains(lowerQuery) || phone.contains(lowerQuery);
        }).toList();
      }

      // Step 4: 최종 반환
      return AvailableWorkersResult(
        workers: availableWorkers,
        totalWorkers: totalWorkers,
        availableCount: availableWorkers.length,
      );
    } catch (e) {
      throw Exception('가용 작업자 목록 조회 실패: $e');
    }
  }

  /// 작업자 목록 조회 (role = 'worker') - 레거시 메서드 (호환성 유지)
  @Deprecated('getAvailableWorkers를 사용하세요')
  Future<List<Map<String, dynamic>>> getWorkers({
    String? searchQuery,
  }) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'worker')
          .isFilter('deleted_at', null)
          .order('name', ascending: true);

      final workers = List<Map<String, dynamic>>.from(response);

      // 검색어가 있으면 클라이언트 사이드에서 필터링 (대소문자 구분 없이)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        return workers.where((worker) {
          final name = (worker['name'] as String? ?? '').toLowerCase();
          final phone = (worker['phone'] as String? ?? '').toLowerCase();
          return name.contains(lowerQuery) || phone.contains(lowerQuery);
        }).toList();
      }

      return workers;
    } catch (e) {
      throw Exception('작업자 목록 조회 실패: $e');
    }
  }

  /// job_order를 통해 agency_id 조회
  Future<String?> getAgencyIdByJobOrder(String jobOrderId) async {
    try {
      final response = await _supabase
          .from('job_orders')
          .select('''
            sites!inner (
              agency_id
            )
          ''')
          .eq('id', jobOrderId)
          .maybeSingle();

      final sites = response?['sites'] as Map<String, dynamic>?;
      return sites?['agency_id'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// 배정 생성 (소장님이 직접 배정하므로 즉시 'accepted' 상태)
  /// 
  /// [jobOrderId] 작업 주문 ID
  /// [workerId] 작업자 ID
  /// [agencyId] 회사 ID (RLS 정책 통과용)
  Future<void> createPlacement({
    required String jobOrderId,
    required String workerId,
    required String agencyId,
  }) async {
    try {
      // placements 테이블에 agency_id 컬럼이 있는지 확인하기 위해
      // 먼저 job_order를 통해 agency_id를 가져온 후 포함
      final insertData = <String, dynamic>{
        'job_order_id': jobOrderId,
        'worker_id': workerId,
        'status': 'accepted', // 소장님이 직접 배정하므로 즉시 확정
      };

      // agency_id가 placements 테이블에 있다면 포함
      // (스키마에 없을 수도 있으므로 try-catch로 처리)
      try {
        insertData['agency_id'] = agencyId;
      } catch (_) {
        // agency_id 컬럼이 없으면 무시
      }

      await _supabase.from('placements').insert(insertData);
    } catch (e) {
      // agency_id 컬럼이 없는 경우 다시 시도 (agency_id 없이)
      if (e.toString().contains('agency_id') || e.toString().contains('column')) {
        await _supabase.from('placements').insert({
          'job_order_id': jobOrderId,
          'worker_id': workerId,
          'status': 'accepted',
        });
      } else {
        throw Exception('배정 생성 실패: $e');
      }
    }
  }
}


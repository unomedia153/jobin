import 'package:supabase_flutter/supabase_flutter.dart';

class DispatchRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 가용 작업자 목록 조회 (해당 날짜에 배정되지 않은 작업자만)
  /// 
  /// [date] 작업 날짜
  /// [searchQuery] 검색어 (이름 또는 전화번호)
  Future<List<Map<String, dynamic>>> getAvailableWorkers({
    required DateTime date,
    String? searchQuery,
  }) async {
    try {
      // 1. 전체 작업자 목록 조회
      final workersResponse = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'worker')
          .isFilter('deleted_at', null)
          .order('name', ascending: true);

      final allWorkers = List<Map<String, dynamic>>.from(workersResponse);

      // 2. 해당 날짜에 이미 배정된 작업자 ID 목록 조회
      final dateStr = date.toIso8601String().split('T')[0]; // YYYY-MM-DD 형식
      
      // 먼저 해당 날짜의 job_order_id 목록 조회
      final jobOrdersResponse = await _supabase
          .from('job_orders')
          .select('id')
          .eq('work_date', dateStr)
          .isFilter('deleted_at', null);

      final jobOrderIds = (jobOrdersResponse as List)
          .map((jo) => jo['id'] as String)
          .toList();

      // 해당 job_order_id들에 해당하는 accepted 상태의 placements 조회
      Set<String> assignedWorkerIds = {};
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

      // 3. 배정되지 않은 작업자만 필터링
      var availableWorkers = allWorkers
          .where((worker) => !assignedWorkerIds.contains(worker['id'] as String))
          .toList();

      // 4. 검색어가 있으면 추가 필터링 (대소문자 구분 없이)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        availableWorkers = availableWorkers.where((worker) {
          final name = (worker['name'] as String? ?? '').toLowerCase();
          final phone = (worker['phone'] as String? ?? '').toLowerCase();
          return name.contains(lowerQuery) || phone.contains(lowerQuery);
        }).toList();
      }

      return availableWorkers;
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


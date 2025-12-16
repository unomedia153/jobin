import 'package:supabase_flutter/supabase_flutter.dart';

class JobRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 오더 생성
  /// 
  /// [siteId] 현장 ID (필수)
  /// [workDate] 작업 날짜 (필수)
  /// [workType] 직종 (필수)
  /// [requiredWorkers] 필요 인원 (기본값 1)
  /// [unitPrice] 단가 (선택)
  /// [memo] 메모 (선택)
  Future<Map<String, dynamic>> createJobOrder({
    required String siteId,
    required DateTime workDate,
    required String workType,
    int requiredWorkers = 1,
    int? unitPrice,
    String? memo,
  }) async {
    final insertData = <String, dynamic>{
      'site_id': siteId,
      'work_date': workDate.toIso8601String().split('T')[0], // DATE 형식
      'work_type': workType,
      'required_workers': requiredWorkers,
    };

    // 선택 필드 추가
    if (unitPrice != null) {
      insertData['unit_price'] = unitPrice;
    }
    if (memo != null && memo.isNotEmpty) {
      insertData['memo'] = memo;
    }

    final response = await _supabase
        .from('job_orders')
        .insert(insertData)
        .select()
        .single();

    return response;
  }

  /// 오더 목록 조회 (현장별)
  Future<List<Map<String, dynamic>>> getJobOrdersBySite(String siteId) async {
    try {
      final response = await _supabase
          .from('job_orders')
          .select()
          .eq('site_id', siteId)
          .isFilter('deleted_at', null)
          .order('work_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}


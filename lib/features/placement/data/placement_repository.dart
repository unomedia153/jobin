import 'package:supabase_flutter/supabase_flutter.dart';

enum PlacementStatus {
  offered, // 배치의향서
  accepted, // 수락
  rejected, // 거절
}

class PlacementRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 배치의향서 목록 조회 (작업자용)
  Future<List<Map<String, dynamic>>> getProposalsByWorker(String workerId) async {
    final response = await _supabase
        .from('placements')
        .select('''
          *,
          job_orders (
            *,
            sites (
              *
            )
          )
        ''')
        .eq('worker_id', workerId)
        .eq('status', 'offered')
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// 배치 수락
  Future<void> acceptPlacement(String placementId) async {
    await _supabase
        .from('placements')
        .update({
          'status': 'accepted',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', placementId);
  }

  /// 배치 거절
  Future<void> rejectPlacement(String placementId) async {
    await _supabase
        .from('placements')
        .update({
          'status': 'rejected',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', placementId);
  }

  /// 배치의향서 생성 (소장용)
  Future<void> createProposal({
    required String jobOrderId,
    required String workerId,
  }) async {
    await _supabase.from('placements').insert({
      'job_order_id': jobOrderId,
      'worker_id': workerId,
      'status': 'offered',
    });
  }

  /// 배치 목록 조회 (소장용)
  Future<List<Map<String, dynamic>>> getPlacementsByAgency(String agencyId) async {
    final response = await _supabase
        .from('placements')
        .select('''
          *,
          job_orders (
            *,
            sites!inner (
              *,
              agency_id
            )
          ),
          profiles!placements_worker_id_fkey (
            name,
            phone
          )
        ''')
        .eq('job_orders.sites.agency_id', agencyId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}


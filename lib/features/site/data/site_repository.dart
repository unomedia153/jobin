import 'package:supabase_flutter/supabase_flutter.dart';

class SiteRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 소장님의 회사에 속한 현장 목록 조회
  Future<List<Map<String, dynamic>>> getSitesByAgency(String agencyId) async {
    try {
      final response = await _supabase
          .from('sites')
          .select()
          .eq('agency_id', agencyId)
          .isFilter('deleted_at', null)
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// 현장 생성
  /// 
  /// [agencyId] 회사 ID
  /// [name] 현장명 (필수)
  /// [lat] 위도
  /// [lng] 경도
  /// [radius] 반경 (기본값 30)
  /// [contactName] 담당자명 (선택)
  /// [contactPhone] 전화번호 (선택)
  /// [address] 주소 (선택)
  Future<Map<String, dynamic>> createSite({
    required String agencyId,
    required String name,
    required double lat,
    required double lng,
    int radius = 30,
    String? contactName,
    String? contactPhone,
    String? address,
  }) async {
    final insertData = <String, dynamic>{
      'agency_id': agencyId,
      'name': name,
      'lat': lat,
      'lng': lng,
      'radius': radius,
    };

    // 선택 필드 추가
    if (contactName != null && contactName.isNotEmpty) {
      insertData['contact_name'] = contactName;
    }
    if (contactPhone != null && contactPhone.isNotEmpty) {
      insertData['contact_phone'] = contactPhone;
    }
    if (address != null && address.isNotEmpty) {
      insertData['address'] = address;
    }

    final response = await _supabase
        .from('sites')
        .insert(insertData)
        .select()
        .single();

    return response;
  }

  /// 현장 ID로 조회
  Future<Map<String, dynamic>?> getSiteById(String siteId) async {
    try {
      final response = await _supabase
          .from('sites')
          .select()
          .eq('id', siteId)
          .isFilter('deleted_at', null)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }
}


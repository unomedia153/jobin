import 'package:supabase_flutter/supabase_flutter.dart';

class AgencyRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 용역회사 등록
  /// 
  /// [name] 회사명
  /// [ownerId] 소장님의 사용자 ID
  /// [representativeName] 대표자명
  /// [businessNumber] 사업자등록번호
  /// [address] 주소 (선택)
  /// [contactPhone] 대표 전화번호
  Future<Map<String, dynamic>> createAgency({
    required String name,
    required String ownerId,
    required String representativeName,
    required String businessNumber,
    String? address,
    required String contactPhone,
  }) async {
    final insertData = <String, dynamic>{
      'name': name,
      'owner_id': ownerId,
      'representative_name': representativeName,
      'business_number': businessNumber,
      'contact_phone': contactPhone,
    };

    // 주소는 선택 사항이므로 값이 있을 때만 추가
    if (address != null && address.isNotEmpty) {
      insertData['address'] = address;
    }

    final response = await _supabase
        .from('agencies')
        .insert(insertData)
        .select()
        .single();

    return response;
  }

  /// 소장님의 용역회사 조회
  Future<Map<String, dynamic>?> getAgencyByOwner(String ownerId) async {
    try {
      final response = await _supabase
          .from('agencies')
          .select()
          .eq('owner_id', ownerId)
          .isFilter('deleted_at', null)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }
}


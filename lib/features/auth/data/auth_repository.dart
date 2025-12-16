import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 카카오 로그인 (추후 구현)
  Future<AuthResponse> signInWithKakao() async {
    // TODO: 카카오 로그인 구현
    throw UnimplementedError('카카오 로그인은 아직 구현되지 않았습니다.');
  }

  /// 일반 회원가입
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
    String? phone,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
      },
    );

    return response;
  }

  /// 일반 로그인
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// SMS 인증 코드 전송 (Mocking)
  Future<void> sendSmsCode(String phone) async {
    // TODO: 실제 SMS 서비스 연동 또는 Mock 처리
    // 현재는 Mock 처리
    await Future.delayed(const Duration(seconds: 1));
  }

  /// SMS 인증 코드 확인 (Mocking)
  Future<bool> verifySmsCode(String phone, String code) async {
    // TODO: 실제 SMS 인증 로직 구현
    // Mock: '123456' 코드는 항상 성공
    return code == '123456';
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// 현재 세션 가져오기
  Session? getCurrentSession() {
    return _supabase.auth.currentSession;
  }

  /// 현재 사용자 가져오기
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// 현재 사용자의 프로필 조회
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = getCurrentUser();
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .isFilter('deleted_at', null)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  /// 프로필 역할 업데이트
  Future<void> updateProfileRole(String role) async {
    final user = getCurrentUser();
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // 먼저 profiles 테이블에 레코드가 있는지 확인
    final existingProfile = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (existingProfile == null) {
      // 프로필이 없으면 생성 (회원가입 시 자동 생성되지 않은 경우)
      await _supabase.from('profiles').insert({
        'id': user.id,
        'role': role,
        'name': user.userMetadata?['name'] ?? '',
        'phone': user.userMetadata?['phone'] ?? '',
        'verified': false,
      });
    } else {
      // 프로필이 있으면 역할만 업데이트
      await _supabase
          .from('profiles')
          .update({'role': role})
          .eq('id', user.id);
    }
  }
}

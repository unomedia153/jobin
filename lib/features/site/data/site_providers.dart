import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'site_repository.dart';

/// SiteRepository Provider
final siteRepositoryProvider = Provider<SiteRepository>((ref) {
  return SiteRepository();
});

/// 현재 로그인한 소장님의 회사 ID를 제공하는 Provider
final currentAgencyIdProvider = FutureProvider<String?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;

  // DashboardRepository를 통해 agency_id 조회
  // 임시로 직접 조회
  try {
    final response = await Supabase.instance.client
        .from('agencies')
        .select('id')
        .eq('owner_id', user.id)
        .isFilter('deleted_at', null)
        .maybeSingle();
    return response?['id'] as String?;
  } catch (e) {
    return null;
  }
});

/// 현재 회사의 현장 목록을 제공하는 Provider
final sitesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final agencyIdAsync = ref.watch(currentAgencyIdProvider);
  return agencyIdAsync.when(
    data: (agencyId) async {
      if (agencyId == null) return [];
      final repository = ref.read(siteRepositoryProvider);
      return await repository.getSitesByAgency(agencyId);
    },
    loading: () => [],
    error: (_, __) => [],
  );
});


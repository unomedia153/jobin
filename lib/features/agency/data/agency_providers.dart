import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'agency_repository.dart';

/// AgencyRepository Provider
final agencyRepositoryProvider = Provider<AgencyRepository>((ref) {
  return AgencyRepository();
});

/// 현재 로그인한 소장님의 회사 정보 Provider
final currentAgencyProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;

  final repository = ref.read(agencyRepositoryProvider);
  return await repository.getAgencyByOwner(user.id);
});

/// 회사 등록 여부 확인 Provider (캐싱)
final hasAgencyProvider = FutureProvider<bool>((ref) async {
  final agency = await ref.watch(currentAgencyProvider.future);
  return agency != null;
});


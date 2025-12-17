import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dispatch_repository.dart';

/// DispatchRepository Provider
final dispatchRepositoryProvider = Provider<DispatchRepository>((ref) {
  return DispatchRepository();
});

/// 가용 작업자 목록 Provider
/// 
/// [date] 작업 날짜
/// [searchQuery] 검색어 (선택)
final availableWorkersProvider = FutureProvider.family<List<Map<String, dynamic>>, ({DateTime date, String? searchQuery})>((ref, params) async {
  final repository = ref.read(dispatchRepositoryProvider);
  return await repository.getAvailableWorkers(
    date: params.date,
    searchQuery: params.searchQuery,
  );
});


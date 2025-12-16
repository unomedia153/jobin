import 'package:supabase_flutter/supabase_flutter.dart';

enum LedgerType {
  income, // 수입
  expense, // 지출
}

class LedgerRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 장부 항목 생성
  Future<void> createLedgerEntry({
    required String agencyId,
    required int amount,
    required LedgerType type,
    required String description,
  }) async {
    await _supabase.from('ledgers').insert({
      'agency_id': agencyId,
      'amount': amount,
      'type': type.name,
      'description': description,
    });
  }

  /// 장부 목록 조회
  Future<List<Map<String, dynamic>>> getLedgerEntries(String agencyId) async {
    final response = await _supabase
        .from('ledgers')
        .select('*')
        .eq('agency_id', agencyId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// 장부 항목 수정
  Future<void> updateLedgerEntry({
    required String ledgerId,
    int? amount,
    LedgerType? type,
    String? description,
  }) async {
    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (amount != null) updateData['amount'] = amount;
    if (type != null) updateData['type'] = type.name;
    if (description != null) updateData['description'] = description;

    await _supabase
        .from('ledgers')
        .update(updateData)
        .eq('id', ledgerId);
  }

  /// 장부 항목 삭제 (Soft Delete)
  Future<void> deleteLedgerEntry(String ledgerId) async {
    await _supabase
        .from('ledgers')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', ledgerId);
  }

  /// 장부 통계 조회 (수입/지출 합계)
  Future<Map<String, int>> getLedgerSummary(String agencyId) async {
    final entries = await getLedgerEntries(agencyId);

    int totalIncome = 0;
    int totalExpense = 0;

    for (final entry in entries) {
      if (entry['type'] == 'income') {
        totalIncome += (entry['amount'] as int? ?? 0);
      } else if (entry['type'] == 'expense') {
        totalExpense += (entry['amount'] as int? ?? 0);
      }
    }

    return {
      'income': totalIncome,
      'expense': totalExpense,
      'balance': totalIncome - totalExpense,
    };
  }
}


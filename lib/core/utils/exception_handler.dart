import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExceptionHandler {
  /// Supabase 예외를 사용자 친화적인 메시지로 변환
  static String getErrorMessage(dynamic error) {
    if (error is PostgrestException) {
      return _handlePostgrestException(error);
    } else if (error is AuthException) {
      return _handleAuthException(error);
    } else if (error is StorageException) {
      return _handleStorageException(error);
    } else {
      return error.toString();
    }
  }

  static String _handlePostgrestException(PostgrestException e) {
    // PostgreSQL 에러 코드에 따른 메시지 매핑
    switch (e.code) {
      case '23505': // unique_violation
        return '이미 존재하는 데이터입니다.';
      case '23503': // foreign_key_violation
        return '관련된 데이터가 없습니다.';
      case '23502': // not_null_violation
        return '필수 항목이 누락되었습니다.';
      case 'PGRST116': // no rows returned
        return '데이터를 찾을 수 없습니다.';
      default:
        return e.message.isNotEmpty ? e.message : '데이터베이스 오류가 발생했습니다.';
    }
  }

  static String _handleAuthException(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid') || message.contains('credentials')) {
      return '로그인 정보가 올바르지 않습니다.';
    } else if (message.contains('email') && message.contains('confirm')) {
      return '이메일 인증이 필요합니다.';
    } else if (message.contains('user') && message.contains('not found')) {
      return '사용자를 찾을 수 없습니다.';
    } else {
      return e.message.isNotEmpty ? e.message : '인증 오류가 발생했습니다.';
    }
  }

  static String _handleStorageException(StorageException e) {
    return e.message.isNotEmpty ? e.message : '파일 저장 오류가 발생했습니다.';
  }

  /// 에러를 SnackBar로 표시
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = getErrorMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 에러를 AlertDialog로 표시
  static Future<void> showErrorDialog(BuildContext context, dynamic error) async {
    final message = getErrorMessage(error);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}


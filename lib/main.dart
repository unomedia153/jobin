import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/constants/supabase_constants.dart';
import 'core/router/app_router.dart'; // goRouterProvider가 정의되어 있어야 함
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Supabase 초기화
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  // 2. 앱 실행 (ProviderScope 필수)
  runApp(const ProviderScope(child: JobInApp()));
}

// StatelessWidget -> ConsumerWidget으로 변경 (라우터 상태 감지용)
class JobInApp extends ConsumerWidget {
  const JobInApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 3. Riverpod을 통해 라우터 설정 가져오기 (로그인 상태 변경 시 자동 리다이렉트됨)
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'JobIn',
      debugShowCheckedModeBanner: false,

      // 기본 테마 (Mobile/Worker용)
      theme: AppTheme.workerTheme,

      // 라우터 연결
      routerConfig: goRouter,

      // 4. 반응형 테마 분기 전략 (이 부분 아주 좋습니다!)
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // 웹/태블릿 (Admin) 환경 -> Admin 테마 적용
            if (constraints.maxWidth >= AppConstants.mobileBreakpoint) {
              return Theme(
                data: AppTheme.adminTheme,
                child: child ?? const SizedBox.shrink(),
              );
            }
            // 모바일 (Worker) 환경 -> 기본 테마 유지
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}

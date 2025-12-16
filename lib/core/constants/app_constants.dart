class AppConstants {
  // Supabase 설정은 환경 변수로 관리 (실제 값은 .env 파일에 저장)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_SUPABASE_URL',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );

  // GPS 설정
  static const double attendanceRadiusMeters = 30.0;

  // Responsive Breakpoint
  static const double mobileBreakpoint = 800.0;

  // Worker App UI 설정 (노년층 배려)
  static const double workerMinFontSize = 16.0;
  static const double workerTitleFontSize = 20.0;
  static const double workerButtonHeight = 56.0;
}


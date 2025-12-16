import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Web과 Mobile을 구분하는 반응형 레이아웃 위젯
/// 
/// 800px 기준으로 Mobile/Web을 분기합니다.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? web;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.web,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppConstants.mobileBreakpoint) {
          return mobile;
        } else {
          return web ?? mobile;
        }
      },
    );
  }
}


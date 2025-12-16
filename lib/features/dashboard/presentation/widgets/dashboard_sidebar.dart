import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class DashboardSidebar extends StatelessWidget {
  final String currentRoute;

  const DashboardSidebar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      color: Colors.white,
      child: Column(
        children: [
          // 로고
          Container(
            padding: const EdgeInsets.all(16),
            child: Icon(
              Icons.business_center,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const Divider(height: 1),
          // 네비게이션 아이콘들
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _SidebarItem(
                  icon: Icons.dashboard,
                  label: '개요',
                  isActive: currentRoute == '/admin-dashboard',
                  onTap: () => context.go('/admin-dashboard'),
                ),
                _SidebarItem(
                  icon: Icons.receipt_long,
                  label: '오더',
                  isActive: false,
                  onTap: () {
                    // TODO: 오더 관리 페이지
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('오더 관리 기능은 준비 중입니다.')),
                    );
                  },
                ),
                _SidebarItem(
                  icon: Icons.location_on,
                  label: '현장',
                  isActive: false,
                  onTap: () {
                    // TODO: 현장 관리 페이지
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('현장 관리 기능은 준비 중입니다.')),
                    );
                  },
                ),
                _SidebarItem(
                  icon: Icons.people,
                  label: '작업자',
                  isActive: false,
                  onTap: () {
                    // TODO: 작업자 관리 페이지
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('작업자 관리 기능은 준비 중입니다.')),
                    );
                  },
                ),
                _SidebarItem(
                  icon: Icons.account_balance_wallet,
                  label: '장부',
                  isActive: false,
                  onTap: () {
                    // TODO: 장부 관리 페이지
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('장부 관리 기능은 준비 중입니다.')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryLight.withValues(alpha: 0.1) : null,
          border: isActive
              ? Border(
                  left: BorderSide(
                    color: AppColors.primary,
                    width: 3,
                  ),
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


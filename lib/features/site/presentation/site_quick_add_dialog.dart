import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/site_providers.dart';
import '../../../../core/constants/app_colors.dart';

class SiteQuickAddDialog extends ConsumerStatefulWidget {
  final String agencyId;

  const SiteQuickAddDialog({
    super.key,
    required this.agencyId,
  });

  @override
  ConsumerState<SiteQuickAddDialog> createState() => _SiteQuickAddDialogState();
}

class _SiteQuickAddDialogState extends ConsumerState<SiteQuickAddDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(siteRepositoryProvider);
      
      // 기본 좌표 (서울시청 좌표, 나중에 주소 검색으로 변경 가능)
      await repository.createSite(
        agencyId: widget.agencyId,
        name: _nameController.text.trim(),
        lat: 37.5665, // 기본값
        lng: 126.9780, // 기본값
        contactName: _contactNameController.text.trim().isEmpty
            ? null
            : _contactNameController.text.trim(),
        contactPhone: _contactPhoneController.text.trim().isEmpty
            ? null
            : _contactPhoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
      );

      if (!mounted) return;

      // 성공 시 새로 생성된 현장 정보 반환
      final newSite = {
        'name': _nameController.text.trim(),
      };

      Navigator.of(context).pop(newSite);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('현장 등록 실패: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 제목
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '새 현장 추가',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 현장명 (필수)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '현장명 *',
                  border: OutlineInputBorder(),
                  hintText: '예: 서울시청 신축공사',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '현장명을 입력해주세요';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              // 담당자
              TextFormField(
                controller: _contactNameController,
                decoration: const InputDecoration(
                  labelText: '담당자',
                  border: OutlineInputBorder(),
                  hintText: '예: 홍길동',
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              // 전화번호
              TextFormField(
                controller: _contactPhoneController,
                decoration: const InputDecoration(
                  labelText: '전화번호',
                  border: OutlineInputBorder(),
                  hintText: '예: 010-1234-5678',
                ),
                keyboardType: TextInputType.phone,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              // 주소
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: '주소',
                  border: OutlineInputBorder(),
                  hintText: '예: 서울특별시 중구 세종대로 110',
                ),
                maxLines: 2,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              // 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('등록'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


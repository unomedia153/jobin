import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../site/data/site_providers.dart';
import '../../../site/presentation/site_quick_add_dialog.dart';
import '../../../job/data/job_providers.dart';
import '../../../../core/constants/app_colors.dart';

class JobOrderCreateDialog extends ConsumerStatefulWidget {
  const JobOrderCreateDialog({super.key});

  @override
  ConsumerState<JobOrderCreateDialog> createState() =>
      _JobOrderCreateDialogState();
}

class _JobOrderCreateDialogState
    extends ConsumerState<JobOrderCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _memoController = TextEditingController();
  final _customWorkTypeController = TextEditingController();

  String? _selectedSiteId;
  DateTime _workDate = DateTime.now().add(const Duration(days: 1)); // 내일
  String? _selectedWorkType;
  int _requiredWorkers = 1;
  int? _unitPrice;
  bool _isLoading = false;
  bool _showCustomWorkType = false;

  // 자주 쓰는 직종 목록
  final List<String> _commonWorkTypes = [
    '조공',
    '양중',
    '청소',
    '곰빵',
    '철거',
  ];

  @override
  void dispose() {
    _memoController.dispose();
    _customWorkTypeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _workDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _workDate = picked;
      });
    }
  }

  Future<void> _openSiteQuickAdd() async {
    final agencyIdAsync = ref.read(currentAgencyIdProvider);
    
    final agencyId = await agencyIdAsync.when(
      data: (id) => Future.value(id),
      loading: () => Future.value(null),
      error: (_, __) => Future.value(null),
    );
    
    if (agencyId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('회사 정보를 찾을 수 없습니다.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final result = await showDialog(
      context: context,
      builder: (context) => SiteQuickAddDialog(agencyId: agencyId),
    );

    if (result != null) {
      if (!mounted) return;
      
      // 현장 목록 새로고침
      ref.invalidate(sitesProvider);
      
      // 새로 생성된 현장을 자동으로 선택
      final sitesAsync = ref.read(sitesProvider);
      final sites = await sitesAsync.when(
        data: (sites) => Future.value(sites),
        loading: () => Future.value(<Map<String, dynamic>>[]),
        error: (_, __) => Future.value(<Map<String, dynamic>>[]),
      );
      
      if (!mounted) return;
      
      final newSiteName = result['name'] as String;
      final newSite = sites.firstWhere(
        (site) => site['name'] == newSiteName,
        orElse: () => <String, dynamic>{},
      );
      
      if (newSite.isNotEmpty) {
        setState(() {
          _selectedSiteId = newSite['id'] as String;
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSiteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('현장을 선택해주세요'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final workType = _showCustomWorkType
        ? _customWorkTypeController.text.trim()
        : _selectedWorkType;

    if (workType == null || workType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('직종을 선택하거나 입력해주세요'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(jobRepositoryProvider);
      await repository.createJobOrder(
        siteId: _selectedSiteId!,
        workDate: _workDate,
        workType: workType,
        requiredWorkers: _requiredWorkers,
        unitPrice: _unitPrice,
        memo: _memoController.text.trim().isEmpty
            ? null
            : _memoController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('오더가 등록되었습니다.'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pop(true); // 성공 시 true 반환
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오더 등록 실패: $e'),
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
    final sitesAsync = ref.watch(sitesProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
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
                    '오더 등록',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 스크롤 가능한 영역
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 현장 선택
                      sitesAsync.when(
                        data: (sites) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: _selectedSiteId,
                                decoration: const InputDecoration(
                                  labelText: '현장 선택 *',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  ...sites.map((site) {
                                    return DropdownMenuItem<String>(
                                      value: site['id'] as String,
                                      child: Text(site['name'] as String),
                                    );
                                  }),
                                ],
                                onChanged: _isLoading
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _selectedSiteId = value;
                                        });
                                      },
                                validator: (value) {
                                  if (value == null) {
                                    return '현장을 선택해주세요';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              // 새 현장 추가 버튼
                              OutlinedButton.icon(
                                onPressed: _isLoading ? null : _openSiteQuickAdd,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('새 현장 추가'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (error, stack) => Text(
                          '현장 목록을 불러올 수 없습니다: $error',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 작업 날짜
                      InkWell(
                        onTap: _isLoading ? null : _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: '작업 날짜 *',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(_workDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 직종
                      const Text(
                        '직종 *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._commonWorkTypes.map((type) {
                            final isSelected = _selectedWorkType == type;
                            return FilterChip(
                              label: Text(type),
                              selected: isSelected,
                              onSelected: _isLoading
                                  ? null
                                  : (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedWorkType = type;
                                          _showCustomWorkType = false;
                                          _customWorkTypeController.clear();
                                        } else {
                                          _selectedWorkType = null;
                                        }
                                      });
                                    },
                              selectedColor: AppColors.primaryLight,
                              checkmarkColor: AppColors.primary,
                            );
                          }),
                          FilterChip(
                            label: const Text('직접 입력'),
                            selected: _showCustomWorkType,
                            onSelected: _isLoading
                                ? null
                                : (selected) {
                                    setState(() {
                                      _showCustomWorkType = selected;
                                      if (selected) {
                                        _selectedWorkType = null;
                                      }
                                    });
                                  },
                            selectedColor: AppColors.primaryLight,
                            checkmarkColor: AppColors.primary,
                          ),
                        ],
                      ),
                      if (_showCustomWorkType) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _customWorkTypeController,
                          decoration: const InputDecoration(
                            labelText: '직종 입력',
                            border: OutlineInputBorder(),
                            hintText: '예: 용접, 도배 등',
                          ),
                          enabled: !_isLoading,
                        ),
                      ],
                      const SizedBox(height: 16),
                      // 필요 인원
                      Row(
                        children: [
                          const Text(
                            '필요 인원 *',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _isLoading || _requiredWorkers <= 1
                                ? null
                                : () {
                                    setState(() {
                                      _requiredWorkers--;
                                    });
                                  },
                          ),
                          Container(
                            width: 60,
                            alignment: Alignment.center,
                            child: Text(
                              '$_requiredWorkers명',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _requiredWorkers++;
                                    });
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 단가
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: '단가 (노임)',
                          border: OutlineInputBorder(),
                          hintText: '예: 150000',
                          suffixText: '원',
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !_isLoading,
                        onChanged: (value) {
                          final price = int.tryParse(value);
                          setState(() {
                            _unitPrice = price;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // 메모
                      TextFormField(
                        controller: _memoController,
                        decoration: const InputDecoration(
                          labelText: '메모 (특이사항)',
                          border: OutlineInputBorder(),
                          hintText: '예: 오전 8시 집합, 안전장비 지참 등',
                        ),
                        maxLines: 3,
                        enabled: !_isLoading,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 하단 버튼
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('등록하기'),
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


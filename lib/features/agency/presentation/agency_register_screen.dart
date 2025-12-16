import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/agency_providers.dart';
import '../../../core/utils/exception_handler.dart';

class AgencyRegisterScreen extends ConsumerStatefulWidget {
  const AgencyRegisterScreen({super.key});

  @override
  ConsumerState<AgencyRegisterScreen> createState() => _AgencyRegisterScreenState();
}

class _AgencyRegisterScreenState extends ConsumerState<AgencyRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _representativeNameController = TextEditingController();
  final _businessNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _representativeNameController.dispose();
    _businessNumberController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
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
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final agencyRepository = ref.read(agencyRepositoryProvider);
      await agencyRepository.createAgency(
        name: _nameController.text.trim(),
        ownerId: user.id,
        representativeName: _representativeNameController.text.trim(),
        businessNumber: _businessNumberController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        contactPhone: _phoneController.text.trim(),
      );

      if (mounted) {
        // Provider 갱신하여 회사 정보가 로드되도록 함
        ref.invalidate(currentAgencyProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('회사 등록이 완료되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 대시보드로 이동
        context.go('/admin-dashboard');
      }
    } catch (e) {
      if (mounted) {
        ExceptionHandler.showErrorSnackBar(context, e);
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        if (!mounted) return;
        
        final router = GoRouter.of(context);
        
        // 뒤로가기 시 확인 다이얼로그
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('회사 등록 취소'),
            content: const Text(
              '회사 정보를 등록하지 않으면 서비스를 이용할 수 없습니다.\n정말 취소하시겠습니까?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('계속 등록'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('취소하고 로그아웃'),
              ),
            ],
          ),
        );

        if (shouldPop == true) {
          if (!mounted) return;
          // 로그아웃 후 로그인 페이지로 이동
          await Supabase.instance.client.auth.signOut();
          if (mounted) {
            router.go('/login');
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('용역회사 등록'),
          centerTitle: true,
          automaticallyImplyLeading: false, // 뒤로가기 버튼 숨김
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '회사 정보를 입력해주세요',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '소장님은 반드시 회사를 등록해야 서비스를 이용할 수 있습니다.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '회사명 *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '회사명을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _representativeNameController,
                decoration: const InputDecoration(
                  labelText: '대표자명 *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '대표자명을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _businessNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '사업자등록번호 *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                  hintText: '000-00-00000',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '사업자등록번호를 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: '주소',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  hintText: '주소를 입력하세요 (추후 주소 API 연동 예정)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: '대표 전화번호 *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  hintText: '010-0000-0000',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '대표 전화번호를 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        '등록 완료',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}


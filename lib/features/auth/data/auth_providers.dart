import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';

/// AuthRepository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});


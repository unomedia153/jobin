import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'job_repository.dart';

/// JobRepository Provider
final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository();
});


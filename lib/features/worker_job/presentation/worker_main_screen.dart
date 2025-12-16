import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkerMainScreen extends ConsumerWidget {
  const WorkerMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('작업 일정'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          '배치의향서 목록이 여기에 표시됩니다.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}


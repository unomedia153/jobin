import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class ProposalCard extends StatelessWidget {
  final Map<String, dynamic> proposal;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const ProposalCard({
    super.key,
    required this.proposal,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final jobOrder = proposal['job_orders'] as Map<String, dynamic>?;
    final site = jobOrder?['sites'] as Map<String, dynamic>?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              site?['name'] ?? '현장명 없음',
              style: const TextStyle(
                fontSize: AppConstants.workerTitleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (jobOrder?['work_date'] != null)
              Text(
                '작업일: ${jobOrder!['work_date']}',
                style: const TextStyle(
                  fontSize: AppConstants.workerMinFontSize,
                ),
              ),
            if (jobOrder?['work_type'] != null)
              Text(
                '작업 유형: ${jobOrder!['work_type']}',
                style: const TextStyle(
                  fontSize: AppConstants.workerMinFontSize,
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onReject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.rejected,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, AppConstants.workerButtonHeight),
                    ),
                    child: const Text('거절'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accepted,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, AppConstants.workerButtonHeight),
                    ),
                    child: const Text('수락'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


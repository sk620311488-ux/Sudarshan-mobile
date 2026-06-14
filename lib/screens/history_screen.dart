import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_card.dart';
import 'quiz_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attempts = controller.attempts.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attempt History'),
      ),
      body: attempts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: AppColors.muted),
                  const SizedBox(height: 16),
                  Text('No attempts yet', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text('Take a test to see your history here.'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: attempts.length,
              itemBuilder: (context, index) {
                final attempt = attempts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SoftCard(
                    color: attempt.isDaily ? AppColors.yellowSoft : AppColors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDate(attempt.savedAtIso),
                              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (attempt.isDaily)
                              const _MiniTag(label: 'Daily', color: AppColors.yellow),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(attempt.testTitle, style: theme.textTheme.titleLarge),
                        Text('${attempt.subject} | ${attempt.chapter}', style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _StatItem(label: 'Score', value: '${attempt.score}/${attempt.total}'),
                            const SizedBox(width: 16),
                            _StatItem(label: 'Percent', value: '${attempt.percent}%'),
                            const SizedBox(width: 16),
                            _StatItem(label: 'Time', value: _formatTime(attempt.timeSpentSec)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios, size: 16),
                              onPressed: () {
                                // Maybe show details or retake?
                                // For now, let's find the test and allow retake if it exists
                                final test = controller.tests.firstWhere(
                                  (t) => t.id == attempt.testId,
                                  orElse: () => AppTest(
                                    id: attempt.testId,
                                    title: attempt.testTitle,
                                    subject: attempt.subject,
                                    chapter: attempt.chapter,
                                    level: 'N/A',
                                    timeLimitMin: 0,
                                    questions: [],
                                  ),
                                );
                                if (test.questions.isNotEmpty) {
                                   Navigator.of(context).push(
                                     MaterialPageRoute(
                                       builder: (_) => QuizScreen(controller: controller, test: test),
                                     ),
                                   );
                                } else {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     const SnackBar(content: Text('Original test data not found for retake.'))
                                   );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

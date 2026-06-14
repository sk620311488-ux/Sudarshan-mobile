import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_card.dart';

class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen({
    super.key,
    required this.profile,
  });

  final PublicStudentProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        profile.level <= 1 ? 0.0 : (profile.totalExp / (300 * profile.level * profile.level)).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(profile.displayName),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            SoftCard(
              color: AppColors.blueSoft,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.accent,
                    child: Text(
                      _initials(profile.displayName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(profile.displayName, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${profile.customStudentId}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(profile.rankTitle, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ProfileMetric(label: 'Level', value: '${profile.level}'),
                      _ProfileMetric(label: 'EXP', value: '${profile.totalExp}'),
                      _ProfileMetric(label: 'Streak', value: '${profile.dailyStreak}'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                  if (profile.bio.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      profile.bio,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SoftCard(
                    color: AppColors.greenSoft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tests Completed', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('${profile.attemptCount}', style: theme.textTheme.headlineSmall),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SoftCard(
                    color: AppColors.tealSoft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Memory Cards', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('${profile.notebookCount}', style: theme.textTheme.headlineSmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('Achievements', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            if (profile.achievements.isEmpty)
              const SoftCard(
                child: Text('No public achievements available yet.'),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: profile.achievements
                    .map(
                      (item) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return 'S';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

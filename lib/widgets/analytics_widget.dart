import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'soft_card.dart';

class SubjectMasteryCard extends StatelessWidget {
  const SubjectMasteryCard({super.key, required this.mastery});
  final Map<String, double> mastery;

  @override
  Widget build(BuildContext context) {
    if (mastery.isEmpty) return const SizedBox.shrink();

    return SoftCard(
      color: AppColors.tealSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subject Mastery', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...mastery.entries.take(4).map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('${e.value.round()}%', style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: e.value / 100,
                    backgroundColor: AppColors.line,
                    color: AppColors.teal,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class WeeklyActivityCard extends StatelessWidget {
  const WeeklyActivityCard({super.key, required this.activity});
  final List<int> activity;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Activity', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final count = activity[index];
                final day = DateTime.now().subtract(Duration(days: 6 - index));
                final height = (count * 20.0).clamp(8.0, 80.0);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 25,
                      height: height,
                      decoration: BoxDecoration(
                        color: count > 0 ? AppColors.blueSoft : AppColors.line,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(['M','T','W','T','F','S','S'][day.weekday - 1],
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class WeakTopicsCard extends StatelessWidget {
  const WeakTopicsCard({super.key, required this.topics});
  final Map<String, int> topics;

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) return const SizedBox.shrink();

    return SoftCard(
      color: AppColors.coralSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Focus Needed', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Top topics where you need more revision.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topics.keys.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

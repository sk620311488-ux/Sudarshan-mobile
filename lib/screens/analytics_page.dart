import 'package:flutter/material.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_card.dart';
import '../widgets/analytics_widget.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key, required this.controller});
  final AppController controller;

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  String? _selectedSubject;
  String? _selectedChapter;

  void _onDeepExplain({String? subject, String? chapter, String? topic}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final explanation = await widget.controller.aiExplainDeep(
        subject: subject ?? 'General',
        chapter: chapter ?? 'Advanced',
        topic: topic ?? 'Core Concept',
      );
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology, color: AppColors.accent, size: 28),
                  const SizedBox(width: 12),
                  const Text('Sovereign AI Deep Explanation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(explanation, style: const TextStyle(fontSize: 16, height: 1.5)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it!'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mastery = widget.controller.subjectMastery;
    final activity = widget.controller.weeklyActivity;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text('Performance Dashboard', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 18),
          
          // 1. 7-Day Activity Chart
          WeeklyActivityCard(activity: activity),
          const SizedBox(height: 18),

          // 2. Subject Mastery (Pie Chart concept represented by grouped bars/cards)
          Text('Subject Mastery', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          _SubjectPieSimulator(
            mastery: mastery,
            onSubjectTap: (sub) => setState(() {
              _selectedSubject = sub;
              _selectedChapter = null;
            }),
          ),
          const SizedBox(height: 18),

          if (_selectedSubject != null) ...[
            const Divider(),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$_selectedSubject Analysis', style: theme.textTheme.titleLarge),
                IconButton(onPressed: () => setState(() => _selectedSubject = null), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 12),
            _ChapterErrorAnalysis(
              controller: widget.controller,
              subject: _selectedSubject!,
              onChapterTap: (ch) => setState(() => _selectedChapter = ch),
            ),
          ],

          if (_selectedChapter != null) ...[
            const SizedBox(height: 18),
            Text('$_selectedChapter Topics', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _TopicErrorAnalysis(
              controller: widget.controller,
              subject: _selectedSubject!,
              chapter: _selectedChapter!,
              onDeepExplain: (topic) => _onDeepExplain(
                subject: _selectedSubject,
                chapter: _selectedChapter,
                topic: topic,
              ),
            ),
          ],
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _SubjectPieSimulator extends StatelessWidget {
  const _SubjectPieSimulator({required this.mastery, required this.onSubjectTap});
  final Map<String, double> mastery;
  final Function(String) onSubjectTap;

  @override
  Widget build(BuildContext context) {
    if (mastery.isEmpty) return const SoftCard(child: Text('No test data yet.'));

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: mastery.entries.map((e) {
        final color = _getColorForPercent(e.value);
        return GestureDetector(
          onTap: () => onSubjectTap(e.key),
          child: Container(
            width: (MediaQuery.of(context).size.width - 48) / 2,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${e.value.round()}% Mastery', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getColorForPercent(double p) {
    if (p >= 80) return AppColors.green;
    if (p >= 50) return AppColors.yellow;
    return AppColors.coral;
  }
}

class _ChapterErrorAnalysis extends StatelessWidget {
  const _ChapterErrorAnalysis({required this.controller, required this.subject, required this.onChapterTap});
  final AppController controller;
  final String subject;
  final Function(String) onChapterTap;

  @override
  Widget build(BuildContext context) {
    final attempts = controller.attempts.where((a) => a.subject == subject).toList();
    final chapterErrors = <String, int>{};
    for (final a in attempts) {
      final errors = a.total - a.score;
      if (errors > 0) {
        chapterErrors[a.chapter] = (chapterErrors[a.chapter] ?? 0) + errors;
      }
    }

    if (chapterErrors.isEmpty) return const SoftCard(child: Text('Is subject mein koi galtiyan nahi mili! Great job.'));

    return Column(
      children: chapterErrors.entries.map<Widget>((e) => ListTile(
        title: Text(e.key),
        subtitle: Text('${e.value} galtiyan'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => onChapterTap(e.key),
      )).toList(),
    );
  }
}

class _TopicErrorAnalysis extends StatelessWidget {
  const _TopicErrorAnalysis({
    required this.controller, 
    required this.subject, 
    required this.chapter,
    required this.onDeepExplain,
  });
  final AppController controller;
  final String subject;
  final String chapter;
  final Function(String) onDeepExplain;

  @override
  Widget build(BuildContext context) {
    final cards = controller.notebookCards.where((c) => c.subject == subject && c.chapter == chapter).toList();
    final topicMistakes = <String, int>{};
    for (final c in cards) {
      if (c.mistakeCount > 0) {
        topicMistakes[c.topic] = (topicMistakes[c.topic] ?? 0) + c.mistakeCount;
      }
    }

    if (topicMistakes.isEmpty) return const SoftCard(child: Text('Is chapter ke topics mein koi recorded galtiyan nahi hain.'));

    return Column(
      children: topicMistakes.entries.map<Widget>((e) => SoftCard(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${e.value} mistakes tracked'),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => onDeepExplain(e.key),
              icon: const Icon(Icons.psychology, size: 16),
              label: const Text('AI Deep explain'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                backgroundColor: AppColors.tealSoft,
                foregroundColor: AppColors.text,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

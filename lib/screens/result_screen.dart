import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/app_models.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_card.dart';
import 'quiz_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.controller,
    required this.test,
    required this.summary,
    this.statusMessage = '',
  });

  final AppController controller;
  final AppTest test;
  final ResultSummary summary;
  final String statusMessage;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<QuestionReview> get _reviews {
    final reviews = [...widget.summary.questionReviews];
    reviews.sort((a, b) => a.index.compareTo(b.index));
    return reviews;
  }

  List<QuestionReview> get _scoredReviews =>
      _reviews.where((item) => item.isScored).toList();

  List<QuestionReview> get _filteredReviews {
    switch (_filter) {
      case 'correct':
        return _reviews.where((item) => item.isScored && item.isCorrect).toList();
      case 'wrong':
        return _reviews.where((item) => item.isScored && !item.isCorrect).toList();
      case 'review':
        return _reviews.where((item) => !item.isScored).toList();
      default:
        return _reviews;
    }
  }

  int get _correctCount => _scoredReviews.where((item) => item.isCorrect).length;

  int get _wrongCount => _scoredReviews.where((item) => !item.isCorrect).length;

  double get _accuracy {
    if (_scoredReviews.isEmpty) {
      return widget.summary.percent.toDouble();
    }
    return (_correctCount / _scoredReviews.length) * 100;
  }

  void _shareResult(BuildContext context) {
    final name = widget.controller.session?.name ?? 'Student';
    final studentId = widget.controller.session?.studentId ?? 'N/A';
    final text = [
      'SUDARSHAN CHALLENGE',
      'Student: $name',
      'ID: $studentId',
      'Test: ${widget.test.title}',
      'Score: ${widget.summary.correct}/${widget.summary.total} (${widget.summary.percent}%)',
      'Accuracy: ${_accuracy.round()}%',
      'Time: ${_format(widget.summary.timeSpentSec)}',
      'EXP: +${widget.summary.earnedExp}',
    ].join('\n');

    SharePlus.instance.share(ShareParams(text: text));
  }

  void _showAiAnalysis(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final analysis = await widget.controller.aiAnalyzePerformance();
      if (!context.mounted) return;
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
                  Text('Sudarshan AI Advanced Analysis', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(analysis, style: const TextStyle(fontSize: 16, height: 1.5)),
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
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Analysis failed: $e')));
      }
    }
  }

  String _format(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remaining = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remaining';
  }

  void _retryWrongQuestions() {
    final wrongReviews = _scoredReviews.where((item) => !item.isCorrect).toList();
    if (wrongReviews.isEmpty) {
      return;
    }

    final retryCards = wrongReviews
        .map(
          (review) => NotebookCard(
            subject: widget.test.subject,
            chapter: widget.test.chapter,
            topic: review.topic.isEmpty ? 'general' : review.topic,
            question: review.question,
            answer: review.correctAnswer,
            options: review.options,
            questionType: review.questionType,
            scheduleLabel: 'Due now',
            dueAtIso: DateTime.now().toIso8601String(),
            mistakeCount: 1,
          ),
        )
        .toList();

    final retryTest = widget.controller.createRetryTest(retryCards);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          controller: widget.controller,
          test: retryTest,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedWeakTopics = widget.summary.weakTopics.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final theme = Theme.of(context);
    final wrongReviews = _scoredReviews.where((item) => !item.isCorrect).toList();
    final scoredTotal = _scoredReviews.length;
    final displayPercent = _accuracy.round();
    final scoreText = scoredTotal == 0
        ? 'No auto-scored questions'
        : '$_correctCount / $scoredTotal correct | $displayPercent%';

    return Scaffold(
      appBar: AppBar(title: const Text('Analysis')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SoftCard(
                  color: AppColors.blueSoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.accent,
                            child: Icon(Icons.bolt, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Experience Gained', style: theme.textTheme.labelLarge),
                                Text(
                                  '+${widget.summary.earnedExp} EXP',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (displayPercent >= 80)
                            const Icon(Icons.workspace_premium, color: Colors.orange, size: 40),
                        ],
                      ),
                      if (widget.summary.dailyPoints > 0) ...[
                        const Divider(height: 24),
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppColors.yellow,
                              child: Icon(Icons.stars, color: Colors.white),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Leaderboard Points', style: theme.textTheme.labelLarge),
                                  Text(
                                    '+${widget.summary.dailyPoints} Points',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.orange[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.yellowSoft,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'DAILY BONUS',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricCard(
                  label: 'Correct',
                  value: _correctCount.toString(),
                  color: AppColors.greenSoft,
                  icon: Icons.check_circle_outline,
                ),
                _MetricCard(
                  label: 'Wrong',
                  value: _wrongCount.toString(),
                  color: AppColors.coralSoft,
                  icon: Icons.cancel_outlined,
                ),
                _MetricCard(
                  label: 'Accuracy',
                  value: '${_accuracy.round()}%',
                  color: AppColors.blueSoft,
                  icon: Icons.insights_outlined,
                ),
                _MetricCard(
                  label: 'Time',
                  value: _format(widget.summary.timeSpentSec),
                  color: AppColors.yellowSoft,
                  icon: Icons.timer_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SoftCard(
              color: displayPercent >= 70 ? AppColors.greenSoft : AppColors.yellowSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.test.title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(scoreText, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Time ${_format(widget.summary.timeSpentSec)} / ${widget.test.timeLimitMin} min',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.psychology),
                      label: const Text('AI Advanced Analysis'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tealSoft,
                        foregroundColor: AppColors.text,
                      ),
                      onPressed: () => _showAiAnalysis(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Share Result'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.text,
                        foregroundColor: AppColors.white,
                      ),
                      onPressed: () => _shareResult(context),
                    ),
                  ),
                ],
              ),
            ),
            if (sortedWeakTopics.isNotEmpty) ...[
              const SizedBox(height: 16),
              SoftCard(
                color: AppColors.tealSoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weak Topics', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: sortedWeakTopics
                          .map(
                            (entry) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppColors.teal.withValues(alpha: 0.25)),
                              ),
                              child: Text('${entry.key}  x${entry.value}'),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Question Analysis', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _filter == 'all',
                        onTap: () => setState(() => _filter = 'all'),
                      ),
                      _FilterChip(
                        label: 'Correct',
                        selected: _filter == 'correct',
                        onTap: () => setState(() => _filter = 'correct'),
                      ),
                      _FilterChip(
                        label: 'Wrong',
                        selected: _filter == 'wrong',
                        onTap: () => setState(() => _filter = 'wrong'),
                      ),
                      _FilterChip(
                        label: 'Review',
                        selected: _filter == 'review',
                        onTap: () => setState(() => _filter = 'review'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_filteredReviews.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No questions in this view.',
                        style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.muted),
                      ),
                    )
                  else
                    ..._filteredReviews.map(
                      (review) => _QuestionReviewTile(
                        controller: widget.controller,
                        review: review,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.statusMessage.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              SoftCard(
                color: AppColors.blueSoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Save Status', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Text(widget.statusMessage, style: theme.textTheme.bodyLarge),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: wrongReviews.isEmpty ? null : _retryWrongQuestions,
                icon: const Icon(Icons.refresh),
                label: Text('Retry Wrong Questions (${wrongReviews.length})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Back To Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: color,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.text),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: selected ? AppColors.accent : Theme.of(context).colorScheme.surface,
      side: BorderSide(color: selected ? AppColors.accent : Theme.of(context).dividerColor),
      onPressed: onTap,
    );
  }
}

class _QuestionReviewTile extends StatefulWidget {
  const _QuestionReviewTile({
    required this.controller,
    required this.review,
  });

  final AppController controller;
  final QuestionReview review;

  @override
  State<_QuestionReviewTile> createState() => _QuestionReviewTileState();
}

class _QuestionReviewTileState extends State<_QuestionReviewTile> {
  bool _loading = false;
  Map<String, dynamic>? _evaluation;

  Color get _borderColor {
    if (!widget.review.isScored) {
      return AppColors.blue;
    }
    return widget.review.isCorrect ? AppColors.green : AppColors.coral;
  }

  Color get _softColor {
    if (!widget.review.isScored) {
      return AppColors.blueSoft;
    }
    return widget.review.isCorrect ? AppColors.greenSoft : AppColors.coralSoft;
  }

  String get _statusLabel {
    if (!widget.review.isScored) {
      return 'Review';
    }
    return widget.review.isCorrect ? 'Correct' : 'Wrong';
  }

  Future<void> _evaluate() async {
    setState(() => _loading = true);
    try {
      final res = await widget.controller.aiEvaluateSubjective(
        question: widget.review.question,
        modelAnswer: widget.review.correctAnswer,
        studentAnswer: widget.review.selectedAnswer,
      );
      setState(() => _evaluation = res);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showAnswers = widget.review.isScored || widget.review.selectedAnswer.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _softColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _borderColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _statusLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (widget.review.topic.trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Text(
                                widget.review.topic,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Q${widget.review.index + 1}. ${widget.review.question}',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showAnswers) ...[
              const SizedBox(height: 14),
              _AnswerLine(
                label: widget.review.isScored ? 'Your answer' : 'Student answer',
                value: widget.review.selectedAnswer.isEmpty ? 'No answer' : widget.review.selectedAnswer,
                color: widget.review.isScored && widget.review.isCorrect ? AppColors.green : _borderColor,
              ),
              const SizedBox(height: 8),
              _AnswerLine(
                label: 'Correct answer',
                value: widget.review.correctAnswer.isEmpty ? 'Not provided' : widget.review.correctAnswer,
                color: AppColors.green,
              ),
            ],
            if (widget.review.explanation.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Explanation',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                widget.review.explanation,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            ],
            if (!widget.review.isScored && widget.review.selectedAnswer.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              if (_evaluation == null)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: AppColors.muted),
                              SizedBox(width: 8),
                              Text(
                                'Manual Check',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Model answer se apne answer ko compare karke marks self-evaluate karein. Deep analysis ke liye AI Check use karein.',
                            style: TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _evaluate,
                        icon: _loading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.psychology, size: 18),
                        label: Text(_loading ? 'AI Analyzing...' : 'Deep AI Check'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.tealSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.teal),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'AI Evaluation',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.teal),
                          ),
                          Text(
                            '${_evaluation!['score']}/100',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.teal),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_evaluation!['feedback']}',
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnswerLine extends StatelessWidget {
  const _AnswerLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}

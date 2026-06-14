import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_models.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_card.dart';

class FlashcardStudyScreen extends StatefulWidget {
  const FlashcardStudyScreen({
    super.key,
    required this.controller,
    required this.cards,
  });

  final AppController controller;
  final List<NotebookCard> cards;

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  int _currentIndex = 0;
  bool _showAnswer = false;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleFeedback(String quality) {
    HapticFeedback.mediumImpact();
    widget.controller.recordFlashcardFeedback(widget.cards[_currentIndex], quality);

    if (_currentIndex < widget.cards.length - 1) {
      setState(() {
        _showAnswer = false;
        _currentIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sabhi cards poore hue. Shandaar kaam.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = widget.cards[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Practice: ${_currentIndex + 1}/${widget.cards.length}'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          if (card.mistakeCount > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SoftCard(
                color: AppColors.coralSoft,
                child: Row(
                  children: [
                    const Icon(Icons.report, color: AppColors.coral),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This card has been missed ${card.mistakeCount} times.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (card.mistakeCount > 1) const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.cards.length,
            backgroundColor: theme.dividerColor,
            color: AppColors.accent,
            minHeight: 6,
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.cards.length,
              itemBuilder: (context, index) {
                final item = widget.cards[index];
                final hasRepeatedMistakes = item.mistakeCount > 1;
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: _FlipCard(
                      question: item.question,
                      answer: item.answer,
                      showAnswer: _showAnswer && _currentIndex == index,
                      questionColor: hasRepeatedMistakes
                          ? (theme.brightness == Brightness.dark
                              ? AppColors.coralDark
                              : AppColors.coralSoft)
                          : theme.cardColor,
                      answerColor: AppColors.tealSoft,
                      repeatedMistakes: hasRepeatedMistakes,
                      repeatedCount: item.mistakeCount,
                      onFlip: () {
                        if (_currentIndex == index) {
                          setState(() => _showAnswer = !_showAnswer);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          _buildControls(theme),
        ],
      ),
    );
  }

  Widget _buildControls(ThemeData theme) {
    final card = widget.cards[_currentIndex];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _showAnswer
          ? Container(
              key: const ValueKey('feedback-buttons'),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Kaisa raha? (Confidence check)',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _AnkiButton(
                        label: 'Hard',
                        subLabel: 'Again',
                        color: AppColors.coralSoft,
                        onPressed: () => _handleFeedback('again'),
                      ),
                      _AnkiButton(
                        label: 'Good',
                        subLabel: card.repetitionCount == 0
                            ? '1d'
                            : '${(card.interval * card.easeFactor).round()}d',
                        color: AppColors.blueSoft,
                        onPressed: () => _handleFeedback('good'),
                      ),
                      _AnkiButton(
                        label: 'Easy',
                        subLabel: card.repetitionCount == 0
                            ? '4d'
                            : '${(card.interval * card.easeFactor * 1.3).round()}d',
                        color: AppColors.greenSoft,
                        onPressed: () => _handleFeedback('easy'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : Container(
              key: const ValueKey('reveal-button'),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() => _showAnswer = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                child: const Text(
                  'SHOW ANSWER',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1.5),
                ),
              ),
            ),
    );
  }
}

class _FlipCard extends StatelessWidget {
  const _FlipCard({
    required this.question,
    required this.answer,
    required this.showAnswer,
    required this.questionColor,
    required this.answerColor,
    required this.repeatedMistakes,
    required this.repeatedCount,
    required this.onFlip,
  });

  final String question;
  final String answer;
  final bool showAnswer;
  final Color questionColor;
  final Color answerColor;
  final bool repeatedMistakes;
  final int repeatedCount;
  final VoidCallback onFlip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onFlip,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: showAnswer ? 180 : 0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          final isBack = value > 90;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(value * (3.14159 / 180)),
            alignment: Alignment.center,
            child: isBack
                ? Transform(
                    transform: Matrix4.identity()..rotateY(3.14159),
                    alignment: Alignment.center,
                    child: _CardSide(
                      title: 'ANSWER',
                      content: answer,
                      color: answerColor,
                      theme: theme,
                    ),
                  )
                : _CardSide(
                    title: repeatedMistakes ? 'MISSED x$repeatedCount' : 'QUESTION',
                    content: question,
                    color: questionColor,
                    theme: theme,
                    showTapHint: !repeatedMistakes,
                  ),
          );
        },
      ),
    );
  }
}

class _CardSide extends StatelessWidget {
  const _CardSide({
    required this.title,
    required this.content,
    required this.color,
    required this.theme,
    this.showTapHint = false,
  });

  final String title;
  final String content;
  final Color color;
  final ThemeData theme;
  final bool showTapHint;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: color,
      child: Container(
        width: double.infinity,
        height: 350,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.muted,
                letterSpacing: 3,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            if (showTapHint) ...[
              const SizedBox(height: 20),
              const Icon(Icons.touch_app_outlined, color: AppColors.muted, size: 20),
              const SizedBox(height: 4),
              const Text('Tap to Flip', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnkiButton extends StatelessWidget {
  const _AnkiButton({
    required this.label,
    required this.subLabel,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final String subLabel;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: AppColors.text,
            padding: const EdgeInsets.symmetric(vertical: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: const BorderSide(color: AppColors.line),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subLabel, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class RotationYTransition extends AnimatedWidget {
  const RotationYTransition({
    super.key,
    required Animation<double> animation,
    this.child,
  }) : super(listenable: animation);

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final rotationValue = animation.value * 3.14159;
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(rotationValue),
      alignment: Alignment.center,
      child: rotationValue > 3.14159 / 2
          ? Transform(
              transform: Matrix4.identity()..rotateY(3.14159),
              alignment: Alignment.center,
              child: child,
            )
          : child,
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/app_models.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_card.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.controller,
    required this.test,
  });

  final AppController controller;
  final AppTest test;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with WidgetsBindingObserver {
  late final List<dynamic> _answers;
  late final List<bool> _showFeedback;
  late final TextEditingController _subjectiveController;
  late final PageController _pageController;
  late final List<AppQuestion> _shuffledQuestions;
  Timer? _timer;
  late int _secondsLeft;
  int _index = 0;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Anti-cheating: Shuffle questions
    _shuffledQuestions = List.from(widget.test.questions)..shuffle();

    _answers = List<dynamic>.filled(_shuffledQuestions.length, null);
    _showFeedback = List<bool>.filled(_shuffledQuestions.length, false);
    _subjectiveController = TextEditingController();
    _pageController = PageController();
    _secondsLeft = widget.test.timeLimitMin * 60;

    if (_shuffledQuestions.isNotEmpty) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _subjectiveController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_submitted) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App background me gaya ya split screen/notification press hua
      _submit(quitTest: true);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _submitted) {
        timer.cancel();
        return;
      }

      if (_secondsLeft <= 1) {
        timer.cancel();
        _submit(timedOut: true);
        return;
      }

      setState(() {
        _secondsLeft -= 1;
      });
    });
  }

  void _saveSubjectiveAnswer() {
    final question = _shuffledQuestions[_index];
    if (!question.isObjective) {
      _answers[_index] = _subjectiveController.text;
    }
  }

  void _loadSubjectiveAnswer(int questionIndex) {
    final question = _shuffledQuestions[questionIndex];
    if (!question.isObjective) {
      _subjectiveController.text = (_answers[questionIndex] as String?) ?? '';
    }
  }

  void _showModelAnswer(BuildContext context, AppQuestion question) {
    showModalBottomSheet(
      context: context,
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
            Text('Model Answer', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(question.correct, style: const TextStyle(fontSize: 16, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExplanation(BuildContext context, AppQuestion question) {
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
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Explanation',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                question.explanation.trim().isEmpty
                    ? 'Model answer right side me hai. Is question ke liye abhi extra explanation available nahi hai.'
                    : question.explanation,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.blueSoft.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Correct answer: ${question.correct}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit({bool timedOut = false, bool quitTest = false}) async {
    if (_submitted || _shuffledQuestions.isEmpty) {
      return;
    }

    _saveSubjectiveAnswer();
    _submitted = true;
    _timer?.cancel();

    if (quitTest) timedOut = true;

    final subjectiveAnswers = <int, String>{};
    final objectiveAnswers =
        List<int?>.filled(_shuffledQuestions.length, null);

    for (var i = 0; i < _shuffledQuestions.length; i++) {
      if (_shuffledQuestions[i].isObjective) {
        objectiveAnswers[i] = _answers[i] as int?;
      } else {
        subjectiveAnswers[i] = (_answers[i] as String?) ?? '';
      }
    }

    final completedTest = widget.test.copyWith(questions: _shuffledQuestions);

    var summary = widget.controller.recordResult(
      test: completedTest,
      answers: objectiveAnswers,
      timeSpentSec: (widget.test.timeLimitMin * 60) - _secondsLeft,
      timedOut: timedOut,
      subjectiveAnswers: subjectiveAnswers,
    );

    // autoritative Points logic from server
    if (widget.test.isDaily && !widget.controller.isGuestMode) {
      final cloudResult = await widget.controller.finalizeResult(
        test: widget.test,
        summary: summary,
      );
      if (cloudResult) {
        // If finalizeResult returns true, it was a successful first attempt
        // We can nominally update the summary object locally for the UI
        summary = ResultSummary(
          correct: summary.correct,
          total: summary.total,
          percent: summary.percent,
          timeSpentSec: summary.timeSpentSec,
          timedOut: summary.timedOut,
          weakTopics: summary.weakTopics,
          subjectiveAnswers: summary.subjectiveAnswers,
          questionReviews: summary.questionReviews,
          earnedExp: summary.earnedExp,
          dailyPoints: (summary.correct * 10) + 50,
        );
      }
    } else {
      await widget.controller.finalizeResult(
        test: widget.test,
        summary: summary,
      );
    }
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          controller: widget.controller,
          test: widget.test,
          summary: summary,
          statusMessage: widget.controller.message,
        ),
      ),
    );
  }

  @override
  Future<bool> didPopRoute() async {
    if (!_submitted) {
      // यदि परीक्षा चल रही है तो स्वतः सबमिट करें
      await _submit(quitTest: true);
      return true;
    }
    return false;
  }

  void _goToPreviousQuestion() {
    if (_index == 0) {
      return;
    }
    _saveSubjectiveAnswer();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToNextQuestion() {
    _saveSubjectiveAnswer();
    if (_index == widget.test.questions.length - 1) {
      _submit();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.test.questions.isEmpty) {
      return _EmptyQuizState(title: widget.test.title);
    }

return Scaffold(
      appBar: AppBar(
        title: Text(widget.test.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(
              child: Text(
                _formatSeconds(_secondsLeft),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: PopScope(
          canPop: _submitted,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            // Prevent back button exit during test
          },
          child: Column(
            children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: _buildHeader(theme),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) {
                  setState(() {
                    _index = idx;
                  });
                  _loadSubjectiveAnswer(idx);
                },
                itemCount: _shuffledQuestions.length,
                itemBuilder: (context, qIdx) {
                  final question = _shuffledQuestions[qIdx];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(question.question, style: theme.textTheme.titleLarge),
                              ),
                              _AiHintButton(
                                controller: widget.controller,
                                question: question.question,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (question.isObjective) ...[
                            ...List.generate(
                              question.options.length,
                              (optionIndex) {
                                final isSelected = _answers[qIdx] == optionIndex;
                                final isCorrect = question.answerIndex == optionIndex;
                                final showFeedback = _showFeedback[qIdx];

                                Color? bgColor;
                                if (showFeedback) {
                                  if (isCorrect) {
                                    bgColor = Colors.green.withValues(alpha: 0.2);
                                  } else if (isSelected) {
                                    bgColor = Colors.red.withValues(alpha: 0.2);
                                  }
                                } else if (isSelected) {
                                  bgColor = AppColors.accent.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.15);
                                }

                                Color? borderColor;
                                if (showFeedback) {
                                  if (isCorrect) {
                                    borderColor = Colors.green;
                                  } else if (isSelected) {
                                    borderColor = Colors.red;
                                  }
                                } else if (isSelected) {
                                  borderColor = AppColors.accent;
                                }

                                  return _ObjectiveOption(
                                  label: question.options[optionIndex],
                                  selected: isSelected,
                                  isDark: theme.brightness == Brightness.dark,
                                  customBgColor: bgColor,
                                  customBorderColor: borderColor,
                                  onTap: showFeedback ? null : () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      _answers[qIdx] = optionIndex;
                                      _showFeedback[qIdx] = true;
                                    });
                                    if (question.explanation.trim().isNotEmpty) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (mounted) {
                                          _showExplanation(context, question);
                                        }
                                      });
                                    }
                                  },
                                );
                              },
                            ),
                          ] else
                            Column(
                              children: [
                                TextField(
                                  controller: _subjectiveController,
                                  maxLines: 6,
                                  enableInteractiveSelection: false, // Copy-paste block
                                  decoration: InputDecoration(
                                    hintText: 'Write your answer here or upload a photo...',
                                    fillColor: theme.colorScheme.surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    suffixIcon: _AiVoiceButton(
                                      onResult: (text) {
                                        setState(() {
                                          _subjectiveController.text += ' $text';
                                          _answers[qIdx] = _subjectiveController.text;
                                        });
                                      },
                                    ),
                                  ),
                                  onChanged: (value) => _answers[qIdx] = value,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.visibility_outlined),
                                        label: const Text('Model Answer'),
                                        onPressed: () => _showModelAnswer(context, question),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: _buildFooter(),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final progress = ((_index + 1) / _shuffledQuestions.length).clamp(0.0, 1.0);
    return SoftCard(
      color: AppColors.yellowSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.test.subject} | ${widget.test.chapter}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: theme.cardColor,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
          const SizedBox(height: 10),
          Text(
            'Question ${_index + 1} of ${_shuffledQuestions.length}',
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _index == 0 ? null : _goToPreviousQuestion,
            child: const Text('Previous'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _goToNextQuestion,
            child: Text(
              _index == _shuffledQuestions.length - 1 ? 'Submit' : 'Next',
            ),
          ),
        ),
      ],
    );
  }

  String _formatSeconds(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remaining = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remaining';
  }
}

class _AiHintButton extends StatefulWidget {
  const _AiHintButton({
    required this.controller,
    required this.question,
  });

  final AppController controller;
  final String question;

  @override
  State<_AiHintButton> createState() => _AiHintButtonState();
}

class _AiHintButtonState extends State<_AiHintButton> {
  bool _loading = false;

  void _showHint() async {
    setState(() => _loading = true);
    try {
      final hint = await widget.controller.aiExplainQuestion(
        question: widget.question,
        answer: 'I am taking a test, give me a subtle hint without revealing the direct answer.',
      );
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.psychology, color: AppColors.accent),
              SizedBox(width: 8),
              Text('Sudarshan AI Hint'),
            ],
          ),
          content: Text(hint),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _loading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.lightbulb_outline, color: AppColors.muted),
      onPressed: _loading ? null : _showHint,
      tooltip: 'Get AI Hint',
    );
  }
}

class _AiVoiceButton extends StatefulWidget {
  const _AiVoiceButton({required this.onResult});
  final ValueChanged<String> onResult;

  @override
  State<_AiVoiceButton> createState() => _AiVoiceButtonState();
}

class _AiVoiceButtonState extends State<_AiVoiceButton> {
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            if (val.finalResult) {
              widget.onResult(val.recognizedWords);
              setState(() => _isListening = false);
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_isListening ? Icons.mic : Icons.mic_none,
        color: _isListening ? Colors.red : AppColors.muted),
      onPressed: _listen,
    );
  }
}

class _ObjectiveOption extends StatelessWidget {
  const _ObjectiveOption({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
    this.customBgColor,
    this.customBorderColor,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback? onTap;
  final Color? customBgColor;
  final Color? customBorderColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: customBgColor ?? (selected
                ? AppColors.accent.withValues(alpha: isDark ? 0.3 : 0.15)
                : Theme.of(context).colorScheme.surface),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: customBorderColor ?? (selected ? AppColors.accent : Theme.of(context).dividerColor),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: customBorderColor ?? (selected ? AppColors.accent : Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyQuizState extends StatelessWidget {
  const _EmptyQuizState({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SoftCard(
              color: AppColors.coralSoft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Test unavailable', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Text(
                    'Is test me questions nahi mile. Firestore data ya sync ko check karna hoga.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

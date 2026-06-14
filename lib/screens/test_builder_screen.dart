import 'dart:math';

import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_card.dart';
import '../state/app_controller.dart';

class TestBuilderScreen extends StatefulWidget {
  const TestBuilderScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<TestBuilderScreen> createState() => _TestBuilderScreenState();
}

class _TestBuilderScreenState extends State<TestBuilderScreen> {
  static const _subjects = [
    'Science',
    'Math',
    'SST',
    'Hindi',
    'English',
    'Sanskrit',
    'General',
  ];
  static const _levels = ['Level 1', 'Level 2', 'Level 3'];

  String _selectedSubject = 'Science';
  String _selectedLevel = 'Level 1';
  final _title = TextEditingController();
  final _subject = TextEditingController();
  final _chapter = TextEditingController();
  final _timeLimit = TextEditingController(text: '10');
  final List<_QuestionDraft> _questions = [];

  @override
  void dispose() {
    _title.dispose();
    _subject.dispose();
    _chapter.dispose();
    _timeLimit.dispose();
    for (final question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_QuestionDraft());
    });
  }

  Future<void> _save() async {
    final builtQuestions = <AppQuestion>[];
    for (final draft in _questions) {
      final options = draft.options
          .map((item) => item.text.trim())
          .where((item) => item.isNotEmpty)
          .toList();
      if (draft.question.text.trim().isEmpty || options.length < 2) {
        continue;
      }
      final selectedIndex =
          min(draft.correctIndex, max(0, options.length - 1));
      builtQuestions.add(
        AppQuestion(
          question: draft.question.text.trim(),
          options: options,
          correct: options[selectedIndex],
          topic: draft.topic.text.trim().isEmpty
              ? 'general'
              : draft.topic.text.trim(),
          questionType: 'MCQ',
          explanation: draft.explanation.text.trim(),
        ),
      );
    }
    if (_title.text.trim().isEmpty || builtQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Test name aur kam se kam ek valid question chahiye.')),
      );
      return;
    }
    final test = AppTest(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: _title.text.trim(),
      subject: _selectedSubject == 'General'
          ? (_subject.text.trim().isEmpty ? 'General' : _subject.text.trim())
          : _selectedSubject,
      chapter: _chapter.text.trim(),
      level: _selectedLevel,
      timeLimitMin: int.tryParse(_timeLimit.text.trim()) ?? 10,
      questions: builtQuestions,
    );
    await widget.controller.addCustomTest(test);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('New Test')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addQuestion,
        icon: const Icon(Icons.add),
        label: const Text('Add Question'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const SoftCard(
              color: AppColors.yellowSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Build Local Test',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text)),
                  SizedBox(height: 8),
                  Text(
                    'Ye test device par locally save hoga. Offline practice ke liye perfect hai.',
                    style: TextStyle(color: AppColors.muted, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SoftCard(
              color: AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Test Setup', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Manual test selection aur question bank dono local rehenge. Iska use tum offline revision ya self-practice ke liye kar sakte ho.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _title,
                    decoration: const InputDecoration(
                      labelText: 'Test Name',
                      hintText: 'Jaise: Acid Base Sprint',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSubject,
                    decoration: const InputDecoration(labelText: 'Subject'),
                    items: _subjects
                        .map((item) =>
                            DropdownMenuItem(value: item, child: Text(item)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedSubject = value ?? 'Science'),
                  ),
                  if (_selectedSubject == 'General') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _subject,
                      decoration:
                          const InputDecoration(labelText: 'Custom Subject'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _chapter,
                    decoration: const InputDecoration(
                      labelText: 'Chapter / Topic Set',
                      hintText: 'Jaise: Acids and Bases revision',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedLevel,
                          decoration: const InputDecoration(labelText: 'Level'),
                          items: _levels
                              .map((item) => DropdownMenuItem(
                                  value: item, child: Text(item)))
                              .toList(),
                          onChanged: (value) => setState(
                              () => _selectedLevel = value ?? 'Level 1'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _timeLimit,
                          decoration: const InputDecoration(
                            labelText: 'Time (min)',
                            helperText: '0 = no limit',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_questions.isEmpty)
              const SoftCard(
                color: AppColors.white,
                child: Text(
                  'Add Question dabao aur apna local practice set banana start karo.',
                  style: TextStyle(color: AppColors.muted, height: 1.35),
                ),
              ),
            ..._questions.asMap().entries.map((entry) {
              final index = entry.key;
              final draft = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SoftCard(
                  color: index.isEven ? AppColors.white : AppColors.blueSoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Question ${index + 1}',
                                style: theme.textTheme.titleMedium),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                final removed = _questions.removeAt(index);
                                removed.dispose();
                              });
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remove'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: draft.question,
                        decoration: const InputDecoration(
                          labelText: 'Question',
                          hintText: 'Question text yahan likho',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: draft.topic,
                        decoration: const InputDecoration(
                          labelText: 'Topic',
                          hintText: 'Jaise: Acids and Bases',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Options',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      for (var optionIndex = 0;
                          optionIndex < draft.options.length;
                          optionIndex++) ...[
                        TextField(
                          controller: draft.options[optionIndex],
                          decoration: InputDecoration(
                            labelText: 'Option ${optionIndex + 1}',
                            hintText: 'Choice ${optionIndex + 1}',
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      DropdownButtonFormField<int>(
                        initialValue: draft.correctIndex,
                        decoration: const InputDecoration(
                          labelText: 'Correct Answer',
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 0, child: Text('Option 1')),
                          DropdownMenuItem(
                              value: 1, child: Text('Option 2')),
                          DropdownMenuItem(
                              value: 2, child: Text('Option 3')),
                          DropdownMenuItem(
                              value: 3, child: Text('Option 4')),
                        ],
                        onChanged: (value) =>
                            setState(() => draft.correctIndex = value ?? 0),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: draft.explanation,
                        decoration: const InputDecoration(
                          labelText: 'Explanation',
                          hintText: 'Optional: chhota explanation add karo',
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save Test'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionDraft {
  _QuestionDraft()
      : question = TextEditingController(),
        topic = TextEditingController(),
        explanation = TextEditingController(),
        options = List.generate(4, (_) => TextEditingController());

  final TextEditingController question;
  final TextEditingController topic;
  final TextEditingController explanation;
  final List<TextEditingController> options;
  int correctIndex = 0;

  void dispose() {
    question.dispose();
    topic.dispose();
    explanation.dispose();
    for (final option in options) {
      option.dispose();
    }
  }
}

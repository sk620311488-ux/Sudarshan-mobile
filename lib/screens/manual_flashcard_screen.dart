import 'package:flutter/material.dart';

import '../config/subject_constants.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_card.dart';

class ManualFlashcardScreen extends StatefulWidget {
  const ManualFlashcardScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ManualFlashcardScreen> createState() => _ManualFlashcardScreenState();
}

class _ManualFlashcardScreenState extends State<ManualFlashcardScreen> {
  String _selectedSubject = SubjectConstants.subjects.first;
  final _subject = TextEditingController();
  final _chapter = TextEditingController();
  final _topic = TextEditingController();
  final _question = TextEditingController();
  final _answer = TextEditingController();

  @override
  void dispose() {
    _subject.dispose();
    _chapter.dispose();
    _topic.dispose();
    _question.dispose();
    _answer.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_question.text.trim().isEmpty || _answer.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Question aur answer dono bharna zaroori hai.')),
      );
      return;
    }
    await widget.controller.addManualFlashcard(
      subject: _selectedSubject,
      chapter: _chapter.text,
      topic: _topic.text,
      question: _question.text,
      answer: _answer.text,
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Flashcard')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const SoftCard(
              color: AppColors.tealSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Add Card',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text)),
                  SizedBox(height: 8),
                  Text(
                    'Ye card notebook me hamesha rahega aur due hone par home reminder me bhi aa jayega.',
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
                  Text('Card Setup', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Ye flashcard notebook me permanently rahega. Due hone par home screen par bhi reminder aa jayega.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSubject,
                    decoration: const InputDecoration(labelText: 'Subject'),
                    items: SubjectConstants.subjects
                        .map((item) =>
                            DropdownMenuItem(value: item, child: Text(item)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedSubject = value ?? SubjectConstants.subjects.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _chapter,
                    decoration: const InputDecoration(
                      labelText: 'Chapter / Section',
                      hintText: 'Jaise: Chapter 4 - Acids',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _topic,
                    decoration: const InputDecoration(
                      labelText: 'Topic',
                      hintText: 'Jaise: Indicators',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SoftCard(
              color: AppColors.blueSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Question + Answer', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _question,
                    decoration: const InputDecoration(
                      labelText: 'Question',
                      hintText: 'Jaise: pH 7 kis solution ko dikhata hai?',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _answer,
                    decoration: const InputDecoration(
                      labelText: 'Answer',
                      hintText: 'Short, clear answer likho',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save Flashcard'),
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

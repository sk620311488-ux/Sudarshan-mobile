import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';
import 'dart:io' show File;

import '../models/app_models.dart';
import '../services/anki_export_service.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/analytics_widget.dart';
import '../widgets/soft_card.dart';
import 'auth_gate.dart';
import 'flashcard_study_screen.dart';
import 'friends_hub_screen.dart';
import 'history_screen.dart';
import 'leaderboard_screen.dart';
import 'manual_flashcard_screen.dart';
import 'quiz_screen.dart';
import '../config/subject_constants.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _openTest(AppTest test) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(controller: widget.controller, test: test),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppTest? dailyTest;
    for (final test in widget.controller.tests) {
      if (test.isDaily) {
        dailyTest = test;
        break;
      }
    }
    final pages = [
      DashboardPage(
        controller: widget.controller,
        onOpenTests: () => setState(() => _index = 1),
        onOpenProfile: () => setState(() => _index = 3),
        onOpenAnalytics: () => setState(() => _index = 3),
        onOpenLeaderboard: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LeaderboardScreen(
                currentUid: widget.controller.session?.uid ?? '',
              ),
            ),
          );
        },
        onStartDaily: dailyTest == null
            ? null
            : () {
                _openTest(dailyTest!);
              },
      ),
      TestsPage(controller: widget.controller),
      NotebookPage(controller: widget.controller),
      ProfilePage(controller: widget.controller),
    ];

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final profile = widget.controller.publicProfile;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Sudarshan Mobile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_alt_1_outlined),
                onPressed: () {
                  if (profile == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Profile load nahi hui. Check connection.')),
                    );
                    return;
                  }
                  SharePlus.instance.share(
                    ShareParams(
                      text: 'Join my Sudarshan friends circle.\n'
                          'Search my custom ID: ${profile.customStudentId}\n'
                          'Student: ${profile.displayName}',
                    ),
                  );
                },
                tooltip: 'Invite Friend',
              ),
            ],
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: pages[_index],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home'),
              NavigationDestination(
                  icon: Icon(Icons.quiz_outlined),
                  selectedIcon: Icon(Icons.quiz),
                  label: 'Tests'),
              NavigationDestination(
                  icon: Icon(Icons.auto_stories_outlined),
                  selectedIcon: Icon(Icons.auto_stories),
                  label: 'Notebook'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.controller,
    required this.onOpenTests,
    required this.onOpenProfile,
    required this.onOpenLeaderboard,
    required this.onOpenAnalytics,
    this.onStartDaily,
  });

  final AppController controller;
  final VoidCallback onOpenTests;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenLeaderboard;
  final VoidCallback onOpenAnalytics;
  final VoidCallback? onStartDaily;

  void _showAiAnalysis(BuildContext context, AppController controller) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final analysis = await controller.aiAnalyzePerformance();
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
                  Text('Sudarshan AI Analysis', style: Theme.of(context).textTheme.titleLarge),
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

  void _showAiSubjectiveChecker(BuildContext context, AppController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AiSubjectiveCheckerSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = controller.session;
    final tests = controller.tests;
    final daily = tests.where((item) => item.isDaily).toList();
    final dueCards = controller.dueCards;
    final hasDaily = daily.isNotEmpty;
    final isGuest = controller.isGuestMode;
    final streak = controller.dailyStreak;

    return ListView(
      key: const ValueKey('dashboard'),
      padding: const EdgeInsets.all(18),
      children: [
        SoftCard(
          color: AppColors.blueSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Today', style: theme.textTheme.headlineMedium),
                  if (streak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department,
                              color: Colors.orange),
                          const SizedBox(width: 4),
                          Text('$streak Day Streak',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${session?.name.isNotEmpty == true ? session!.name : 'Student'}  |  ${(session?.mode ?? 'guest').toUpperCase()}',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton(
                    onPressed: hasDaily ? onStartDaily : onOpenTests,
                    child: Text(hasDaily ? 'Start Daily Now' : 'Open Tests'),
                  ),
                  OutlinedButton(
                    onPressed: onOpenLeaderboard,
                    child: const Text('Leaderboard'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              FriendsHubScreen(controller: controller),
                        ),
                      );
                    },
                    icon: const Icon(Icons.group_add, size: 18),
                    label: const Text('Friends'),
                  ),
                  ElevatedButton.icon(
                    onPressed: onOpenAnalytics,
                    icon: const Icon(Icons.psychology, size: 18),
                    label: const Text('AI Analysis'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tealSoft,
                      foregroundColor: AppColors.text,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _DailyMissionsCard(controller: controller),
        const SizedBox(height: 18),
        SubjectMasteryCard(mastery: controller.subjectMastery),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: WeeklyActivityCard(activity: controller.weeklyActivity)),
          ],
        ),
        const SizedBox(height: 12),
        WeakTopicsCard(topics: controller.topWeakTopics),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                title: 'Daily Test',
                value: hasDaily ? 'Ready' : 'Not found',
                color: AppColors.yellowSoft,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                title: 'Streak',
                value: streak > 0 ? '$streak Days' : 'Start Today',
                color: AppColors.greenSoft,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                title: 'Weak Topic',
                value:
                    dueCards.isNotEmpty ? dueCards.first.topic : 'No due card',
                color: AppColors.coralSoft,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                title: 'Memory Cards',
                value: '${controller.notebookCards.length} total',
                color: AppColors.tealSoft,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SoftCard(
          color: AppColors.tealSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sudarshan AI Subjective Checker', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Apne answer ko check karwao: Type karo, Bolo (Voice), ya Photo upload karo.'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.psychology),
                onPressed: () => _showAiSubjectiveChecker(context, controller),
                label: const Text('Start AI Checking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Activity', style: theme.textTheme.titleLarge),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => HistoryScreen(controller: controller)),
                );
              },
              child: const Text('View History'),
            ),
          ],
        ),
        if (controller.attempts.isEmpty)
          const SoftCard(
              child: Text('No tests taken yet. Start your first one!'))
        else
          ...controller.attempts.reversed.take(3).map((attempt) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  tileColor: theme.cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  leading: CircleAvatar(
                    backgroundColor: attempt.isDaily
                        ? AppColors.yellowSoft
                        : AppColors.blueSoft,
                    child: Icon(attempt.isDaily ? Icons.star : Icons.quiz,
                        size: 20),
                  ),
                  title: Text(attempt.testTitle,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                      '${attempt.score}/${attempt.total} | ${attempt.percent}%'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              HistoryScreen(controller: controller)),
                    );
                  },
                ),
              )),
        const SizedBox(height: 18),
        if (controller.last10WrongQuestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: SoftCard(
              color: AppColors.coralSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Fix', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Pichle tests me jo questions galat hue thay, unka ek quick 10-question sprint try karo.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      final wrongOnes = controller.last10WrongQuestions;
                      final retryTest = controller.createRetryTest(wrongOnes);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            controller: controller,
                            test: retryTest,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry Last 10 Wrong'),
                  ),
                ],
              ),
            ),
          ),
        if (isGuest) ...[
          const SizedBox(height: 18),
          SoftCard(
            color: AppColors.coralSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Save Progress Permanently',
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'Upgrade to an account to sync your daily streaks and memory cards across devices.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AuthGateScreen(
                          controller: controller,
                          upgradeMode: true,
                        ),
                      ),
                    );
                  },
                  child: const Text('Create Account'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class TestsPage extends StatefulWidget {
  const TestsPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<TestsPage> createState() => _TestsPageState();
}

class _TestsPageState extends State<TestsPage> {
  String _searchQuery = '';
  String? _selectedSubject;
  String? _selectedSubSubject;
  String? _selectedChapter;

  void _onBack() {
    setState(() {
      if (_selectedChapter != null) {
        _selectedChapter = null;
      } else if (_selectedSubSubject != null) {
        _selectedSubSubject = null;
      } else if (_selectedSubject != null) {
        _selectedSubject = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allTests = widget.controller.tests;

    // Search Mode
    if (_searchQuery.isNotEmpty) {
      final searchFilteredTests = allTests.where((test) {
        final matchesSearch =
            test.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                test.chapter.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                test.subject.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesSearch;
      }).toList();
      return _buildSearchList(searchFilteredTests, theme);
    }

    // Chapter View (Tests inside a chapter)
    if (_selectedChapter != null) {
      final chapterTests = allTests.where((test) {
        if (_selectedSubSubject == 'Daily Test') {
          return test.isDaily && test.subject == _selectedSubject;
        }
        
        // Exact matching for Bihar Board Chapters
        // We check if the test's chapter name is exactly same or contained in our list
        final testChapter = test.chapter.trim();
        final selectedChapter = _selectedChapter!.trim();
        
        return test.subject == _selectedSubject && 
               (testChapter == selectedChapter || 
                testChapter.contains(selectedChapter) || 
                selectedChapter.contains(testChapter));
      }).toList();
      return _buildTestsInsideChapter(chapterTests, theme);
    }

    // Sub-subject/Book/Daily Folder View
    if (_selectedSubSubject != null) {
      if (_selectedSubSubject == 'Daily Test') {
        return _buildDailyTestDatesView(allTests, theme);
      }
      return _buildChaptersView(theme);
    }

    // Main Subject View
    if (_selectedSubject != null) {
      return _buildSubSubjectsView(theme);
    }

    // Root Subject List
    return _buildRootSubjects(theme);
  }

  Widget _buildRootSubjects(ThemeData theme) {
    final subjects = SubjectConstants.subjects;
    return Column(
      children: [
        _buildSearchBar(theme),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text('Select Subject', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              ...subjects.map((sub) => _FolderTile(
                    title: sub,
                    icon: Icons.folder,
                    color: AppColors.blue,
                    onTap: () => setState(() => _selectedSubject = sub),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubSubjectsView(ThemeData theme) {
    final subs = SubjectConstants.subSubjects[_selectedSubject] ?? [];
    return Column(
      children: [
        _buildHeader(_selectedSubject!),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              ...subs.map((sub) => _FolderTile(
                    title: sub,
                    icon: sub == 'Daily Test' ? Icons.today : Icons.folder_shared,
                    color: sub == 'Daily Test' ? AppColors.yellow : AppColors.teal,
                    onTap: () => setState(() => _selectedSubSubject = sub),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyTestDatesView(List<AppTest> tests, ThemeData theme) {
    final dailyTests = tests.where((t) => t.isDaily && t.subject == _selectedSubject).toList();
    // Sort by date (usually ID is YYYY-MM-DD)
    dailyTests.sort((a, b) => b.id.compareTo(a.id));

    return Column(
      children: [
        _buildHeader('Daily Tests: $_selectedSubject'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: dailyTests.isEmpty 
              ? [const Center(child: Text('No daily tests found.'))]
              : dailyTests.map((test) => ListTile(
                leading: const Icon(Icons.event, color: AppColors.yellow),
                title: Text(test.title),
                subtitle: Text('Date: ${test.id}'),
                trailing: const Icon(Icons.play_arrow),
                onTap: () => _openTest(test),
              )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildChaptersView(ThemeData theme) {
    final chapters = SubjectConstants.chapters[_selectedSubSubject] ?? [];
    return Column(
      children: [
        _buildHeader(_selectedSubSubject!),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              ...chapters.map((ch) => ListTile(
                    leading: const Icon(Icons.book, color: AppColors.teal),
                    title: Text(ch),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => setState(() => _selectedChapter = ch),
                  )),
              // Add a "Others" for tests that don't match known chapters
              ListTile(
                leading: const Icon(Icons.more_horiz),
                title: const Text('Miscellaneous'),
                onTap: () => setState(() => _selectedChapter = 'Misc'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestsInsideChapter(List<AppTest> tests, ThemeData theme) {
    return Column(
      children: [
        _buildHeader(_selectedChapter!),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: tests.isEmpty
                ? [const Center(child: Text('Is chapter mein abhi koi test nahi hai.'))]
                : tests.map((test) => _TestTile(test: test, onTap: () => _openTest(test))).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchList(List<AppTest> tests, ThemeData theme) {
    return Column(
      children: [
        _buildSearchBar(theme),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: tests.map((test) => _TestTile(test: test, onTap: () => _openTest(test))).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 18, 18, 0),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: _onBack),
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search tests...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: theme.cardColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  void _openTest(AppTest test) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuizScreen(controller: widget.controller, test: test)));
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({required this.title, required this.icon, required this.color, required this.onTap});
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _TestTile extends StatelessWidget {
  const _TestTile({required this.test, required this.onTap});
  final AppTest test;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(test.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('${test.questionCount} Qs | ${test.timeLimitMin} min'),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onTap, child: const Text('Start Test'))),
          ],
        ),
      ),
    );
  }
}

class NotebookPage extends StatefulWidget {
  const NotebookPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<NotebookPage> createState() => _NotebookPageState();
}

class _NotebookPageState extends State<NotebookPage> {
  final AnkiExportService _ankiExportService = AnkiExportService();
  String _selectedSubject = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allCards = widget.controller.notebookCards;

    // Extract subjects for filtering
    final subjects = ['All', ...allCards.map((e) => e.subject).toSet()];

    // Apply filtering
    final filteredCards = allCards.where((card) {
      final matchesSubject =
          _selectedSubject == 'All' || card.subject == _selectedSubject;
      final matchesSearch =
          card.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              card.answer.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              card.chapter.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSubject && matchesSearch;
    }).toList();

    // Filtered due cards for the "Study" button
    final filteredDueCards = filteredCards.where((c) => c.isDue).toList();

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search cards, chapters...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Subject Filters
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final sub = subjects[index];
              final isSelected = _selectedSubject == sub;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(sub),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _selectedSubject = sub),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: ListView(
            key: const ValueKey('notebook'),
            padding: const EdgeInsets.all(18),
            children: [
              SoftCard(
                color: AppColors.tealSoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Anki Brain', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    const Text(
                      'Scientific revision based on Spaced Repetition. Study your due cards daily to never forget.',
                      style: TextStyle(color: AppColors.muted, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (filteredCards.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FlashcardStudyScreen(
                              controller: widget.controller,
                              cards: filteredDueCards.isEmpty
                                  ? filteredCards
                                  : filteredDueCards,
                            ),
                          ),
                        );
                      },
                      label: Text(filteredDueCards.isNotEmpty
                          ? 'Study Due ${_selectedSubject == 'All' ? '' : _selectedSubject} (${filteredDueCards.length})'
                          : 'Study All ${_selectedSubject == 'All' ? '' : _selectedSubject}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blueSoft,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => ManualFlashcardScreen(
                                  controller: widget.controller))),
                      child: const Text('Add Card'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: filteredCards.isEmpty
                          ? null
                          : () async {
                              final export = await _ankiExportService
                                  .exportCards(filteredCards);
                              await Clipboard.setData(
                                  ClipboardData(text: export.tsv));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Anki Exported to Clipboard!')),
                                );
                              }
                            },
                      child: const Text('Export TSV'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: allCards.isEmpty
                      ? null
                      : () => widget.controller.exportNotebookAsPdf(),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Download Notebook PDF'),
                ),
              ),
              const SizedBox(height: 18),
              if (filteredCards.isEmpty)
                Center(
                    child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    children: [
                      Text((_selectedSubject == 'All' && _searchQuery.isEmpty)
                          ? 'No flashcards yet. Start taking tests!'
                          : 'No cards found matching your criteria.'),
                      if (_selectedSubject != 'All' || _searchQuery.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(() {
                            _selectedSubject = 'All';
                            _searchQuery = '';
                          }),
                          child: const Text('Clear Filters'),
                        ),
                    ],
                  ),
                )),
              ...filteredCards.asMap().entries.map((entry) => _NotebookCardItem(
                    key: ValueKey('${entry.value.question}_${entry.key}'),
                    card: entry.value,
                    controller: widget.controller,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotebookCardItem extends StatelessWidget {
  const _NotebookCardItem({
    super.key,
    required this.card,
    required this.controller,
  });
  final NotebookCard card;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine Mastery Tag
    String masteryLabel = 'New';
    Color masteryColor = AppColors.tealSoft;
    if (card.repetitionCount > 0) {
      if (card.interval >= 7) {
        masteryLabel = 'Mastered';
        masteryColor = AppColors.greenSoft;
      } else {
        masteryLabel = 'Learning';
        masteryColor = AppColors.yellowSoft;
      }
    }
    final hasRepeatedMistakes = card.mistakeCount > 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FlashcardStudyScreen(
                controller: controller,
                cards: [card],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: SoftCard(
          color: hasRepeatedMistakes
              ? (theme.brightness == Brightness.dark
                  ? AppColors.coralDark
                  : AppColors.coralSoft)
              : card.isDue
                  ? (theme.brightness == Brightness.dark
                      ? AppColors.yellowDark
                      : AppColors.yellowSoft)
                  : (theme.brightness == Brightness.dark
                      ? theme.cardColor
                      : AppColors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _MiniTag(label: card.subject, color: AppColors.blueSoft),
                      const SizedBox(width: 6),
                      _MiniTag(label: masteryLabel, color: masteryColor),
                      if (hasRepeatedMistakes) ...[
                        const SizedBox(width: 6),
                        _MiniTag(
                            label: 'Missed x${card.mistakeCount}',
                            color: AppColors.coralSoft),
                      ],
                    ],
                  ),
                  if (card.isDue)
                    const _MiniTag(label: 'DUE NOW', color: Colors.orange),
                ],
              ),
              const SizedBox(height: 12),
              Text(card.question, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.event_repeat,
                      size: 14, color: AppColors.muted),
                  const SizedBox(width: 4),
                  Text('Next: ${card.scheduleLabel}',
                      style: theme.textTheme.bodySmall),
                  const Spacer(),
                  _AiDoubtSolverButton(
                    controller: controller,
                    question: card.question,
                    answer: card.answer,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => controller.deleteNotebookCard(card),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ProfilePage — the 4th tab of HomeShell
// ---------------------------------------------------------------------------

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.controller});
  final AppController controller;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AppController get c => widget.controller;

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
                  const Text('Sovereign AI Deep Explanation',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(explanation,
                      style: const TextStyle(fontSize: 16, height: 1.5)),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('AI Error: $e')));
      }
    }
  }

  void _showEditIdDialog() {
    final ctrl = TextEditingController(text: c.session?.customStudentId ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Student ID Set Karo'),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Student ID (max 12 chars)',
            border: OutlineInputBorder(),
          ),
          maxLength: 12,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await c.updateStudentId(ctrl.text.trim().toUpperCase());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Student ID updated!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = c.session;

    if (session == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_outlined, size: 64, color: AppColors.muted),
            const SizedBox(height: 16),
            const Text('Koi account nahi mila.', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AuthGateScreen(controller: c)),
              ),
              child: const Text('Sign In'),
            ),
          ],
        ),
      );
    }

    final level = c.userLevel;
    final progress = c.levelProgress;
    final nextExp = c.nextLevelExp;
    final achievements = c.achievements;
    final mastery = c.subjectMastery;
    final activity = c.weeklyActivity;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // ── Avatar + Name ──────────────────────────────────────
        SoftCard(
          color: AppColors.blueSoft,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40), // spacer
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.accent,
                    child: Text(
                      _initials(session.name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(c.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                    onPressed: () => c.toggleTheme(),
                    tooltip: 'Toggle Theme',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                session.name.trim().isEmpty ? 'Student' : session.name,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ID: ${session.studentId}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (!session.isGuest) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _showEditIdDialog,
                      child: const Icon(Icons.edit_outlined,
                          size: 16, color: AppColors.accent),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(c.rankTitle, style: theme.textTheme.titleMedium),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Stats row ──────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _ProfileStat(
                label: 'Level',
                value: '$level',
              ),
            ),
            Expanded(
              child: _ProfileStat(
                label: 'Total EXP',
                value: '${c.totalExp}',
              ),
            ),
            Expanded(
              child: _ProfileStat(
                label: 'Streak',
                value: '${c.dailyStreak}',
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Level progress bar ─────────────────────────────────
        SoftCard(
          color: AppColors.greenSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Level $level Progress',
                      style: theme.textTheme.titleMedium),
                  Text('${c.totalExp} / $nextExp EXP',
                      style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Colors.white,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.accent),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Analytics Section ──────────────────────────────────
        Text('Performance Analytics', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        WeeklyActivityCard(activity: activity),
        const SizedBox(height: 16),
        Text('Subject Mastery', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        _SubjectPieSimulator(
          mastery: mastery,
          onSubjectTap: (sub) => setState(() {
            _selectedSubject = sub;
            _selectedChapter = null;
          }),
        ),

        if (_selectedSubject != null) ...[
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_selectedSubject Analysis',
                  style: theme.textTheme.titleLarge),
              IconButton(
                  onPressed: () => setState(() => _selectedSubject = null),
                  icon: const Icon(Icons.close)),
            ],
          ),
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

        const SizedBox(height: 24),

        // ── Achievements ───────────────────────────────────────
        Text('Achievements', style: theme.textTheme.titleLarge),
        const SizedBox(height: 10),
        if (achievements.isEmpty)
          const SoftCard(
            child: Text('Abhi tak koi achievement nahi. Tests solve karte raho!'),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: achievements
                .map(
                  (a) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Text(a,
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
                .toList(),
          ),

        const SizedBox(height: 24),

        // ── Sign-out ───────────────────────────────────────────
        if (!session.isGuest)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Sign Out',
                  style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out?'),
                    content: const Text(
                        'Aap sign out karna chahte hain?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Sign Out',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && mounted) {
                  await c.signOut();
                }
              },
            ),
          ),

        const SizedBox(height: 32),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'S';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

// ---------------------------------------------------------------------------

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: AppColors.muted)),
      ],
    );
  }
}

class _AiDoubtSolverButton extends StatefulWidget {
  const _AiDoubtSolverButton({
    required this.controller,
    required this.question,
    required this.answer,
  });

  final AppController controller;
  final String question;
  final String answer;

  @override
  State<_AiDoubtSolverButton> createState() => _AiDoubtSolverButtonState();
}

class _AiDoubtSolverButtonState extends State<_AiDoubtSolverButton> {
  bool _loading = false;

  void _showExplanation() async {
    setState(() => _loading = true);
    try {
      final explanation = await widget.controller.aiExplainQuestion(
        question: widget.question,
        answer: widget.answer,
      );
      if (!mounted) return;

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
              Row(
                children: [
                  const Icon(Icons.psychology, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text('Sudarshan AI Explain',
                      style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 16),
              Text(explanation,
                  style: const TextStyle(fontSize: 15, height: 1.5)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it!'),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('AI Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.psychology_outlined, size: 22),
      onPressed: _loading ? null : _showExplanation,
      tooltip: 'Explain this',
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}

class _SubjectPieSimulator extends StatelessWidget {
  const _SubjectPieSimulator(
      {required this.mastery, required this.onSubjectTap});
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
                Text('${e.value.round()}% Mastery',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
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
  const _ChapterErrorAnalysis(
      {required this.controller,
      required this.subject,
      required this.onChapterTap});
  final AppController controller;
  final String subject;
  final Function(String) onChapterTap;

  @override
  Widget build(BuildContext context) {
    final attempts =
        controller.attempts.where((a) => a.subject == subject).toList();
    final chapterErrors = <String, int>{};
    for (final a in attempts) {
      final errors = a.total - a.score;
      if (errors > 0) {
        chapterErrors[a.chapter] = (chapterErrors[a.chapter] ?? 0) + errors;
      }
    }

    if (chapterErrors.isEmpty) {
      return const SoftCard(
          child: Text('Is subject mein koi galtiyan nahi mili! Great job.'));
    }

    return Column(
      children: chapterErrors.entries
          .map<Widget>((e) => ListTile(
                title: Text(e.key),
                subtitle: Text('${e.value} galtiyan'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onChapterTap(e.key),
              ))
          .toList(),
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
    final cards = controller.notebookCards
        .where((c) => c.subject == subject && c.chapter == chapter)
        .toList();
    final topicMistakes = <String, int>{};
    for (final c in cards) {
      if (c.mistakeCount > 0) {
        topicMistakes[c.topic] = (topicMistakes[c.topic] ?? 0) + c.mistakeCount;
      }
    }

    if (topicMistakes.isEmpty) {
      return const SoftCard(
          child: Text(
              'Is chapter ke topics mein koi recorded galtiyan nahi hain.'));
    }

    return Column(
      children: topicMistakes.entries
          .map<Widget>((e) => SoftCard(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.key,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${e.value} mistakes tracked'),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => onDeepExplain(e.key),
                      icon: const Icon(Icons.psychology, size: 16),
                      label: const Text('AI Deep explain'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        backgroundColor: AppColors.tealSoft,
                        foregroundColor: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _DailyMissionsCard extends StatelessWidget {
  const _DailyMissionsCard({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final missions = controller.missions;
    if (missions.isEmpty) return const SizedBox.shrink();

    return SoftCard(
      color: AppColors.yellowSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Missions',
                  style: Theme.of(context).textTheme.titleLarge),
              const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          ...missions.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(m.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: m.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: m.isCompleted ? AppColors.muted : null,
                            )),
                        Text('${m.progress}/${m.goal}',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: m.progress / m.goal,
                        backgroundColor: Colors.white,
                        color: m.isCompleted ? AppColors.green : Colors.orange,
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

class _AiSubjectiveCheckerSheet extends StatefulWidget {
  const _AiSubjectiveCheckerSheet({required this.controller});
  final AppController controller;

  @override
  State<_AiSubjectiveCheckerSheet> createState() => _AiSubjectiveCheckerSheetState();
}

class _AiSubjectiveCheckerSheetState extends State<_AiSubjectiveCheckerSheet> {
  final _modelController = TextEditingController();
  final _answerController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ImagePicker _picker = ImagePicker();
  
  bool _isListening = false;
  File? _image;
  bool _loading = false;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _modelController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _answerController.text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _answerController.text = "[Photo Uploaded]";
      });
    }
  }

  Future<void> _evaluate() async {
    if (_modelController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pehle Model Answer ya Keywords dalo.')),
      );
      return;
    }
    if (_answerController.text.isEmpty && _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apna answer likho, bolo ya photo upload karo.')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _result = null;
    });

    try {
      String? base64Image;
      if (_image != null) {
        final bytes = await _image!.readAsBytes();
        base64Image = base64Encode(bytes);
      }

      final res = await widget.controller.aiEvaluateSubjective(
        question: "Manual AI Check",
        modelAnswer: _modelController.text,
        studentAnswer: _answerController.text,
        imageBase64: base64Image,
      );

      setState(() {
        _result = res;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Evaluation Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.only(
        top: 24, left: 24, right: 24, 
        bottom: MediaQuery.of(context).viewInsets.bottom + 24
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('AI Answer Checker', style: theme.textTheme.headlineSmall),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _modelController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Model Answer / Topic Keywords',
                hintText: 'Sahi answer yahan likho...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Your Answer:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _answerController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Type karo, mic se bolo, ya photo khicho...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'mic',
                      onPressed: _listen,
                      backgroundColor: _isListening ? Colors.red : AppColors.teal,
                      child: Icon(_isListening ? Icons.mic : Icons.mic_none),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'camera',
                      onPressed: () => _pickImage(ImageSource.camera),
                      backgroundColor: AppColors.blueSoft,
                      child: const Icon(Icons.camera_alt_outlined, color: AppColors.text),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'gallery',
                      onPressed: () => _pickImage(ImageSource.gallery),
                      backgroundColor: AppColors.yellowSoft,
                      child: const Icon(Icons.photo_library_outlined, color: AppColors.text),
                    ),
                  ],
                ),
              ],
            ),
            if (_image != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(_image!, height: 100, width: 100, fit: BoxFit.cover),
              ),
              TextButton.icon(
                onPressed: () => setState(() { _image = null; _answerController.clear(); }),
                icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                label: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _evaluate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                ),
                child: _loading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Check My Answer Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.greenSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Evaluation Score', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${_result!['score']}/100', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.green)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Feedback: ${_result!['feedback']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    const Text('AI Explanation:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
                    const SizedBox(height: 4),
                    Text(_result!['explanation'] ?? '', style: const TextStyle(height: 1.4)),
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

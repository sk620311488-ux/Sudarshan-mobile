import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    this.onStartDaily,
  });

  final AppController controller;
  final VoidCallback onOpenTests;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenLeaderboard;
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
                    onPressed: () => _showAiAnalysis(context, controller),
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
        const SizedBox(height: 12),
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
  String? _selectedSubjectFolder;
  String? _selectedSubSubjectFolder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allTests = widget.controller.tests;

    // Filter by search query first
    final searchFilteredTests = allTests.where((test) {
      final matchesSearch =
          test.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              test.chapter.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              test.subject.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    if (_searchQuery.isNotEmpty) {
      return _buildTestList(searchFilteredTests, theme);
    }

    if (_selectedSubSubjectFolder != null) {
      final subSubjectTests = allTests
          .where((test) => test.subject == _selectedSubSubjectFolder)
          .toList();
      return _buildChapterView(subSubjectTests, theme, isSubSubject: true);
    }

    if (_selectedSubjectFolder != null) {
      // Check if it has sub-subjects (like Science/SST)
      final subSubs = SubjectConstants.subSubjects[_selectedSubjectFolder];
      if (subSubs != null) {
        return _buildSubSubjectView(_selectedSubjectFolder!, subSubs, theme);
      }

      final subjectTests = allTests
          .where((test) => test.subject == _selectedSubjectFolder)
          .toList();
      return _buildChapterView(subjectTests, theme);
    }

    // Show Main Subjects as Folders
    final subjects = SubjectConstants.subjects;

    return Column(
      children: [
        _buildSearchBar(theme),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text('Subjects', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              ...subjects.map((sub) {
                return ListTile(
                  leading: const Icon(Icons.folder, color: AppColors.blue),
                  title: Text(sub, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => setState(() => _selectedSubjectFolder = sub),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubSubjectView(String parent, List<String> subs, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedSubjectFolder = null),
              ),
              Text(parent, style: theme.textTheme.titleLarge),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: subs.map((sub) {
              return ListTile(
                leading: const Icon(Icons.folder_shared, color: AppColors.teal),
                title: Text(sub, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => setState(() => _selectedSubSubjectFolder = sub),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search subjects, chapters, or titles...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: theme.cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildChapterView(List<AppTest> tests, ThemeData theme, {bool isSubSubject = false}) {
    final chapters = tests.map((e) => e.chapter).toSet().toList();
    chapters.sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (isSubSubject) {
                    setState(() => _selectedSubSubjectFolder = null);
                  } else {
                    setState(() => _selectedSubjectFolder = null);
                  }
                },
              ),
              Text(isSubSubject ? _selectedSubSubjectFolder! : _selectedSubjectFolder!,
                   style: theme.textTheme.titleLarge),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              if (tests.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text('No tests found in this category.'),
                )),
              ...chapters.map((chapter) {
                final chapterTests =
                    tests.where((t) => t.chapter == chapter).toList();
                return ExpansionTile(
                  leading: const Icon(Icons.book, color: AppColors.teal),
                  title: Text(chapter.isEmpty ? 'General' : chapter),
                  children: chapterTests
                      .map((test) => ListTile(
                            title: Text(test.title),
                            subtitle: Text('${test.questionCount} Qs | ${test.timeLimitMin} min'),
                            trailing: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => QuizScreen(
                                        controller: widget.controller,
                                        test: test),
                                  ),
                                );
                              },
                              child: const Text('Start'),
                            ),
                          ))
                      .toList(),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestList(List<AppTest> tests, ThemeData theme) {
    return Column(
      children: [
        _buildSearchBar(theme),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: tests
                .map((test) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(test.title, style: theme.textTheme.titleLarge),
                            const SizedBox(height: 4),
                            Text('${test.subject} | ${test.chapter}'),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${test.questionCount} Qs'),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => QuizScreen(
                                            controller: widget.controller,
                                            test: test),
                                      ),
                                    );
                                  },
                                  child: const Text('Start'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
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

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final streak = controller.dailyStreak;
    final achievements = controller.achievements;
    final level = controller.userLevel;
    final exp = controller.totalExp;
    final progress = controller.levelProgress;
    final rank = controller.rankTitle;
    final nextLevelAt = controller.nextLevelExp;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        SoftCard(
          color: theme.colorScheme.surface,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.brightness == Brightness.dark
                        ? AppColors.blueDark
                        : AppColors.blueSoft,
                    child: Icon(Icons.person,
                        size: 40, color: theme.colorScheme.onSurface),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(controller.session?.name ?? 'Student',
                  style: theme.textTheme.headlineSmall),
              Text(rank,
                  style: TextStyle(
                      color: theme.brightness == Brightness.dark
                          ? AppColors.accent
                          : AppColors.teal,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
              const SizedBox(height: 16),
              // Level Progress Bar
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Level $level',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('$exp / $nextLevelAt EXP',
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: theme.brightness == Brightness.dark
                          ? AppColors.lineDark
                          : theme.dividerColor,
                      color: AppColors.accent,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                HistoryScreen(controller: controller)),
                      );
                    },
                    child: _ProfileStat(
                        label: 'Tests', value: '${controller.attempts.length}'),
                  ),
                  _ProfileStat(label: 'Streak', value: '$streak'),
                  _ProfileStat(
                      label: 'Cards',
                      value: '${controller.notebookCards.length}'),
                ],
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _showEditIdDialog(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Student ID: ${controller.session?.studentId}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(width: 4),
                    Icon(Icons.edit,
                        size: 14, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Share My Progress'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.white,
                  ),
                  onPressed: () {
                    final name = controller.session?.name ?? 'Student';
                    final streak = controller.dailyStreak;
                    final level = controller.userLevel;
                    final tests = controller.attempts.length;
                    final cards = controller.notebookCards.length;
                    final studentId = controller.session?.studentId ?? '';

                    final text = '''
🚀 SUDARSHAN LEARNING JOURNEY 🚀
---------------------------
👤 Student: $name
🆔 Sudarshan ID: $studentId
🔥 Daily Streak: $streak Days
🎖️ Rank: ${controller.rankTitle} (Level $level)
📚 Tests Mastered: $tests
🧠 Memory Cards: $cards

🏆 I am mastering my Bihar Board subjects using Spaced Repetition on Sudarshan App!

Join me and let's compete together!
Download Sudarshan Now.
''';
                    SharePlus.instance.share(ShareParams(text: text));
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Settings', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        SoftCard(
          color: theme.cardColor,
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                    controller.isDarkMode ? Icons.dark_mode : Icons.light_mode),
                title: const Text('Dark Mode'),
                trailing: Switch(
                  value: controller.isDarkMode,
                  onChanged: (val) => controller.toggleTheme(),
                ),
              ),
              Divider(color: theme.dividerColor),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Show Onboarding Again'),
                onTap: () async {
                  // Quick reset for demo
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(
                      'sudarshan_mobile_onboarding_done', false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Restart app to see onboarding!')));
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Weekly Progress', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        SoftCard(
          color: theme.cardColor,
          child: SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                // Dummy logic for bars based on attempts in last 7 days
                final day = DateTime.now().subtract(Duration(days: 6 - index));
                final dateKey =
                    '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                final count = controller.attempts
                    .where((a) => a.dateKey == dateKey)
                    .length;
                final height = (count * 20.0).clamp(10.0, 100.0);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 30,
                      height: height,
                      decoration: BoxDecoration(
                        color:
                            count > 0 ? AppColors.blueSoft : theme.dividerColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1],
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('Achievements', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        if (achievements.isEmpty)
          const SoftCard(child: Text('Keep studying to unlock badges!')),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: achievements
              .map((a) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Text(a,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            onPressed: () => controller.signOut(),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        ),
      ],
    );
  }

  void _showEditIdDialog(BuildContext context) {
    final controllerText =
        TextEditingController(text: controller.session?.customStudentId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Student ID'),
        content: TextField(
          controller: controllerText,
          decoration: const InputDecoration(hintText: 'Enter your custom ID'),
          maxLength: 12,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.updateStudentId(controllerText.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
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

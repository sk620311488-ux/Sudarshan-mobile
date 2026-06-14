import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/leaderboard_service.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_card.dart';

class FriendsLeaderboardScreen extends StatefulWidget {
  const FriendsLeaderboardScreen({
    super.key,
    required this.currentUid,
    required this.friendProfiles,
  });

  final String currentUid;
  final List<PublicStudentProfile> friendProfiles;

  @override
  State<FriendsLeaderboardScreen> createState() => _FriendsLeaderboardScreenState();
}

class _FriendsLeaderboardScreenState extends State<FriendsLeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _leaderboardService = LeaderboardService();
  LeaderboardPeriod _period = LeaderboardPeriod.daily;
  late Stream<LeaderboardView> _dailyStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _dailyStream = _watchDaily();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<LeaderboardView> _watchDaily() {
    return _leaderboardService.watchLeaderboard(
      period: _period,
      currentUid: widget.currentUid,
    );
  }

  Set<String> get _allowedUids {
    final ids = widget.friendProfiles.map((item) => item.uid).toSet();
    ids.add(widget.currentUid);
    return ids;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // We need to find the current user's profile to include it in the EXP list
    // Actually, it's better to fetch fresh profiles or rely on the caller to provide them.
    // For now, let's assume friendProfiles has the data.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily Test'),
            Tab(text: 'All Time (EXP)'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildDailyTab(theme),
            _buildExpTab(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTab(ThemeData theme) {
    return StreamBuilder<LeaderboardView>(
      stream: _dailyStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final board = snapshot.data ??
            LeaderboardView(
              period: _period,
              entries: const [],
              totalParticipants: 0,
            );
        final filtered = board.entries.where((entry) => _allowedUids.contains(entry.uid)).toList()
          ..sort((a, b) => a.rank.compareTo(b.rank));

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Row(
              children: LeaderboardPeriod.values
                  .map(
                    (period) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(period.label),
                        selected: period == _period,
                        onSelected: (_) {
                          setState(() {
                            _period = period;
                            _dailyStream = _watchDaily();
                          });
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
              const SoftCard(
                child: Text('Abhi kisi friend ne is period me test nahi diya.'),
              )
            else
              ...filtered.asMap().entries.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _FriendRankTile(
                        entry: item.value.copyWith(rank: item.key + 1),
                        highlight: item.value.uid == widget.currentUid,
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }

  Widget _buildExpTab(ThemeData theme) {
    // Combine current user's profile with friends for the EXP list
    final sortedList = [...widget.friendProfiles]
      ..sort((a, b) => b.totalExp.compareTo(a.totalExp));

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const SoftCard(
          color: AppColors.tealSoft,
          child: Text('Doston ki All-Time ranking unke total EXP par aadharit hai.'),
        ),
        const SizedBox(height: 16),
        if (sortedList.isEmpty)
          const SoftCard(child: Text('Abhi koi friend add nahi kiya gaya.'))
        else
          ...sortedList.asMap().entries.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SoftCard(
                    color: item.value.uid == widget.currentUid ? AppColors.yellowSoft : AppColors.white,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: item.value.uid == widget.currentUid ? AppColors.accent : AppColors.blueSoft,
                          child: Text(
                            '#${item.key + 1}',
                            style: TextStyle(
                              color: item.value.uid == widget.currentUid ? Colors.white : AppColors.text,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.value.uid == widget.currentUid ? 'You' : item.value.displayName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: item.value.uid == widget.currentUid ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              Text('Level ${item.value.level} • ${item.value.rankTitle}'),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${item.value.totalExp}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                            ),
                            const Text('EXP', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

class _FriendRankTile extends StatelessWidget {
  const _FriendRankTile({
    required this.entry,
    required this.highlight,
  });

  final DailyLeaderboardEntry entry;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: highlight ? AppColors.yellowSoft : AppColors.white,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: highlight ? AppColors.accent : AppColors.blueSoft,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                color: highlight ? Colors.white : AppColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  highlight ? 'You' : entry.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${entry.studentId}  •  ${entry.points} pts',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.score}/${entry.total}  |  ${entry.percent}%  |  ${_timeLabel(entry.timeTakenSec)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeLabel(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes}m ${remaining.toString().padLeft(2, '0')}s';
  }
}

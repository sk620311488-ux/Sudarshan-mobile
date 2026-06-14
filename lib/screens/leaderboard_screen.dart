import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/leaderboard_service.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_card.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({
    super.key,
    required this.currentUid,
  });

  final String currentUid;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _service = LeaderboardService();
  LeaderboardPeriod _period = LeaderboardPeriod.daily;
  late Stream<LeaderboardView> _stream;

  @override
  void initState() {
    super.initState();
    _stream = _watch();
  }

  void _setPeriod(LeaderboardPeriod period) {
    if (_period == period) {
      return;
    }
    setState(() {
      _period = period;
      _stream = _watch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = widget.currentUid.trim().isEmpty;

    return StreamBuilder<LeaderboardView>(
      stream: _stream,
      builder: (context, snapshot) {
        final isRefreshing = snapshot.connectionState == ConnectionState.waiting;
        final hasData = snapshot.hasData && (snapshot.data?.entries.isNotEmpty ?? false);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Leaderboard'),
            actions: [
              if (isRefreshing && hasData)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                IconButton(
                  onPressed: () => setState(() => _stream = _watch(forceRefresh: true)),
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
          body: SafeArea(
            child: _buildBody(context, snapshot, isRefreshing, hasData, isGuest),
          ),
        );
      },
    );
  }

  Stream<LeaderboardView> _watch({bool forceRefresh = false}) {
    return _service.watchLeaderboard(
      period: _period,
      currentUid: widget.currentUid,
      forceRefresh: forceRefresh,
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<LeaderboardView> snapshot,
    bool isRefreshing,
    bool hasData,
    bool isGuest,
  ) {
    final theme = Theme.of(context);

    if (isRefreshing && !hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError || (!isRefreshing && !hasData)) {
      return ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _PeriodSelector(
            value: _period,
            onChanged: _setPeriod,
          ),
          const SizedBox(height: 16),
          SoftCard(
            color: AppColors.coralSoft,
            child: Column(
              children: [
                const Text(
                  'Leaderboard load nahi hui. Check Internet Connection.',
                  style: TextStyle(color: AppColors.text, height: 1.35),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => setState(() => _stream = _watch()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final board = snapshot.data ??
        LeaderboardView(
          period: _period,
          entries: const [],
          totalParticipants: 0,
        );

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _PeriodSelector(
          value: _period,
          onChanged: _setPeriod,
        ),
        const SizedBox(height: 16),
        SoftCard(
          color: AppColors.blueSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_period.label} Leaderboard',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                board.totalParticipants == 0
                    ? 'Abhi is period ke liye koi score nahi mila.'
                    : _periodDescription(_period, board.totalParticipants),
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (isGuest)
          SoftCard(
            color: AppColors.yellowSoft,
            child: Column(
              children: [
                const Text(
                  'Leaderboard join karne ke liye Sign In karein.',
                  style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Guest scores leaderboard par nahi dikhte.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          )
        else if (board.currentUser != null)
          _YourRankCard(board: board)
        else
          SoftCard(
            color: AppColors.yellowSoft,
            child: Text(
              _noScoreMessage(_period),
              style: const TextStyle(color: AppColors.text, height: 1.35),
            ),
          ),
        const SizedBox(height: 16),
        if (board.topTen.isEmpty)
          const SoftCard(
            color: AppColors.white,
            child: Text(
              'Top list abhi empty hai.',
              style: TextStyle(color: AppColors.muted, height: 1.35),
            ),
          )
        else
          ...board.topTen.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LeaderboardTile(
                entry: entry,
                highlight: !isGuest && entry.uid == widget.currentUid,
              ),
            ),
          ),
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.value,
    required this.onChanged,
  });

  final LeaderboardPeriod value;
  final ValueChanged<LeaderboardPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: LeaderboardPeriod.values
          .map(
            (period) => ChoiceChip(
              label: Text(period.label),
              selected: value == period,
              onSelected: (_) => onChanged(period),
            ),
          )
          .toList(),
    );
  }
}

class _YourRankCard extends StatelessWidget {
  const _YourRankCard({required this.board});

  final LeaderboardView board;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rank = board.currentUserRank ?? 0;
    final topPercent = board.currentUserTopPercent;
    final exactRankVisible = rank > 0 && rank <= 100;

    return SoftCard(
      color: AppColors.greenSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Position', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(
            exactRankVisible
                ? 'You are rank #$rank out of ${board.totalParticipants}'
                : topPercent == null
                    ? 'Rank abhi calculate nahi ho paya.'
                    : 'You are under top $topPercent%',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '${_currentScoreLabel(board)}: ${board.currentUser!.score}/${board.currentUser!.total}  |  ${board.currentUser!.percent}%  |  ${_timeLabel(board.currentUser!.timeTakenSec)}',
            style: theme.textTheme.bodyMedium,
          ),
          if (board.currentUser!.attemptCount > 1) ...[
            const SizedBox(height: 4),
            Text(
              _attemptCountMessage(board),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.entry,
    required this.highlight,
  });

  final DailyLeaderboardEntry entry;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final rank = entry.rank;
    Widget rankWidget;
    Color rankColor = highlight ? AppColors.accent : AppColors.blueSoft;
    
    if (rank == 1) {
      rankWidget = const Icon(Icons.emoji_events, color: Colors.amber, size: 28);
    } else if (rank == 2) {
      rankWidget = const Icon(Icons.emoji_events, color: Color(0xFFC0C0C0), size: 26);
    } else if (rank == 3) {
      rankWidget = const Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 24);
    } else {
      rankWidget = Text(
        '#$rank',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: highlight ? AppColors.white : AppColors.text,
        ),
      );
    }

    return SoftCard(
      color: highlight ? AppColors.yellowSoft : AppColors.white,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: rankWidget,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      highlight ? 'You' : entry.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'ID: ${entry.studentId}',
                      style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${entry.points} pts',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.teal),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${entry.score}/${entry.total}  |  ${entry.percent}%  |  ${_timeLabel(entry.timeTakenSec)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (entry.attemptCount > 1) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${entry.attemptCount} official daily scores combined',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _periodLabel(LeaderboardPeriod period) {
  switch (period) {
    case LeaderboardPeriod.daily:
      return 'Aaj ka';
    case LeaderboardPeriod.weekly:
      return 'Is hafte ka';
    case LeaderboardPeriod.monthly:
      return 'Is mahine ka';
  }
}

String _currentScoreLabel(LeaderboardView board) {
  if (board.period == LeaderboardPeriod.daily || board.currentUser == null) {
    return '${_periodLabel(board.period)} score';
  }
  return '${_periodLabel(board.period)} combined';
}

String _attemptCountMessage(LeaderboardView board) {
  final count = board.currentUser?.attemptCount ?? 0;
  switch (board.period) {
    case LeaderboardPeriod.daily:
      return '$count official attempts recorded today';
    case LeaderboardPeriod.weekly:
      return '$count official daily scores combined over the last 7 days';
    case LeaderboardPeriod.monthly:
      return '$count official daily scores combined over the last 30 days';
  }
}

String _timeLabel(int seconds) {
  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;
  return '${minutes}m ${remaining.toString().padLeft(2, '0')}s';
}

String _periodDescription(LeaderboardPeriod period, int count) {
  switch (period) {
    case LeaderboardPeriod.daily:
      return 'Top 10 aaj ke scores. Daily test ka pehla attempt count hota hai.';
    case LeaderboardPeriod.weekly:
      return 'Pichle 7 din ke best scores. $count students ne participate kiya.';
    case LeaderboardPeriod.monthly:
      return 'Pichle 30 din ke best scores. $count students ne participate kiya.';
  }
}

String _noScoreMessage(LeaderboardPeriod period) {
  switch (period) {
    case LeaderboardPeriod.daily:
      return 'Tumhara aaj ka score nahi mila. Daily test ka pehla attempt complete karo.';
    case LeaderboardPeriod.weekly:
      return 'Pichle 7 din mein tumhara koi daily test score nahi mila. Aaj ka daily test do.';
    case LeaderboardPeriod.monthly:
      return 'Pichle 30 din mein tumhara koi daily test score nahi mila. Aaj ka daily test do.';
  }
}

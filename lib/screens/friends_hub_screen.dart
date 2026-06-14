import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/app_models.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_card.dart';
import 'friends_leaderboard_screen.dart';
import 'public_profile_screen.dart';

class FriendsHubScreen extends StatefulWidget {
  const FriendsHubScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  State<FriendsHubScreen> createState() => _FriendsHubScreenState();
}

class _FriendsHubScreenState extends State<FriendsHubScreen> {
  final _searchController = TextEditingController();
  PublicStudentProfile? _result;
  bool _searching = false;
  String _message = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim().toUpperCase();
    if (query.isEmpty) {
      setState(() {
        _result = null;
        _message = 'Custom ID enter karo.';
      });
      return;
    }

    setState(() {
      _searching = true;
      _message = '';
    });

    final profile = await widget.controller.searchProfileByStudentId(query);
    if (!mounted) {
      return;
    }

    setState(() {
      _searching = false;
      _result = profile;
      _message = profile == null ? 'Is ID se koi profile nahi mili.' : '';
    });
  }

  Future<void> _sendRequest(PublicStudentProfile profile, String message) async {
    if (profile.uid == widget.controller.session?.uid) {
      setState(() {
        _message = 'Apne aap ko friend list me add nahi kar sakte.';
      });
      return;
    }

    await widget.controller.sendFriendRequest(profile.uid, message: message);
    if (!mounted) return;

    setState(() {
      _message = '${profile.displayName} ko friend request bhej di gayi hai.';
      _result = null;
      _searchController.clear();
    });
  }

  void _showRequestDialog(PublicStudentProfile profile) {
    final msgController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${profile.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Koi message bhejna chahte ho? (Optional)'),
            const SizedBox(height: 12),
            TextField(
              controller: msgController,
              decoration: const InputDecoration(hintText: 'e.g. Hi, main Rahul hoon!'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendRequest(profile, msgController.text.trim());
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.controller.session;
    final ownProfile = widget.controller.publicProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends & Invite'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<PublicStudentProfile>>(
          stream: widget.controller.watchFriendProfiles(),
          builder: (context, snapshot) {
            final friends = snapshot.data ?? const <PublicStudentProfile>[];
            final isRefreshing = snapshot.connectionState == ConnectionState.waiting;

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                if (isRefreshing && friends.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                SoftCard(
                  color: AppColors.blueSoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Friend Circle',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Icon(Icons.group_work, color: AppColors.accent),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.qr_code_scanner, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Your Sudarshan ID', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                                  Text(
                                    session?.studentId ?? 'Not set',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: session?.studentId ?? ''));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID Copied!')));
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Doston ke saath compete karein aur apni progress unke saath share karein.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: ownProfile == null
                                  ? null
                                  : () async {
                                      await SharePlus.instance.share(ShareParams(text: 'Join my Sudarshan Friend Circle! 🚀\n\n'
                                              'My ID: ${ownProfile.customStudentId}\n'
                                              'Student: ${ownProfile.displayName}\n\n'
                                              'Download Sudarshan and let\'s study together!'));
                                    },
                              icon: const Icon(Icons.person_add_alt_1),
                              label: const Text('Invite Friends'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final profile = widget.controller.publicProfile;
                            final allProfiles = [...friends];
                            if (profile != null) {
                              allProfiles.add(profile);
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => FriendsLeaderboardScreen(
                                  currentUid: session?.uid ?? '',
                                  friendProfiles: allProfiles,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.leaderboard),
                          label: const Text('Friends Leaderboard'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                StreamBuilder<List<FriendRequest>>(
                  stream: widget.controller.watchIncomingRequests(),
                  builder: (context, reqSnap) {
                    final requests = reqSnap.data ?? [];
                    if (requests.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pending Requests', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        ...requests.map((req) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SoftCard(
                            color: AppColors.yellowSoft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${req.fromName} has sent you a request',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (req.message.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('"${req.message}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => widget.controller.respondToFriendRequest(req, FriendRequestStatus.accepted),
                                      child: const Text('Accept'),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: () => widget.controller.respondToFriendRequest(req, FriendRequestStatus.declined),
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                      child: const Text('Deny'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )),
                        const SizedBox(height: 18),
                      ],
                    );
                  },
                ),
                SoftCard(
                  color: AppColors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add By Custom ID',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Friend Custom ID',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _searching ? null : _search,
                          child: Text(_searching ? 'Searching...' : 'Search Student'),
                        ),
                      ),
                      if (_message.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(_message),
                      ],
                      if (_result != null) ...[
                        const SizedBox(height: 14),
                        _SearchResultCard(
                          profile: _result!,
                          onAdd: () => _showRequestDialog(_result!),
                          onOpen: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PublicProfileScreen(profile: _result!),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Friends (${friends.length}/200)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (friends.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FriendsLeaderboardScreen(
                                currentUid: session?.uid ?? '',
                                friendProfiles: friends,
                              ),
                            ),
                          );
                        },
                        child: const Text('Open Board'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (friends.isEmpty)
                  const SoftCard(
                    child: Text('Abhi tak koi friend add nahi hua.'),
                  )
                else
                  ...friends.map(
                    (friend) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _FriendProfileTile(
                        profile: friend,
                        controller: widget.controller,
                        onOpen: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PublicProfileScreen(profile: friend),
                            ),
                          );
                        },
                        onRemove: () async {
                          await widget.controller.removeFriend(friend.uid);
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.profile,
    required this.onAdd,
    required this.onOpen,
  });

  final PublicStudentProfile profile;
  final VoidCallback onAdd;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: AppColors.tealSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(profile.displayName, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('ID: ${profile.customStudentId}'),
          const SizedBox(height: 4),
          Text('Level ${profile.level}  •  ${profile.rankTitle}'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton(
                onPressed: onAdd,
                child: const Text('Send Request'),
              ),
              OutlinedButton(
                onPressed: onOpen,
                child: const Text('View Profile'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FriendProfileTile extends StatelessWidget {
  const _FriendProfileTile({
    required this.profile,
    required this.onOpen,
    required this.onRemove,
    required this.controller,
  });

  final PublicStudentProfile profile;
  final VoidCallback onOpen;
  final VoidCallback onRemove;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.blueSoft,
                child: Text(
                  profile.displayName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.displayName, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('ID: ${profile.customStudentId}'),
                    const SizedBox(height: 4),
                    Text('Level ${profile.level}  •  ${profile.rankTitle}'),
                  ],
                ),
              ),
              IconButton(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.person_remove_outlined),
              ),
            ],
          ),
          FutureBuilder<List<PublicStudentProfile>>(
            future: controller.getMutualFriends(profile.uid),
            builder: (context, snap) {
              final mutuals = snap.data ?? [];
              if (mutuals.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.group, size: 14, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      '${mutuals.length} mutual friend${mutuals.length > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

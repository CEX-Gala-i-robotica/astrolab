import 'package:flutter/material.dart';

import '../services/leaderboard_service.dart';
import '../theme/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  final String uid;
  final String token;

  const LeaderboardScreen({super.key, required this.uid, required this.token});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late final LeaderboardService _service;
  final _friendCtrl = TextEditingController();
  bool _showFriendsOnly = false;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  LeaderboardSnapshot _snapshot = const LeaderboardSnapshot(
    global: [],
    friends: [],
    incomingRequests: [],
  );

  @override
  void initState() {
    super.initState();
    _service = LeaderboardService(uid: widget.uid, token: widget.token);
    _load();
  }

  @override
  void dispose() {
    _friendCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await _service.loadSnapshot();
      if (mounted) setState(() => _snapshot = snapshot);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addFriend() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final err = await _service.addFriendByUsername(_friendCtrl.text);
      if (!mounted) return;
      if (err != null) {
        setState(() => _error = err);
        return;
      }
      _friendCtrl.clear();
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accept(String uid) async {
    await _friendAction(() => _service.acceptRequest(uid));
  }

  Future<void> _reject(String uid) async {
    await _friendAction(() => _service.rejectRequest(uid));
  }

  Future<void> _remove(String uid) async {
    await _friendAction(() => _service.removeFriend(uid));
  }

  Future<void> _friendAction(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width < 600 ? 16.0 : 32.0;
    final entries = _showFriendsOnly ? _snapshot.friends : _snapshot.global;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 36),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    _StatusBanner(message: _error!),
                    const SizedBox(height: 14),
                  ],
                  _friendManager(),
                  const SizedBox(height: 16),
                  _tabs(),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (entries.isEmpty)
                    _empty()
                  else
                    ...List.generate(
                      entries.length,
                      (index) => _LeaderboardTile(
                        rank: index + 1,
                        entry: entries[index],
                        onRemoveFriend:
                            entries[index].isFriend &&
                                !entries[index].isCurrentUser
                            ? () => _remove(entries[index].uid)
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    final current = _snapshot.global.where((entry) => entry.isCurrentUser);
    final me = current.isEmpty ? null : current.first;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.13),
              border: Border.all(color: AppColors.primary.withOpacity(0.35)),
            ),
            child: const Icon(
              Icons.leaderboard_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Clasament',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  me == null
                      ? 'Finalizeaza lectii si teste ca sa apari in clasament.'
                      : '@${me.username} - ${me.score} puncte',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Reincarca',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _friendManager() {
    return _Panel(
      title: 'Prieteni',
      icon: Icons.group_add_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 230,
                child: TextField(
                  controller: _friendCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration('Username prieten'),
                  onSubmitted: (_) => _addFriend(),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _busy ? null : _addFriend,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Adauga'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          if (_snapshot.incomingRequests.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Cereri primite',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ..._snapshot.incomingRequests.map(
              (request) => _RequestTile(
                request: request,
                onAccept: () => _accept(request.fromUid),
                onReject: () => _reject(request.fromUid),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tabs() {
    return Row(
      children: [
        Expanded(
          child: _TabButton(
            label: 'Toti utilizatorii',
            icon: Icons.public_rounded,
            selected: !_showFriendsOnly,
            onTap: () => setState(() => _showFriendsOnly = false),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TabButton(
            label: 'Prietenii mei',
            icon: Icons.group_rounded,
            selected: _showFriendsOnly,
            onTap: () => setState(() => _showFriendsOnly = true),
          ),
        ),
      ],
    );
  }

  Widget _empty() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.surface.withOpacity(0.92),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.primary.withOpacity(0.16)),
    ),
    child: Text(
      _showFriendsOnly
          ? 'Adauga prieteni ca sa vezi clasamentul apropiat.'
          : 'Nu exista inca utilizatori cu punctaj.',
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.textMuted),
    ),
  );

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMuted),
      prefixIcon: const Icon(
        Icons.alternate_email_rounded,
        color: AppColors.textMuted,
        size: 19,
      ),
      filled: true,
      fillColor: AppColors.background.withOpacity(0.70),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.16)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.55)),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Panel({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.93),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final VoidCallback? onRemoveFriend;

  const _LeaderboardTile({
    required this.rank,
    required this.entry,
    this.onRemoveFriend,
  });

  @override
  Widget build(BuildContext context) {
    final color = entry.isCurrentUser
        ? AppColors.primary
        : rank <= 3
        ? AppColors.secondary
        : AppColors.textSecondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppColors.primary.withOpacity(0.10)
            : AppColors.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${entry.username}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (entry.displayName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${entry.score} pct',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (onRemoveFriend != null) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Sterge prieten',
              onPressed: onRemoveFriend,
              icon: const Icon(
                Icons.person_remove_alt_1_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestTile({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.44),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '@${request.fromUsername}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Accepta',
            onPressed: onAccept,
            icon: const Icon(Icons.check_rounded, color: Colors.greenAccent),
          ),
          IconButton(
            tooltip: 'Respinge',
            onPressed: onReject,
            icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.16)
              : AppColors.surface.withOpacity(0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.primary.withOpacity(0.45)
                : AppColors.primary.withOpacity(0.14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String message;

  const _StatusBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

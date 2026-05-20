import 'dart:convert';

import 'package:http/http.dart' as http;

class LeaderboardService {
  static const String _dbUrl = String.fromEnvironment('FIREBASE_DB_URL');

  final String uid;
  final String token;

  const LeaderboardService({required this.uid, required this.token});

  bool get isConfigured =>
      _dbUrl.isNotEmpty && uid.isNotEmpty && token.isNotEmpty;

  Future<LeaderboardSnapshot> loadSnapshot() async {
    _ensureConfigured();
    final leaderboard = await _getMap('leaderboard');
    final profiles = await _getMap('publicProfiles');
    final friendships = await _getMap('friendships/$uid');
    final requests = await _getMap('friendRequests/$uid');

    final friendIds = friendships.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toSet();

    final entries = <LeaderboardEntry>[];
    for (final entry in leaderboard.entries) {
      final scoreData = entry.value;
      if (scoreData is! Map) continue;
      final profile = profiles[entry.key];
      final profileMap = profile is Map
          ? Map<dynamic, dynamic>.from(profile)
          : <dynamic, dynamic>{};
      entries.add(
        LeaderboardEntry(
          uid: entry.key,
          username: _readString(profileMap, 'username', fallback: 'user'),
          displayName: _readString(profileMap, 'displayName'),
          score: _readInt(scoreData, 'score'),
          isCurrentUser: entry.key == uid,
          isFriend: friendIds.contains(entry.key),
        ),
      );
    }
    entries.sort((a, b) => b.score.compareTo(a.score));

    final incoming = <FriendRequest>[];
    for (final entry in requests.entries) {
      final data = entry.value;
      if (data is! Map) continue;
      incoming.add(
        FriendRequest(
          fromUid: entry.key,
          fromUsername: _readString(data, 'fromUsername', fallback: 'user'),
          createdAt: _readString(data, 'createdAt'),
        ),
      );
    }
    incoming.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return LeaderboardSnapshot(
      global: entries,
      friends: entries
          .where((entry) => entry.isCurrentUser || entry.isFriend)
          .toList(),
      incomingRequests: incoming,
    );
  }

  Future<String?> addFriendByUsername(String rawUsername) async {
    _ensureConfigured();
    final username = _normalizeUsername(rawUsername);
    if (!_isValidUsername(username)) {
      return 'Username invalid. Foloseste 3-20 caractere: litere, cifre sau _.';
    }

    final profile = await _getMap('publicProfiles/$uid');
    final currentUsername = _readString(profile, 'username', fallback: 'user');
    if (username == currentUsername) {
      return 'Nu iti poti trimite cerere tie.';
    }

    final targetUid = await _getValue('usernames/$username');
    if (targetUid is! String || targetUid.isEmpty) {
      return 'Nu exista un utilizator cu acest username.';
    }

    final existingFriends = await _getValue('friendships/$uid/$targetUid');
    if (existingFriends == true) return 'Sunteti deja prieteni.';

    await _put('friendRequests/$targetUid/$uid', {
      'fromUid': uid,
      'fromUsername': currentUsername,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return null;
  }

  Future<void> acceptRequest(String fromUid) async {
    _ensureConfigured();
    await _put('friendships/$uid/$fromUid', true);
    await _put('friendships/$fromUid/$uid', true);
    await _delete('friendRequests/$uid/$fromUid');
  }

  Future<void> rejectRequest(String fromUid) async {
    _ensureConfigured();
    await _delete('friendRequests/$uid/$fromUid');
  }

  Future<void> removeFriend(String friendUid) async {
    _ensureConfigured();
    await _delete('friendships/$uid/$friendUid');
    await _delete('friendships/$friendUid/$uid');
  }

  Future<Map<String, dynamic>> _getMap(String path) async {
    final value = await _getValue(path);
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  Future<dynamic> _getValue(String path) async {
    final response = await http.get(
      Uri.parse('$_dbUrl/$path.json?auth=$token'),
    );
    _throwIfBad(response);
    final body = response.body.trim();
    if (body.isEmpty || body == 'null') return null;
    return jsonDecode(body);
  }

  Future<void> _put(String path, Object value) async {
    final response = await http.put(
      Uri.parse('$_dbUrl/$path.json?auth=$token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(value),
    );
    _throwIfBad(response);
  }

  Future<void> _delete(String path) async {
    final response = await http.delete(
      Uri.parse('$_dbUrl/$path.json?auth=$token'),
    );
    _throwIfBad(response);
  }

  void _throwIfBad(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw LeaderboardException(
      'Firebase a raspuns cu ${response.statusCode}: ${response.body}',
    );
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw const LeaderboardException(
        'Sesiunea sau FIREBASE_DB_URL lipseste pentru clasament.',
      );
    }
  }

  static String _normalizeUsername(String value) => value.trim().toLowerCase();

  static bool _isValidUsername(String value) =>
      RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(value);

  static String _readString(
    Map<dynamic, dynamic> map,
    String key, {
    String fallback = '',
  }) {
    final value = map[key];
    return value is String && value.trim().isNotEmpty ? value : fallback;
  }

  static int _readInt(Map<dynamic, dynamic> map, String key) {
    final value = map[key];
    return value is num ? value.round() : 0;
  }
}

class LeaderboardSnapshot {
  final List<LeaderboardEntry> global;
  final List<LeaderboardEntry> friends;
  final List<FriendRequest> incomingRequests;

  const LeaderboardSnapshot({
    required this.global,
    required this.friends,
    required this.incomingRequests,
  });
}

class LeaderboardEntry {
  final String uid;
  final String username;
  final String displayName;
  final int score;
  final bool isCurrentUser;
  final bool isFriend;

  const LeaderboardEntry({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.score,
    required this.isCurrentUser,
    required this.isFriend,
  });
}

class FriendRequest {
  final String fromUid;
  final String fromUsername;
  final String createdAt;

  const FriendRequest({
    required this.fromUid,
    required this.fromUsername,
    required this.createdAt,
  });
}

class LeaderboardException implements Exception {
  final String message;
  const LeaderboardException(this.message);

  @override
  String toString() => message;
}

import 'package:shared_preferences/shared_preferences.dart';

/// Gestionează sesiunea utilizatorului — echivalent cu Registry (RegPath) din C#
/// Pe mobile/desktop folosim shared_preferences în loc de Windows Registry.
class SessionService {
  static const _kRememberMe = 'remember_me';
  static const _kEmail      = 'email';
  static const _kIdToken    = 'id_token';
  static const _kUid        = 'uid';
  static const _kLoggedIn   = 'logged_in';

  /// Salvează sesiunea [Login.cs → SaveSession]
  static Future<void> save({
    required String email,
    required String idToken,
    required String uid,
    required bool   rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool  (_kRememberMe, rememberMe);
    await prefs.setString(_kEmail,      rememberMe ? email   : '');
    await prefs.setString(_kIdToken,    rememberMe ? idToken : '');
    await prefs.setString(_kUid,        rememberMe ? uid     : '');
    await prefs.setBool  (_kLoggedIn,   true);
  }

  /// Citește sesiunea salvată
  static Future<SavedSession> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SavedSession(
      rememberMe: prefs.getBool(_kRememberMe)   ?? false,
      email:      prefs.getString(_kEmail)       ?? '',
      idToken:    prefs.getString(_kIdToken)     ?? '',
      uid:        prefs.getString(_kUid)         ?? '',
      loggedIn:   prefs.getBool(_kLoggedIn)      ?? false,
    );
  }

  /// Șterge sesiunea la logout
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRememberMe);
    await prefs.remove(_kEmail);
    await prefs.remove(_kIdToken);
    await prefs.remove(_kUid);
    await prefs.setBool(_kLoggedIn, false);
  }
}

class SavedSession {
  final bool   rememberMe;
  final String email;
  final String idToken;
  final String uid;
  final bool   loggedIn;

  const SavedSession({
    required this.rememberMe,
    required this.email,
    required this.idToken,
    required this.uid,
    required this.loggedIn,
  });
}
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AuthService {
  static const String _apiKey = String.fromEnvironment('FIREBASE_API_KEY_WEB');
  static const String _dbUrl = String.fromEnvironment('FIREBASE_DB_URL');

  static const _signInUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword';
  static const _signUpUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp';
  static const _resetUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode';
  static const _googleUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp';
  static const _refreshUrl = 'https://securetoken.googleapis.com/v1/token';

  // Client ID pentru Web / Mobile
  static const _googleClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  // Client ID pentru Desktop (OAuth2 "Desktop app" din Google Cloud Console)
  static const _googleDesktopClientId = String.fromEnvironment(
    'GOOGLE_DESKTOP_CLIENT_ID',
  );

  // Secret pentru Desktop client (necesar pentru googleapis_auth)
  static const _googleDesktopClientSecret = String.fromEnvironment(
    'GOOGLE_DESKTOP_CLIENT_SECRET',
  );

  static bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  static final _googleSignIn = kIsWeb
      ? GoogleSignIn(
          clientId: _googleClientId,
          scopes: ['email', 'profile', 'openid'],
        )
      : GoogleSignIn(
          serverClientId: _googleClientId,
          scopes: ['email', 'profile', 'openid'],
        );

  // ─────────────────────────────────────────────
  // Email / Parolă
  // ─────────────────────────────────────────────

  static Future<AuthResult> signIn(String email, String password) => _call(
    _signInUrl,
    {'email': email, 'password': password, 'returnSecureToken': true},
  );

  static Future<AuthResult> signUp(String email, String password) => _call(
    _signUpUrl,
    {'email': email, 'password': password, 'returnSecureToken': true},
  );

  static Future<String?> sendPasswordReset(String email) async {
    try {
      final res = await http.post(
        Uri.parse('$_resetUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'requestType': 'PASSWORD_RESET', 'email': email}),
      );
      if (res.statusCode == 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return translateError(data['error']?['message'] as String?);
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────────
  // Google Sign-In (Web + Mobile + Desktop)
  // ─────────────────────────────────────────────

  static Future<AuthResult> signInWithGoogle() async {
    if (_isDesktop) {
      return _signInWithGoogleDesktop();
    }
    return _signInWithGoogleMobileOrWeb();
  }

  /// Google Sign-In pentru Web și Mobile (Android / iOS)
  static Future<AuthResult> _signInWithGoogleMobileOrWeb() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult.err('Autentificare anulată.');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null && accessToken == null) {
        return AuthResult.err('Nu s-a putut obține token Google.');
      }

      final postBody = idToken != null
          ? 'id_token=$idToken&providerId=google.com'
          : 'access_token=$accessToken&providerId=google.com';

      return _exchangeGoogleTokenWithFirebase(postBody);
    } catch (e) {
      return AuthResult.err(e.toString());
    }
  }

  /// Google Sign-In pentru Desktop (Windows / Linux / macOS)
  /// Folosește googleapis_auth cu OAuth2 flow — deschide browserul și
  /// ascultă callback-ul pe un port local temporar.
  static Future<AuthResult> _signInWithGoogleDesktop() async {
    try {
      final clientId = ClientId(
        _googleDesktopClientId,
        _googleDesktopClientSecret,
      );

      final scopes = ['email', 'profile', 'openid'];

      // googleapis_auth pornește un server HTTP local temporar și
      // redirecționează utilizatorul în browser pentru autentificare.
      final authClient = await clientViaUserConsent(clientId, scopes, (
        String url,
      ) async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Nu se poate deschide browserul: $url');
        }
      });

      final credentials = authClient.credentials;
      final idToken = credentials.idToken;
      final accessToken = credentials.accessToken.data;

      authClient.close();

      if (idToken == null && accessToken.isEmpty) {
        return AuthResult.err('Nu s-a putut obține token Google (desktop).');
      }

      final postBody = (idToken != null && idToken.isNotEmpty)
          ? 'id_token=$idToken&providerId=google.com'
          : 'access_token=$accessToken&providerId=google.com';

      return _exchangeGoogleTokenWithFirebase(postBody);
    } catch (e) {
      return AuthResult.err(e.toString());
    }
  }

  /// Trimite token-ul Google la Firebase Identity Toolkit și
  /// returnează un AuthResult cu idToken Firebase, uid și email.
  static Future<AuthResult> _exchangeGoogleTokenWithFirebase(
    String postBody,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$_googleUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'postBody': postBody,
          'requestUri': 'http://localhost',
          'returnSecureToken': true,
        }),
      );

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        return AuthResult.ok(
          idToken: data['idToken'] ?? '',
          refreshToken: data['refreshToken'] ?? '',
          uid: data['localId'] ?? '',
          email: data['email'] ?? '',
        );
      }

      return AuthResult.err(
        translateError(data['error']?['message'] as String?),
      );
    } catch (e) {
      return AuthResult.err(e.toString());
    }
  }

  // ─────────────────────────────────────────────
  // Sign Out
  // ─────────────────────────────────────────────

  static Future<void> signOutGoogle() async {
    if (_isDesktop) return; // googleapis_auth nu are sesiune persistentă
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  // ─────────────────────────────────────────────
  // Utilități
  // ─────────────────────────────────────────────

  static Future<bool> needsProfileSetup(String token, String uid) async {
    if (_dbUrl.isEmpty || token.isEmpty || uid.isEmpty) return true;

    try {
      final userUrl = '$_dbUrl/$uid.json?auth=$token';
      final userRes = await http.get(Uri.parse(userUrl));
      if (userRes.statusCode < 200 || userRes.statusCode >= 300) {
        return true;
      }

      final body = userRes.body.trim();
      if (body.isEmpty || body == 'null') return true;

      final decoded = jsonDecode(body);
      if (decoded is! Map) return true;

      final data = Map<String, dynamic>.from(decoded);
      final rootSetup = data['setup'];
      final profile = data['profile'];
      final profileSetup = profile is Map ? profile['setup'] : null;

      return rootSetup != true && profileSetup != true;
    } catch (_) {
      return true;
    }
  }

  static Future<Map<String, dynamic>?> loadProfile({
    required String token,
    required String uid,
  }) async {
    if (_dbUrl.isEmpty || token.isEmpty || uid.isEmpty) return null;

    try {
      final res = await http.get(
        Uri.parse('$_dbUrl/$uid/profile.json?auth=$token'),
      );
      if (res.statusCode < 200 || res.statusCode >= 300) return null;

      final body = res.body.trim();
      if (body.isEmpty || body == 'null') return null;

      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;

      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<AuthResult> refreshSession(String refreshToken) async {
    if (refreshToken.isEmpty) {
      return AuthResult.err('Nu exista sesiune salvata.');
    }

    try {
      final res = await http.post(
        Uri.parse('$_refreshUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'grant_type': 'refresh_token', 'refresh_token': refreshToken},
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return AuthResult.ok(
          idToken: data['id_token'] ?? '',
          refreshToken: data['refresh_token'] ?? refreshToken,
          uid: data['user_id'] ?? '',
          email: '',
        );
      }
      return AuthResult.err(
        translateError(data['error']?['message'] as String?),
      );
    } catch (e) {
      return AuthResult.err(e.toString());
    }
  }

  static Future<String?> saveProfileSetup({
    required String token,
    required String uid,
    required Map<String, dynamic> profile,
  }) async {
    if (_dbUrl.isEmpty) {
      return 'FIREBASE_DB_URL lipseste din dart-define/.env.';
    }
    if (token.isEmpty || uid.isEmpty) {
      return 'Sesiunea Firebase nu este valida.';
    }

    try {
      final completedAt = DateTime.now().toIso8601String();
      final username = _normalizeUsername(
        profile['username']?.toString() ?? '',
      );
      if (!_isValidUsername(username)) {
        return 'Username-ul trebuie sa aiba 3-20 caractere: litere, cifre sau _.';
      }

      final usernameRes = await http.get(
        Uri.parse('$_dbUrl/usernames/$username.json?auth=$token'),
      );
      if (usernameRes.statusCode >= 200 && usernameRes.statusCode < 300) {
        final existingUid = usernameRes.body.trim().replaceAll('"', '');
        if (existingUid.isNotEmpty &&
            existingUid != 'null' &&
            existingUid != uid) {
          return 'Username-ul este deja folosit.';
        }
      }

      final profileRes = await http.put(
        Uri.parse('$_dbUrl/$uid/profile.json?auth=$token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          ...profile,
          'username': username,
          'setup': true,
          'setupCompletedAt': completedAt,
        }),
      );
      if (profileRes.statusCode < 200 || profileRes.statusCode >= 300) {
        return _firebaseDbError('profilul', profileRes);
      }

      final setupRes = await http.put(
        Uri.parse('$_dbUrl/$uid/setup.json?auth=$token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(true),
      );
      if (setupRes.statusCode < 200 || setupRes.statusCode >= 300) {
        return _firebaseDbError('setup', setupRes);
      }

      final usernameSaveRes = await http.put(
        Uri.parse('$_dbUrl/usernames/$username.json?auth=$token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(uid),
      );
      if (usernameSaveRes.statusCode < 200 ||
          usernameSaveRes.statusCode >= 300) {
        return _firebaseDbError('username', usernameSaveRes);
      }

      final publicProfileRes = await http.put(
        Uri.parse('$_dbUrl/publicProfiles/$uid.json?auth=$token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'username': username,
          'displayName':
              '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'
                  .trim(),
          'updatedAt': completedAt,
        }),
      );
      if (publicProfileRes.statusCode < 200 ||
          publicProfileRes.statusCode >= 300) {
        return _firebaseDbError('profilul public', publicProfileRes);
      }

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  static String _normalizeUsername(String value) => value.trim().toLowerCase();

  static bool _isValidUsername(String value) {
    return RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(value);
  }

  static String _firebaseDbError(String target, http.Response res) {
    try {
      final data = jsonDecode(res.body);
      if (data is Map && data['error'] != null) {
        return 'Firebase a respins $target: ${data['error']}';
      }
    } catch (_) {}
    return 'Firebase a respins $target (${res.statusCode}): ${res.body}';
  }

  static String translateError(String? code) {
    switch (code) {
      case 'EMAIL_NOT_FOUND':
      case 'INVALID_PASSWORD':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Email sau parolă incorectă.';
      case 'USER_DISABLED':
        return 'Contul a fost dezactivat.';
      case 'EMAIL_EXISTS':
        return 'Adresa de email este deja înregistrată.';
      case 'WEAK_PASSWORD':
      case 'WEAK_PASSWORD : Password should be at least 6 characters':
        return 'Parola trebuie să aibă cel puțin 6 caractere.';
      case 'TOO_MANY_ATTEMPTS_TRY_LATER':
        return 'Prea multe încercări. Încearcă mai târziu.';
      case 'INVALID_EMAIL':
        return 'Adresa de email nu este validă.';
      default:
        return code ?? 'Eroare necunoscută.';
    }
  }

  static Future<AuthResult> _call(String url, Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$url?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return AuthResult.ok(
          idToken: data['idToken'] ?? '',
          refreshToken: data['refreshToken'] ?? '',
          uid: data['localId'] ?? '',
          email: data['email'] ?? '',
        );
      }
      return AuthResult.err(
        translateError(data['error']?['message'] as String?),
      );
    } catch (e) {
      return AuthResult.err(e.toString());
    }
  }
}

// ─────────────────────────────────────────────
// AuthResult
// ─────────────────────────────────────────────

class AuthResult {
  final bool ok;
  final String? idToken;
  final String? refreshToken;
  final String? uid;
  final String? email;
  final String? error;

  const AuthResult._({
    required this.ok,
    this.idToken,
    this.refreshToken,
    this.uid,
    this.email,
    this.error,
  });

  factory AuthResult.ok({
    required String idToken,
    required String refreshToken,
    required String uid,
    required String email,
  }) => AuthResult._(
    ok: true,
    idToken: idToken,
    refreshToken: refreshToken,
    uid: uid,
    email: email,
  );

  factory AuthResult.err(String error) => AuthResult._(ok: false, error: error);
}

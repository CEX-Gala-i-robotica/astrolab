import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AuthService {
  static const String _apiKey = String.fromEnvironment('FIREBASE_API_KEY_WEB');
  static const String _dbUrl  = String.fromEnvironment('FIREBASE_DB_URL');

  static const _signInUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword';
  static const _signUpUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp';
  static const _resetUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode';
  static const _googleUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp';

  // Client ID pentru Web / Mobile
  static const _googleClientId =
  String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  // Client ID pentru Desktop (OAuth2 "Desktop app" din Google Cloud Console)
  static const _googleDesktopClientId =
  String.fromEnvironment('GOOGLE_DESKTOP_CLIENT_ID');

  // Secret pentru Desktop client (necesar pentru googleapis_auth)
  static const _googleDesktopClientSecret =
  String.fromEnvironment('GOOGLE_DESKTOP_CLIENT_SECRET');

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

  static Future<AuthResult> signIn(String email, String password) =>
      _call(_signInUrl, {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      });

  static Future<AuthResult> signUp(String email, String password) =>
      _call(_signUpUrl, {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      });

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
      final idToken    = googleAuth.idToken;
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
      final authClient = await clientViaUserConsent(
        clientId,
        scopes,
            (String url) async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            throw Exception('Nu se poate deschide browserul: $url');
          }
        },
      );

      final credentials  = authClient.credentials;
      final idToken      = credentials.idToken;
      final accessToken  = credentials.accessToken.data;

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
      String postBody) async {
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
          uid:     data['localId'] ?? '',
          email:   data['email'] ?? '',
        );
      }

      return AuthResult.err(
          translateError(data['error']?['message'] as String?));
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
    try {
      final url = '$_dbUrl/$uid/profile/setup.json?auth=$token';
      final res = await http.get(Uri.parse(url));
      final body = res.body.trim();
      return body == 'null' || body == 'false' || body.isEmpty;
    } catch (_) {
      return false;
    }
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

  static Future<AuthResult> _call(
      String url, Map<String, dynamic> body) async {
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
          uid:     data['localId'] ?? '',
          email:   data['email'] ?? '',
        );
      }
      return AuthResult.err(
          translateError(data['error']?['message'] as String?));
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
  final String? uid;
  final String? email;
  final String? error;

  const AuthResult._({
    required this.ok,
    this.idToken,
    this.uid,
    this.email,
    this.error,
  });

  factory AuthResult.ok({
    required String idToken,
    required String uid,
    required String email,
  }) =>
      AuthResult._(ok: true, idToken: idToken, uid: uid, email: email);

  factory AuthResult.err(String error) =>
      AuthResult._(ok: false, error: error);
}
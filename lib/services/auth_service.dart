import 'dart:convert';
import 'package:http/http.dart' as http;

/// Wrapper peste Firebase Auth REST API
/// Identic cu logica din Login.cs / SignUp.cs (C# WPF)
class AuthService {
  // !! Înlocuiește cu valorile din Firebase Console
  static const String _apiKey = 'YOUR_FIREBASE_API_KEY';
  static const String _dbUrl  = 'YOUR_REALTIME_DB_URL';
  // ex: 'https://astrolab-default-rtdb.firebaseio.com'

  static const _signInUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword';
  static const _signUpUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp';
  static const _resetUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode';

  /// Autentificare email + parolă  [Login.cs → LoginButton_Click]
  static Future<AuthResult> signIn(String email, String password) =>
      _call(_signInUrl, {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      });

  /// Înregistrare email + parolă  [SignUp.cs → SignUpButton_Click]
  static Future<AuthResult> signUp(String email, String password) =>
      _call(_signUpUrl, {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      });

  /// Resetare parolă  [Login.cs → ForgotPasswordLink_Click]
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

  /// Verifică dacă userul trebuie să completeze profilul
  /// [Login.cs → CheckNeedsProfileSetup]
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

  /// Traducere coduri eroare Firebase → mesaje în română
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

  // ── internal ──────────────────────────────────────────────────────────────
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

class AuthResult {
  final bool    ok;
  final String? idToken;
  final String? uid;
  final String? email;
  final String? error;

  const AuthResult._({required this.ok, this.idToken, this.uid,
    this.email, this.error});

  factory AuthResult.ok({
    required String idToken,
    required String uid,
    required String email,
  }) => AuthResult._(ok: true, idToken: idToken, uid: uid, email: email);

  factory AuthResult.err(String error) =>
      AuthResult._(ok: false, error: error);
}
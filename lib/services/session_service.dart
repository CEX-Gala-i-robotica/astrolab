import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _kRememberMe = 'remember_me';
  static const _kEmail = 'email';
  static const _kIdToken = 'id_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kUid = 'uid';
  static const _kLoggedIn = 'logged_in';
  static const _kFirstName = 'first_name';
  static const _kLastName = 'last_name';
  static const _kUsername = 'username';
  static const _kBirthDate = 'birth_date';
  static const _kPhone = 'phone';
  static const _kClassValue = 'class_value';
  static const _kAstronomyLevel = 'astronomy_level';

  static Future<void> save({
    required String email,
    required String idToken,
    required String uid,
    required bool rememberMe,
    String refreshToken = '',
    String firstName = '',
    String lastName = '',
    String username = '',
    String birthDate = '',
    String phone = '',
    String classValue = '5',
    String astronomyLevel = 'beginner',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRememberMe, rememberMe);
    await prefs.setString(_kEmail, rememberMe ? email : '');
    await prefs.setString(_kIdToken, rememberMe ? idToken : '');
    await prefs.setString(_kRefreshToken, rememberMe ? refreshToken : '');
    await prefs.setString(_kUid, rememberMe ? uid : '');
    await prefs.setBool(_kLoggedIn, true);
    await prefs.setString(_kFirstName, firstName);
    await prefs.setString(_kLastName, lastName);
    await prefs.setString(_kUsername, username);
    await prefs.setString(_kBirthDate, birthDate);
    await prefs.setString(_kPhone, phone);
    await prefs.setString(_kClassValue, classValue);
    await prefs.setString(_kAstronomyLevel, astronomyLevel);
  }

  static Future<SavedSession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SavedSession(
      rememberMe: prefs.getBool(_kRememberMe) ?? false,
      email: prefs.getString(_kEmail) ?? '',
      idToken: prefs.getString(_kIdToken) ?? '',
      refreshToken: prefs.getString(_kRefreshToken) ?? '',
      uid: prefs.getString(_kUid) ?? '',
      loggedIn: prefs.getBool(_kLoggedIn) ?? false,
      firstName: prefs.getString(_kFirstName) ?? '',
      lastName: prefs.getString(_kLastName) ?? '',
      username: prefs.getString(_kUsername) ?? '',
      birthDate: prefs.getString(_kBirthDate) ?? '',
      phone: prefs.getString(_kPhone) ?? '',
      classValue: prefs.getString(_kClassValue) ?? '5',
      astronomyLevel: prefs.getString(_kAstronomyLevel) ?? 'beginner',
    );
  }

  static Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String username,
    required String birthDate,
    required String phone,
    required String classValue,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFirstName, firstName);
    await prefs.setString(_kLastName, lastName);
    await prefs.setString(_kUsername, username);
    await prefs.setString(_kBirthDate, birthDate);
    await prefs.setString(_kPhone, phone);
    await prefs.setString(_kClassValue, classValue);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRememberMe);
    await prefs.remove(_kEmail);
    await prefs.remove(_kIdToken);
    await prefs.remove(_kRefreshToken);
    await prefs.remove(_kUid);
    await prefs.setBool(_kLoggedIn, false);
    await prefs.remove(_kFirstName);
    await prefs.remove(_kLastName);
    await prefs.remove(_kUsername);
    await prefs.remove(_kBirthDate);
    await prefs.remove(_kPhone);
    await prefs.remove(_kClassValue);
    await prefs.remove(_kAstronomyLevel);
  }
}

class SavedSession {
  final bool rememberMe;
  final String email;
  final String idToken;
  final String refreshToken;
  final String uid;
  final bool loggedIn;
  final String firstName;
  final String lastName;
  final String username;
  final String birthDate;
  final String phone;
  final String classValue;
  final String astronomyLevel;

  // Alias so ProfileEditScreen can use session.token
  String get token => idToken;

  const SavedSession({
    required this.rememberMe,
    required this.email,
    required this.idToken,
    required this.refreshToken,
    required this.uid,
    required this.loggedIn,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.birthDate,
    required this.phone,
    required this.classValue,
    required this.astronomyLevel,
  });
}
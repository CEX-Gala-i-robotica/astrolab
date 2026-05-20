import 'dart:convert';

import 'package:http/http.dart' as http;

class AstronomyObserver {
  final String latitude;
  final String longitude;
  final String elevation;
  final String fromDate;
  final String toDate;
  final String time;

  const AstronomyObserver({
    required this.latitude,
    required this.longitude,
    required this.elevation,
    required this.fromDate,
    required this.toDate,
    required this.time,
  });

  Map<String, String> toQuery({String output = 'rows'}) => {
    'latitude': latitude,
    'longitude': longitude,
    'elevation': elevation,
    'from_date': fromDate,
    'to_date': toDate,
    'time': time,
    'output': output,
  };

  Map<String, dynamic> toStudioObserver() => {
    'latitude': double.tryParse(latitude) ?? 0,
    'longitude': double.tryParse(longitude) ?? 0,
    'date': fromDate,
  };
}

class AstronomyApiService {
  static const _baseUrl = 'https://api.astronomyapi.com/api/v2';
  static const _appId = String.fromEnvironment('ASTRONOMY_API_APP_ID');
  static const _appSecret = String.fromEnvironment('ASTRONOMY_API_APP_SECRET');

  bool get isConfigured => _appId.isNotEmpty && _appSecret.isNotEmpty;

  Map<String, String> get _headers {
    final token = base64Encode(utf8.encode('$_appId:$_appSecret'));
    return {
      'Authorization': 'Basic $token',
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> getAllPositions(AstronomyObserver observer) {
    return _get('/bodies/positions', observer.toQuery());
  }

  Future<Map<String, dynamic>> getBodyPositions({
    required String body,
    required AstronomyObserver observer,
  }) {
    return _get('/bodies/positions/$body', observer.toQuery());
  }

  Future<Map<String, dynamic>> getEvents({
    required String body,
    required AstronomyObserver observer,
  }) {
    return _get('/bodies/events/$body', observer.toQuery());
  }

  Future<Map<String, dynamic>> search({
    required String term,
    int limit = 8,
    int offset = 0,
  }) {
    return _get('/search', {
      'term': term,
      'match_type': 'fuzzy',
      'limit': '$limit',
      'offset': '$offset',
      'order_by': 'name',
    });
  }

  Future<String> createStarChart({
    required AstronomyObserver observer,
    required String constellation,
    String style = 'navy',
  }) async {
    final data = await _post('/studio/star-chart', {
      'style': style,
      'observer': observer.toStudioObserver(),
      'view': {
        'type': 'constellation',
        'parameters': {'constellation': constellation},
      },
    });
    return data['data']?['imageUrl'] as String? ?? '';
  }

  Future<String> createMoonPhase({
    required AstronomyObserver observer,
    String format = 'png',
  }) async {
    final data = await _post('/studio/moon-phase', {
      'format': format,
      'style': {
        'moonStyle': 'shaded',
        'backgroundStyle': 'stars',
        'backgroundColor': '#020A12',
        'headingColor': 'white',
        'textColor': '#B0C4D8',
      },
      'observer': observer.toStudioObserver(),
      'view': {'type': 'portrait-simple'},
    });
    return data['data']?['imageUrl'] as String? ?? '';
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> query,
  ) async {
    _ensureConfigured();
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    final response = await http.get(uri, headers: _headers);
    return _decode(response);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    _ensureConfigured();
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(decoded as Map);
    }
    final message = decoded is Map && decoded['errors'] is List
        ? (decoded['errors'] as List)
              .map((error) => error is Map ? error['message'] : error)
              .join('\n')
        : decoded.toString();
    throw AstronomyApiException(
      'AstronomyAPI a raspuns cu ${response.statusCode}: $message',
    );
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw const AstronomyApiException(
        'Lipsesc ASTRONOMY_API_APP_ID sau ASTRONOMY_API_APP_SECRET din .env.',
      );
    }
  }
}

class AstronomyApiException implements Exception {
  final String message;
  const AstronomyApiException(this.message);

  @override
  String toString() => message;
}

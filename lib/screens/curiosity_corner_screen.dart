import 'package:flutter/material.dart';

import '../services/astronomy_api_service.dart';
import '../theme/app_theme.dart';

class CuriosityCornerScreen extends StatefulWidget {
  const CuriosityCornerScreen({super.key});

  @override
  State<CuriosityCornerScreen> createState() => _CuriosityCornerScreenState();
}

class _CuriosityCornerScreenState extends State<CuriosityCornerScreen> {
  final _api = AstronomyApiService();
  final _latitude = TextEditingController(text: '44.4268');
  final _longitude = TextEditingController(text: '26.1025');
  final _elevation = TextEditingController(text: '85');
  final _fromDate = TextEditingController();
  final _toDate = TextEditingController();
  final _time = TextEditingController(text: '22:00:00');
  final _search = TextEditingController(text: 'Orion');

  String _selectedBody = 'moon';
  String _eventBody = 'moon';
  String _constellation = 'ori';
  String _chartStyle = 'navy';
  String? _busy;
  String? _error;
  String? _moonImageUrl;
  String? _starChartUrl;
  List<dynamic> _allPositionRows = const [];
  List<dynamic> _bodyPositionRows = const [];
  List<dynamic> _eventRows = const [];
  bool _eventSearchDone = false;
  List<dynamic> _searchRows = const [];

  static const _bodies = {
    'sun': 'Soare',
    'moon': 'Luna',
    'mercury': 'Mercur',
    'venus': 'Venus',
    'mars': 'Marte',
    'jupiter': 'Jupiter',
    'saturn': 'Saturn',
    'uranus': 'Uranus',
    'neptune': 'Neptun',
    'pluto': 'Pluto',
  };

  static const _constellations = {
    'ori': 'Orion',
    'uma': 'Ursa Major',
    'cas': 'Cassiopeia',
    'lyr': 'Lyra',
    'cyg': 'Cygnus',
    'sco': 'Scorpius',
    'sgr': 'Sagittarius',
    'tau': 'Taurus',
    'leo': 'Leo',
    'and': 'Andromeda',
  };

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final date = _formatDate(today);
    _fromDate.text = date;
    _toDate.text = date;
  }

  @override
  void dispose() {
    _latitude.dispose();
    _longitude.dispose();
    _elevation.dispose();
    _fromDate.dispose();
    _toDate.dispose();
    _time.dispose();
    _search.dispose();
    super.dispose();
  }

  AstronomyObserver get _observer => AstronomyObserver(
    latitude: _latitude.text.trim(),
    longitude: _longitude.text.trim(),
    elevation: _elevation.text.trim(),
    fromDate: _fromDate.text.trim(),
    toDate: _toDate.text.trim(),
    time: _time.text.trim(),
  );

  Future<void> _run(String label, Future<void> Function() action) async {
    setState(() {
      _busy = label;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _loadAllPositions() async {
    await _run('positions', () async {
      final response = await _api.getAllPositions(_observer);
      final data = response['data'] as Map<String, dynamic>? ?? {};
      setState(() => _allPositionRows = _extractRows(data));
    });
  }

  Future<void> _loadBodyPositions() async {
    await _run('body', () async {
      final response = await _api.getBodyPositions(
        body: _selectedBody,
        observer: _observer,
      );
      final data = response['data'] as Map<String, dynamic>? ?? {};
      setState(() => _bodyPositionRows = _extractRows(data));
    });
  }

  Future<void> _loadEvents() async {
    await _run('events', () async {
      final response = await _api.getEvents(
        body: _eventBody,
        observer: _observer,
      );
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final rows = _extractRows(data).where(_hasEvents).toList();
      setState(() {
        _eventRows = rows;
        _eventSearchDone = true;
      });
    });
  }

  Future<void> _runSearch() async {
    final term = _search.text.trim();
    if (term.isEmpty) return;
    await _run('search', () async {
      final response = await _api.search(term: term);
      setState(() => _searchRows = response['data'] as List<dynamic>? ?? []);
    });
  }

  Future<void> _createMoonPhase() async {
    await _run('moon', () async {
      final url = await _api.createMoonPhase(observer: _observer);
      setState(() => _moonImageUrl = url);
    });
  }

  Future<void> _createStarChart() async {
    await _run('chart', () async {
      final url = await _api.createStarChart(
        observer: _observer,
        constellation: _constellation,
        style: _chartStyle,
      );
      setState(() => _starChartUrl = url);
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;
    final hPad = width < 600 ? 16.0 : 32.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Header(),
              const SizedBox(height: 18),
              if (!_api.isConfigured) _configurationNotice(),
              if (_error != null) ...[
                _StatusBanner(message: _error!, isError: true),
                const SizedBox(height: 14),
              ],
              _observerPanel(),
              const SizedBox(height: 18),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _positionsPanel()),
                    const SizedBox(width: 18),
                    Expanded(child: _eventsPanel()),
                  ],
                )
              else ...[
                _positionsPanel(),
                const SizedBox(height: 18),
                _eventsPanel(),
              ],
              const SizedBox(height: 18),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _searchPanel()),
                    const SizedBox(width: 18),
                    Expanded(child: _studioPanel()),
                  ],
                )
              else ...[
                _searchPanel(),
                const SizedBox(height: 18),
                _studioPanel(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _configurationNotice() => _StatusBanner(
    isError: true,
    message:
        'Adauga in .env ASTRONOMY_API_APP_ID si ASTRONOMY_API_APP_SECRET, apoi porneste aplicatia prin debug.ps1.',
  );

  Widget _observerPanel() => _Panel(
    title: 'Observator',
    icon: Icons.explore_rounded,
    child: Wrap(
      runSpacing: 12,
      spacing: 12,
      children: [
        _field(_latitude, 'Latitudine', width: 130),
        _field(_longitude, 'Longitudine', width: 130),
        _field(_elevation, 'Elevatie m', width: 120),
        _field(_fromDate, 'De la', width: 130),
        _field(_toDate, 'Pana la', width: 130),
        _field(_time, 'Ora', width: 120),
      ],
    ),
  );

  Widget _positionsPanel() => _Panel(
    title: 'Pozitii pe cer',
    icon: Icons.public_rounded,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 170,
              child: _dropdown(
                value: _selectedBody,
                label: 'Corp',
                items: _bodies,
                onChanged: (value) => setState(() => _selectedBody = value),
              ),
            ),
            _button(
              label: 'Corp selectat',
              icon: Icons.my_location_rounded,
              busyKey: 'body',
              onPressed: _loadBodyPositions,
            ),
            _button(
              label: 'Toate corpurile',
              icon: Icons.travel_explore_rounded,
              busyKey: 'positions',
              onPressed: _loadAllPositions,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_bodyPositionRows.isNotEmpty) ...[
          _miniTitle('Rezultat pentru ${_bodies[_selectedBody]}'),
          ..._positionTiles(_bodyPositionRows).take(4),
        ],
        if (_allPositionRows.isNotEmpty) ...[
          _miniTitle('Panorama sistemului solar'),
          ..._positionTiles(_allPositionRows).take(10),
        ],
        if (_bodyPositionRows.isEmpty && _allPositionRows.isEmpty)
          _empty('Alege un corp sau incarca toate pozitiile.'),
      ],
    ),
  );

  Widget _eventsPanel() => _Panel(
    title: 'Eclipse',
    icon: Icons.event_available_rounded,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 170,
              child: _dropdown(
                value: _eventBody,
                label: 'Corp',
                items: const {'sun': 'Soare', 'moon': 'Luna'},
                onChanged: (value) => setState(() => _eventBody = value),
              ),
            ),
            _button(
              label: 'Cauta eclipse',
              icon: Icons.wb_twilight_rounded,
              busyKey: 'events',
              onPressed: _loadEvents,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!_eventSearchDone)
          _empty('Eclipsele sunt disponibile pentru Soare si Luna.')
        else if (_eventSearchDone && _busy != 'events' && _eventRows.isEmpty)
          const _StatusBanner(
            message: 'Nu sunt eclipse in intervalul selectat.',
            isError: true,
          )
        else
          ..._eventTiles(_eventRows),
      ],
    ),
  );

  Widget _searchPanel() => _Panel(
    title: 'Cautare stele',
    icon: Icons.search_rounded,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _field(_search, 'Termen', width: 220),
            _button(
              label: 'Cauta',
              icon: Icons.manage_search_rounded,
              busyKey: 'search',
              onPressed: _runSearch,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._searchRows.map(_searchTile),
        if (_searchRows.isEmpty) _empty('Exemple: Orion, M 42, Vega sau M 31.'),
      ],
    ),
  );

  Widget _studioPanel() => _Panel(
    title: 'Studio vizual',
    icon: Icons.auto_awesome_rounded,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 180,
              child: _dropdown(
                value: _constellation,
                label: 'Constelatie',
                items: _constellations,
                onChanged: (value) => setState(() => _constellation = value),
              ),
            ),
            SizedBox(
              width: 130,
              child: _dropdown(
                value: _chartStyle,
                label: 'Stil',
                items: const {
                  'default': 'Default',
                  'inverted': 'Inverted',
                  'navy': 'Navy',
                  'red': 'Red',
                },
                onChanged: (value) => setState(() => _chartStyle = value),
              ),
            ),
            _button(
              label: 'Harta stelara',
              icon: Icons.map_rounded,
              busyKey: 'chart',
              onPressed: _createStarChart,
            ),
            _button(
              label: 'Faza Lunii',
              icon: Icons.nightlight_round,
              busyKey: 'moon',
              onPressed: _createMoonPhase,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_starChartUrl != null)
          _imageResult('Harta constelatiei', _starChartUrl!),
        if (_moonImageUrl != null) _imageResult('Faza Lunii', _moonImageUrl!),
        if (_starChartUrl == null && _moonImageUrl == null)
          _empty(
            'Genereaza imagini cu ajutorul cărora să înveți mai ușor astronomie.',
          ),
      ],
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.background.withOpacity(0.55),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.16)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.55)),
          ),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required String label,
    required Map<String, String> items,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: AppColors.surfaceLight,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.background.withOpacity(0.55),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.55)),
        ),
      ),
      items: items.entries
          .map(
            (entry) =>
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

  Widget _button({
    required String label,
    required IconData icon,
    required String busyKey,
    required VoidCallback onPressed,
  }) {
    final busy = _busy == busyKey;
    return ElevatedButton.icon(
      onPressed: _busy == null && _api.isConfigured ? onPressed : null,
      icon: busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Iterable<Widget> _positionTiles(List<dynamic> rows) sync* {
    for (final row in rows) {
      if (row is! Map) continue;
      final body = row['body'] ?? row['entry'] ?? {};
      final positions = row['positions'] ?? row['cells'] ?? const [];
      if (positions is! List || positions.isEmpty || positions.first is! Map) {
        continue;
      }
      yield _PositionTile(
        name: _text(body, 'name', fallback: _text(positions.first, 'name')),
        date: _text(positions.first, 'date'),
        altitude: _nested(positions.first, [
          'position',
          'horizontal',
          'altitude',
          'degrees',
        ]),
        azimuth: _nested(positions.first, [
          'position',
          'horizontal',
          'azimuth',
          'degrees',
        ]),
        constellation: _nested(positions.first, [
          'position',
          'constellation',
          'name',
        ]),
        magnitude: _nested(positions.first, ['extraInfo', 'magnitude']),
      );
    }
  }

  Iterable<Widget> _eventTiles(List<dynamic> rows) sync* {
    for (final row in rows) {
      if (row is! Map) continue;
      final events = row['events'] ?? row['cells'] ?? const [];
      if (events is! List || events.isEmpty) continue;
      for (final event in events) {
        if (event is! Map) continue;
        yield _DataTile(
          icon: Icons.flare_rounded,
          title: _eventName(_text(event, 'type')),
          lines: [
            'Varf: ${_nested(event, ['eventHighlights', 'peak', 'date'], fallback: '-')}',
            'Altitudine: ${_nested(event, ['eventHighlights', 'peak', 'altitude'], fallback: '-')}',
            'Obscurare: ${_nested(event, ['extraInfo', 'obscuration'], fallback: '-')}',
          ],
        );
      }
    }
  }

  Widget _searchTile(dynamic item) {
    if (item is! Map) return const SizedBox.shrink();
    final crossIds = item['crossIdentification'];
    final aliases = crossIds is List
        ? crossIds
              .whereType<Map>()
              .map((entry) => entry['name'])
              .whereType<String>()
              .take(3)
              .join(', ')
        : '';
    return _DataTile(
      icon: Icons.blur_on_rounded,
      title: _text(item, 'name'),
      lines: [
        'Tip: ${_nested(item, ['type', 'name'])}',
        'Constelatie: ${_nested(item, ['position', 'constellation', 'name'])}',
        'RA/Dec: ${_nested(item, ['position', 'equatorial', 'rightAscension', 'string'])} / ${_nested(item, ['position', 'equatorial', 'declination', 'string'])}',
        if (aliases.isNotEmpty) 'Alias: $aliases',
      ],
    );
  }

  Widget _imageResult(String title, String url) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _miniTitle(title),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (_, __, ___) =>
                _empty('Imaginea nu s-a putut incarca.'),
          ),
        ),
      ],
    ),
  );

  Widget _miniTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _empty(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Text(
      text,
      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
    ),
  );

  List<dynamic> _extractRows(Map<String, dynamic> data) {
    final rows = data['rows'];
    if (rows is List) return rows;
    final table = data['table'];
    if (table is Map && table['rows'] is List) return table['rows'] as List;
    return const [];
  }

  static bool _hasEvents(dynamic row) {
    if (row is! Map) return false;
    final events = row['events'] ?? row['cells'] ?? const [];
    return events is List && events.whereType<Map>().isNotEmpty;
  }

  static String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  static String _text(dynamic map, String key, {String fallback = '-'}) {
    if (map is Map && map[key] != null) return map[key].toString();
    return fallback;
  }

  static String _nested(
    dynamic map,
    List<String> keys, {
    String fallback = '-',
  }) {
    dynamic current = map;
    for (final key in keys) {
      if (current is! Map || current[key] == null) return fallback;
      current = current[key];
    }
    return current.toString();
  }

  static String _eventName(String value) {
    if (value == '-') return 'Eveniment';
    return value
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
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
              Icons.psychology_alt_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Colțul curioșilor',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Pozitii astronomice, eclipse, cautare planete si imagini generate.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
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

class _PositionTile extends StatelessWidget {
  final String name;
  final String date;
  final String altitude;
  final String azimuth;
  final String constellation;
  final String magnitude;

  const _PositionTile({
    required this.name,
    required this.date,
    required this.altitude,
    required this.azimuth,
    required this.constellation,
    required this.magnitude,
  });

  @override
  Widget build(BuildContext context) {
    return _DataTile(
      icon: Icons.radio_button_checked_rounded,
      title: name,
      lines: [
        date,
        'Alt/Az: $altitude / $azimuth',
        'Constelatie: $constellation',
        'Magnitudine: $magnitude',
      ],
    );
  }
}

class _DataTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> lines;

  const _DataTile({
    required this.icon,
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.42),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.secondary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                ...lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      line,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const _StatusBanner({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.redAccent : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

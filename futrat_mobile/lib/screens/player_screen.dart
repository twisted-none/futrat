import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth_gate.dart';
import '../core/profile_api.dart';
import '../core/active_season.dart';
import '../models/all_models.dart';
import '../providers/data_provider.dart';
import '../widgets/match_tile.dart';

class PlayerScreen extends StatefulWidget {
  final int playerId;
  final ProfileApi? api;
  const PlayerScreen({super.key, required this.playerId, this.api});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final ProfileApi _api = widget.api ?? ProfileApi();
  Map<String, dynamic>? _player, _coverage;
  List<Map<String, dynamic>> _matches = [];
  List<MatchModel> _upcoming = [];
  bool _calendar = false;
  bool _loading = true, _more = false, _busy = false;
  String _kind = 'all';
  final int _season = activeSeason;
  int _generation = 0;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await Future.wait([
        _api.player(widget.playerId),
        _api.playerMatches(widget.playerId, season: _season, kind: _kind),
      ]);
      if (!mounted || generation != _generation) return;
      setState(() {
        _player = data[0];
        _coverage = Map<String, dynamic>.from(data[1]['coverage']);
        _calendar = data[1]['calendar_season'] ?? false;
        _upcoming = ((data[1]['upcoming'] ?? []) as List)
            .map((row) => MatchModel.fromJson(Map<String, dynamic>.from(row)))
            .toList();
        _matches = (data[1]['matches'] as List)
            .map((r) => Map<String, dynamic>.from(r))
            .toList();
        _more = data[1]['more'];
      });
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _error = 'Не удалось загрузить профиль');
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _next() async {
    if (_busy) return;
    setState(() => _busy = true);
    final generation = _generation;
    try {
      final data = await _api.playerMatches(
        widget.playerId,
        season: _season,
        kind: _kind,
        offset: _matches.length,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _matches.addAll(
          (data['matches'] as List).map((r) => Map<String, dynamic>.from(r)),
        );
        _more = data['more'];
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось загрузить продолжение')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final id = (_player?['id'] as int?) ?? widget.playerId;
    final favorite = data.isPlayerFavorite(id);
    return Scaffold(
      appBar: AppBar(
        title: Text(_player?['name'] ?? 'Игрок'),
        actions: [
          IconButton(
            tooltip: favorite ? 'Убрать из избранного' : 'В избранное',
            icon: Icon(favorite ? Icons.star : Icons.star_border),
            onPressed: () => runAuthenticatedAction(
              context,
              action: 'добавить игрока в избранное',
              onAuthenticated: (resumed) async {
                if (resumed && data.isPlayerFavorite(id)) return;
                await data.togglePlayerFavorite(id);
              },
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: TextButton(
                onPressed: _load,
                child: Text('$_error · Повторить'),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Center(
                            child: PlayerPhoto(
                              url: _player?['photo_url'],
                              size: 82,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(seasonLabel(_calendar)),
                          const SizedBox(height: 12),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'all', label: Text('Все')),
                              ButtonSegment(value: 'club', label: Text('Клуб')),
                              ButtonSegment(
                                value: 'national',
                                label: Text('Сборная'),
                              ),
                            ],
                            selected: {_kind},
                            onSelectionChanged: (values) {
                              setState(() => _kind = values.first);
                              _load();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_coverage?['status'] != 'ready')
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'История дополняется: проверено ${_coverage?['checked'] ?? 0} из ${_coverage?['candidates'] ?? 0} матчей команд. Показаны подтверждённые участия.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  if (_matches.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Подтверждённых участий пока нет',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ..._matches.map((row) {
                    final match = MatchModel.fromJson(
                      Map<String, dynamic>.from(row['match']),
                    );
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PlayerPhoto(url: row['photo_url'], size: 42),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MatchTile(match: match),
                                  Text(
                                    'Голы: ${row['goals'] ?? '—'} · Передачи: ${row['assists'] ?? '—'} · Минуты: ${row['minutes'] ?? '—'}',
                                  ),
                                  Text(
                                    "${row['user_rating'] ?? '—'} · ${row['rating_count'] ?? 0} голосов",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (_more)
                    TextButton(
                      onPressed: _busy ? null : _next,
                      child: const Text('Загрузить ещё'),
                    ),
                  if (!_more && _upcoming.isNotEmpty && _kind == 'all') ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Возможное участие · составы ещё не подтверждены',
                      ),
                    ),
                    ..._upcoming.map((match) => MatchTile(match: match)),
                  ],
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth_gate.dart';
import '../core/profile_api.dart';
import '../core/active_season.dart';
import '../models/all_models.dart';
import '../providers/data_provider.dart';
import '../widgets/match_tile.dart';
import '../widgets/match_summary.dart';
import '../widgets/app_states.dart';

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
      _loading = _player == null;
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
          ? const AppSkeleton(
              layout: LoadingLayout.profile,
              label: 'Загрузка профиля игрока',
            )
          : _error != null && _player == null
          ? AppEmptyState(
              title: _error!,
              icon: Icons.wifi_off_outlined,
              actionLabel: 'Повторить',
              onAction: _load,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                key: PageStorageKey('player-${widget.playerId}-$_kind'),
                padding: const EdgeInsets.all(12),
                children: [
                  if (_error != null)
                    UpdateNotice(message: _error!, onRetry: _load),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              PlayerPhoto(url: _player?['photo_url'], size: 48),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  seasonLabel(_calendar),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final option in const [
                                ('all', 'Все'),
                                ('club', 'Клуб'),
                                ('national', 'Сборная'),
                              ])
                                ChoiceChip(
                                  label: Text(option.$2),
                                  selected: _kind == option.$1,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _kind = option.$1);
                                      _load();
                                    }
                                  },
                                ),
                            ],
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
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PlayerPhoto(url: row['photo_url'], size: 36),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Голы: ${row['goals'] ?? '—'} · Передачи: ${row['assists'] ?? '—'} · Минуты: ${row['minutes'] ?? '—'}',
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${row['user_rating'] ?? '—'} · Оценок: ${row['rating_count'] ?? 0}',
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
                          const Divider(height: 1, indent: 14, endIndent: 14),
                          MatchSummary(
                            match: match,
                            linkTeams: true,
                            showTournament: true,
                          ),
                        ],
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

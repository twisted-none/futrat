import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth_gate.dart';
import '../core/profile_api.dart';
import '../core/active_season.dart';
import '../models/all_models.dart';
import '../providers/data_provider.dart';
import '../widgets/match_tile.dart';

class TeamScreen extends StatefulWidget {
  final int teamId;
  final String? name;
  final ProfileApi? api;
  const TeamScreen({super.key, required this.teamId, this.name, this.api});
  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  late final ProfileApi _api = widget.api ?? ProfileApi();
  final ScrollController _scroll = ScrollController();
  final Key _center = const ValueKey('latest-game');
  bool _loading = true, _morePast = false, _moreFuture = false, _busy = false;
  bool _calendar = false;
  String? _error, _name;
  final int _season = activeSeason;
  MatchModel? _anchor;
  List<MatchModel> _past = [], _future = [];
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List<MatchModel> _parse(dynamic rows) => (rows as List)
      .map((r) => MatchModel.fromJson(Map<String, dynamic>.from(r)))
      .toList();
  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.team(widget.teamId, season: _season);
      if (!mounted || generation != _generation) return;
      setState(() {
        _name = data['team']['name'];
        _calendar = data['calendar_season'] ?? false;
        _anchor = data['anchor'] == null
            ? null
            : MatchModel.fromJson(Map<String, dynamic>.from(data['anchor']));
        _past = _parse(data['past']);
        _future = _parse(data['future']);
        _morePast = data['more_past'];
        _moreFuture = data['more_future'];
      });
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _error = 'Не удалось загрузить матчи');
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _more(bool past) async {
    if (_busy || _anchor == null) return;
    final generation = _generation;
    setState(() => _busy = true);
    try {
      final cursor = past
          ? (_past.isEmpty ? _anchor! : _past.last)
          : (_future.isEmpty ? _anchor! : _future.last);
      final data = await _api.team(
        widget.teamId,
        season: _season,
        cursor: cursor.id,
        direction: past ? 'past' : 'future',
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        if (past) {
          _past.addAll(_parse(data['matches']));
          _morePast = data['more'];
        } else {
          _future.addAll(_parse(data['matches']));
          _moreFuture = data['more'];
        }
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
    final favorite = data.isTeamFavorite(widget.teamId);
    return Scaffold(
      appBar: AppBar(
        title: Text(_name ?? widget.name ?? 'Команда'),
        actions: [
          IconButton(
            tooltip: favorite ? 'Убрать из избранного' : 'В избранное',
            icon: Icon(favorite ? Icons.star : Icons.star_border),
            onPressed: () => runAuthenticatedAction(
              context,
              action: 'добавить команду в избранное',
              onAuthenticated: (resumed) async {
                if (resumed && data.isTeamFavorite(widget.teamId)) return;
                await data.toggleTeamFavorite(widget.teamId);
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: Text(seasonLabel(_calendar))),
                const Text('Все турниры'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: TextButton(
                      onPressed: _load,
                      child: Text('$_error · Повторить'),
                    ),
                  )
                : _anchor == null
                ? const Center(child: Text('Нет матчей в этом сезоне'))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: CustomScrollView(
                      key: ValueKey(_season),
                      controller: _scroll,
                      center: _center,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            if (index == _past.length) {
                              return TextButton(
                                onPressed: _busy ? null : () => _more(true),
                                child: const Text('Более ранние матчи'),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: MatchTile(match: _past[index]),
                            );
                          }, childCount: _past.length + (_morePast ? 1 : 0)),
                        ),
                        SliverList(
                          key: _center,
                          delegate: SliverChildListDelegate([
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Text(
                                _anchor!.status == 'FINISHED'
                                    ? 'Последняя сыгранная встреча'
                                    : 'Ближайшая встреча',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: MatchTile(match: _anchor!),
                            ),
                            if (_future.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.fromLTRB(16, 18, 16, 4),
                                child: Text('Расписание'),
                              ),
                            ..._future.map(
                              (m) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: MatchTile(match: m),
                              ),
                            ),
                            if (_moreFuture)
                              TextButton(
                                onPressed: _busy ? null : () => _more(false),
                                child: const Text('Следующие матчи'),
                              ),
                            const SizedBox(height: 85),
                          ]),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _anchor == null
          ? null
          : FloatingActionButton.small(
              tooltip: 'К последней игре',
              onPressed: () {
                if (_scroll.hasClients) {
                  _scroll.animateTo(
                    0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                }
              },
              child: const Icon(Icons.my_location),
            ),
    );
  }
}

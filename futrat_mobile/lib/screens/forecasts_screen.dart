import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/auth_gate.dart';
import '../core/forecast_api.dart';
import '../models/all_models.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import 'match_detail_screen.dart';

DateTime moscowTime(DateTime date) =>
    date.toUtc().add(const Duration(hours: 3));
String moscowDay(DateTime date) =>
    DateFormat('yyyy-MM-dd').format(moscowTime(date));

class ForecastsScreen extends StatefulWidget {
  final ForecastApi? api;
  const ForecastsScreen({super.key, this.api});
  @override
  State<ForecastsScreen> createState() => _ForecastsScreenState();
}

class _ForecastsScreenState extends State<ForecastsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  late final ForecastApi _api = widget.api ?? ForecastApi();
  String _day = moscowDay(DateTime.now());
  String? _month = DateFormat('yyyy-MM').format(moscowTime(DateTime.now()));
  int _tab = 0, _used = 0, _generation = 0, _rankTotal = 0;
  bool _loading = true, _busy = false, _historyMore = false;
  bool _favoritesOnly = false;
  String? _error;
  List<Map<String, dynamic>> _choices = [], _history = [], _ranks = [];
  Map<String, dynamic>? _myRank;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final signedIn = context.read<AuthProvider>().isAuthenticated;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_tab == 0) {
        final results = signedIn
            ? await Future.wait([_api.mine(day: _day), _api.used(_day)])
            : [<Map<String, dynamic>>[], 0];
        if (!mounted || generation != _generation) return;
        setState(() {
          _choices = results[0] as List<Map<String, dynamic>>;
          _used = results[1] as int;
        });
      } else if (_tab == 1) {
        final rows = signedIn ? await _api.mine() : <Map<String, dynamic>>[];
        if (!mounted || generation != _generation) return;
        setState(() {
          _history = rows;
          _historyMore = rows.length == 100;
        });
      } else {
        final results = await Future.wait([
          _api.rankings(month: _month),
          signedIn ? _api.myRank(month: _month) : Future.value(null),
        ]);
        if (!mounted || generation != _generation) return;
        final board = results[0]!;
        setState(() {
          _ranks = (board['rows'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _rankTotal = board['total'];
          _myRank = results[1];
        });
      }
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _error = _message(error));
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  String _message(Object error) {
    if (error is DioException && error.response?.data is Map) {
      final detail = error.response?.data['detail'];
      if (detail is String) return detail;
    }
    return 'Не удалось получить данные. Попробуйте ещё раз.';
  }

  Future<void> _moreRows(bool rankings) async {
    if (_busy) return;
    final generation = _generation;
    setState(() => _busy = true);
    try {
      if (rankings) {
        final data = await _api.rankings(month: _month, offset: _ranks.length);
        if (!mounted || generation != _generation) return;
        setState(
          () => _ranks.addAll(
            (data['rows'] as List).map((r) => Map<String, dynamic>.from(r)),
          ),
        );
      } else {
        final rows = await _api.mine(offset: _history.length);
        if (!mounted || generation != _generation) return;
        setState(() {
          _history.addAll(rows);
          _historyMore = rows.length == 100;
        });
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(error))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choose(MatchModel match, String outcome) async {
    if (_busy) return;
    await runAuthenticatedAction(
      context,
      action: 'сделать прогноз',
      onAuthenticated: (_) async {
        if (!mounted) return;
        setState(() => _busy = true);
        try {
          await _api.choose(match.id, outcome);
          if (mounted) await _load();
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(_message(error))));
          }
        } finally {
          if (mounted) setState(() => _busy = false);
        }
      },
    );
  }

  Future<void> _cancel(int id) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _api.cancel(id);
      if (mounted) await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final signedIn = context.watch<AuthProvider>().isAuthenticated;
    final matches =
        data.allMatches
            .where(
              (m) =>
                  moscowDay(m.dateTime) == _day &&
                  m.status == 'SCHEDULED' &&
                  m.dateTime.isAfter(DateTime.now()) &&
                  (!_favoritesOnly ||
                      data.isTeamFavorite(m.homeTeam.id) ||
                      data.isTeamFavorite(m.awayTeam.id) ||
                      data.isLeagueFavorite(m.tournament.id)),
            )
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Прогнозы'),
          bottom: TabBar(
            controller: _tabs,
            onTap: (tab) {
              setState(() => _tab = tab);
              _load();
            },
            tabs: const [
              Tab(text: 'Матчи'),
              Tab(text: 'Мои прогнозы'),
              Tab(text: 'Рейтинг'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (_tab == 0)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Предыдущая дата',
                            onPressed: () => _shift(-1),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: _pickDate,
                              child: Text(
                                '${DateFormat('dd.MM.yyyy').format(DateTime.parse(_day))} · МСК',
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Следующая дата',
                            onPressed: () => _shift(1),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              signedIn
                                  ? 'Выбрано $_used из 10'
                                  : 'До 10 матчей на дату по МСК',
                            ),
                          ),
                          FilterChip(
                            label: const Text('Избранное'),
                            selected: _favoritesOnly,
                            onSelected: (v) =>
                                setState(() => _favoritesOnly = v),
                          ),
                        ],
                      ),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'П1 / Х / П2 · 90 минут · +10 за верный исход',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_tab == 2)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _month ?? 'all',
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('За всё время'),
                    ),
                    ...List.generate(12, (i) {
                      final now = moscowTime(DateTime.now());
                      final month = DateTime(now.year, now.month - i);
                      final value = DateFormat('yyyy-MM').format(month);
                      return DropdownMenuItem(
                        value: value,
                        child: Text(DateFormat('MM.yyyy').format(month)),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _month = value == 'all' ? null : value);
                    _load();
                  },
                ),
              ),
            if (_tab == 2 && _myRank != null) _rankCard(_myRank!, mine: true),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          TextButton(
                            onPressed: _load,
                            child: const Text('Повторить'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _tab == 0
                          ? _games(matches)
                          : _tab == 1
                          ? _myPredictions(signedIn)
                          : _ranking(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _shift(int days) {
    setState(
      () => _day = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.parse(_day).add(Duration(days: days))),
    );
    _load();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_day),
      firstDate: DateTime.now().subtract(const Duration(days: 730)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() => _day = DateFormat('yyyy-MM-dd').format(picked));
      _load();
    }
  }

  Widget _games(List<MatchModel> matches) {
    if (matches.isEmpty) return _empty('На эту дату нет доступных матчей');
    final choices = {for (final row in _choices) row['match_id'] as int: row};
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index], choice = choices[match.id];
        final selected = choice != null && choice['status'] == 'OPEN'
            ? choice['outcome'] as String
            : null;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${DateFormat('HH:mm').format(moscowTime(match.dateTime))} МСК · ${match.tournament.name}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${match.homeTeam.name} — ${match.awayTeam.name}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MatchDetailScreen(match: match),
                    ),
                  ),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'HOME', label: Text('П1')),
                    ButtonSegment(value: 'DRAW', label: Text('Х')),
                    ButtonSegment(value: 'AWAY', label: Text('П2')),
                  ],
                  selected: {if (selected != null) selected},
                  emptySelectionAllowed: true,
                  onSelectionChanged: _busy
                      ? null
                      : (values) {
                          if (values.isNotEmpty) _choose(match, values.first);
                        },
                ),
                if (selected != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _busy ? null : () => _cancel(match.id),
                      child: const Text('Отменить прогноз'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _myPredictions(bool signedIn) {
    if (!signedIn) return _empty('Войдите, чтобы увидеть свои прогнозы');
    if (_history.isEmpty) return _empty('Прогнозов пока нет');
    const labels = {
      'OPEN': 'Принят',
      'PENDING': 'Ожидание результата за 90 минут',
      'WON': 'Верно · +10',
      'LOST': 'Не угадан · 0',
      'VOID': 'Аннулирован',
      'CANCELLED': 'Отменён',
      'RECONFIRM': 'Перенос: подтвердите на новой дате',
    };
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: _history.length + (_historyMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _history.length) {
          return TextButton(
            onPressed: _busy ? null : () => _moreRows(false),
            child: const Text('Загрузить ещё'),
          );
        }
        final row = _history[index],
            match = MatchModel.fromJson(
              Map<String, dynamic>.from(row['match']),
            );
        return Card(
          child: ListTile(
            title: Text('${match.homeTeam.name} — ${match.awayTeam.name}'),
            subtitle: Text(
              '${row['day']} · ${labels[row['status']] ?? row['status']}',
            ),
            trailing: Text(
              const {'HOME': 'П1', 'DRAW': 'Х', 'AWAY': 'П2'}[row['outcome']]!,
            ),
            onTap: () {
              setState(() {
                _day = moscowDay(match.dateTime);
                _tab = 0;
              });
              _tabs.animateTo(0);
              _load();
            },
          ),
        );
      },
    );
  }

  Widget _rankCard(Map<String, dynamic> row, {bool mine = false}) => Card(
    child: ListTile(
      leading: Text(
        '#${row['rank']}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      title: Text(mine ? 'Вы · ${row['username']}' : row['username']),
      subtitle: Text(
        '${row['correct']}/${row['settled']} · точность ${row['accuracy']}%',
      ),
      trailing: Text('${row['total_points']} баллов'),
    ),
  );
  Widget _ranking() => _ranks.isEmpty
      ? _empty('В этом периоде ещё нет рассчитанных прогнозов')
      : ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          children: [
            ..._ranks.map((row) => _rankCard(row)),
            if (_ranks.length < _rankTotal)
              TextButton(
                onPressed: _busy ? null : () => _moreRows(true),
                child: const Text('Загрузить ещё'),
              ),
          ],
        );
  Widget _empty(String text) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      Padding(
        padding: const EdgeInsets.all(32),
        child: Text(text, textAlign: TextAlign.center),
      ),
    ],
  );
}

import 'package:dio/dio.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/auth_gate.dart';
import '../core/forecast_api.dart';
import '../models/all_models.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import 'match_detail_screen.dart';
import '../widgets/app_states.dart';
import '../widgets/football_logo.dart';
import '../widgets/match_summary.dart';

DateTime moscowTime(DateTime date) =>
    date.toUtc().add(const Duration(hours: 3));
String moscowDay(DateTime date) =>
    DateFormat('yyyy-MM-dd').format(moscowTime(date));

class ForecastsScreen extends StatefulWidget {
  final ForecastApi? api;
  final DateTime Function()? now;
  const ForecastsScreen({super.key, this.api, this.now});
  @override
  State<ForecastsScreen> createState() => _ForecastsScreenState();
}

class _ForecastsScreenState extends State<ForecastsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  late final ForecastApi _api = widget.api ?? ForecastApi();
  DateTime _now() => widget.now?.call() ?? DateTime.now();
  late String _day = moscowDay(_now());
  late String _observedMonth = _currentMonth();
  late String? _month = _observedMonth;
  Timer? _monthTimer;
  int _tab = 0, _used = 0, _generation = 0, _rankTotal = 0;
  bool _loading = true, _busy = false, _historyMore = false;
  bool _favoritesOnly = false;
  String? _error;
  final Map<int, String> _displayKeys = {};
  String get _viewKey =>
      '$_tab:${_tab == 0
          ? _day
          : _tab == 2
          ? _month
          : 'history'}';
  List<Map<String, dynamic>> _choices = [], _history = [], _ranks = [];
  Map<String, dynamic>? _myRank;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMonthCheck();
    Future.microtask(_load);
  }

  String _currentMonth() {
    final current = DateFormat('yyyy-MM').format(moscowTime(_now()));
    return current.compareTo('2026-10') < 0 ? '2026-10' : current;
  }

  List<DateTime> _months() {
    final current = DateTime.parse('${_currentMonth()}-01');
    final count = (current.year - 2026) * 12 + current.month - 10 + 1;
    return List.generate(
      count,
      (i) => DateTime(current.year, current.month - i),
    );
  }

  void _scheduleMonthCheck() {
    _monthTimer?.cancel();
    final now = _now().toUtc();
    final moscow = moscowTime(now);
    final next = DateTime.utc(
      moscow.year,
      moscow.month + 1,
    ).subtract(const Duration(hours: 3));
    final remaining = next.difference(now);
    _monthTimer = Timer(
      remaining.isNegative ? const Duration(seconds: 1) : remaining,
      _checkMonth,
    );
  }

  void _checkMonth() {
    if (!mounted) return;
    final current = _currentMonth();
    if (current != _observedMonth) {
      setState(() {
        _observedMonth = current;
        _month = current;
      });
      if (_tab == 2) _load();
    }
    _scheduleMonthCheck();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkMonth();
    } else {
      _monthTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _monthTimer?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load({bool keepList = false}) async {
    final generation = ++_generation;
    final signedIn = context.read<AuthProvider>().isAuthenticated;
    setState(() {
      if (!keepList) _loading = _displayKeys[_tab] != _viewKey;
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
      if (mounted && generation == _generation) _displayKeys[_tab] = _viewKey;
    } catch (error) {
      if (mounted && generation == _generation) {
        if (keepList) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_message(error))));
        } else {
          setState(() => _error = _message(error));
        }
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(error))));
      }
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
          if (mounted) await _load(keepList: true);
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
      if (mounted) await _load(keepList: true);
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
                  m.dateTime.isAfter(_now()) &&
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
          bottom: appTabs(
            context,
            const ['Матчи', 'Мои прогнозы', 'Рейтинг'],
            controller: _tabs,
            fixedEqualWidth: false,
            onTap: (tab) {
              setState(() => _tab = tab);
              _load();
            },
          ),
        ),
        body: Column(
          children: [
            if (_tab == 0)
              Card(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
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
                                textAlign: TextAlign.center,
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              signedIn
                                  ? 'Выбрано $_used из 10'
                                  : 'Лимит: 10 матчей',
                            ),
                            FilterChip(
                              label: const Text('Избранное'),
                              selected: _favoritesOnly,
                              onSelected: (value) =>
                                  setState(() => _favoritesOnly = value),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '90 минут · +10 за верный исход',
                          style: Theme.of(context).textTheme.bodySmall,
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
                    ..._months().map((month) {
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
            if (_tab == 2 && !_loading && _error == null && _myRank != null)
              _rankCard(_myRank!, mine: true),
            if (_error != null && _displayKeys[_tab] == _viewKey)
              UpdateNotice(message: _error!, onRetry: _load),
            Expanded(
              child: _loading
                  ? AppSkeleton(
                      label: _tab == 2
                          ? 'Загрузка рейтинга'
                          : 'Загрузка прогнозов',
                    )
                  : _error != null && _displayKeys[_tab] != _viewKey
                  ? AppEmptyState(
                      title: 'Не удалось получить данные',
                      message: _error,
                      icon: Icons.wifi_off_outlined,
                      actionLabel: 'Повторить',
                      onAction: _load,
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
      firstDate: _now().subtract(const Duration(days: 730)),
      lastDate: _now().add(const Duration(days: 730)),
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
      key: PageStorageKey('forecast-choices-$_day'),
      padding: const EdgeInsets.all(16),
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
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MatchDetailScreen(match: match),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        for (final team in [match.homeTeam, match.awayTeam])
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                FootballLogo(url: team.logoUrl, size: 26),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    team.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SegmentedButton<String>(
                  expandedInsets: EdgeInsets.zero,
                  style: const ButtonStyle(
                    minimumSize: WidgetStatePropertyAll(Size(48, 48)),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: 'HOME',
                      label: Text('П1'),
                      tooltip: 'Победа хозяев',
                    ),
                    ButtonSegment(
                      value: 'DRAW',
                      label: Text('Х'),
                      tooltip: 'Ничья',
                    ),
                    ButtonSegment(
                      value: 'AWAY',
                      label: Text('П2'),
                      tooltip: 'Победа гостей',
                    ),
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
    if (!signedIn) {
      return _empty(
        'Войдите, чтобы увидеть свои прогнозы',
        actionLabel: 'Войти / зарегистрироваться',
        onAction: () async {
          if (await openAuthScreen(context) && mounted) _load();
        },
      );
    }
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MatchSummary(
                match: match,
                showTournament: true,
                onTap: () {
                  setState(() {
                    _day = moscowDay(match.dateTime);
                    _tab = 0;
                  });
                  _tabs.animateTo(0);
                  _load();
                },
              ),
              const Divider(height: 1, indent: 14, endIndent: 14),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Text(
                      'Ваш прогноз: ${const {'HOME': 'П1', 'DRAW': 'Х', 'AWAY': 'П2'}[row['outcome']]}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '${row['day']} · ${labels[row['status']] ?? row['status']}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _rankCard(Map<String, dynamic> row, {bool mine = false}) => Card(
    margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#${row['rank']}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Tooltip(
                  message: row['username'],
                  child: Text(
                    mine ? 'Вы · ${row['username']}' : row['username'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${row['total_points']} баллов',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                '${row['correct']}/${row['settled']} · точность ${row['accuracy']}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
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
  Widget _empty(String text, {String? actionLabel, VoidCallback? onAction}) =>
      LayoutBuilder(
        builder: (context, constraints) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: constraints.maxHeight,
              child: AppEmptyState(
                title: text,
                icon: _tab == 2
                    ? Icons.leaderboard_outlined
                    : Icons.sports_soccer_outlined,
                actionLabel: actionLabel,
                onAction: onAction,
              ),
            ),
          ],
        ),
      );
}

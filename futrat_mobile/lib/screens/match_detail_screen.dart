import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/all_models.dart';
import '../widgets/lineup_view.dart';
import '../widgets/team_link.dart';
import '../widgets/football_logo.dart';
import '../core/app_theme.dart';
import '../core/auth_gate.dart';
import '../core/translator.dart'; // ПОДКЛЮЧАЕМ МЕГА-СЛОВАРЬ
import '../providers/theme_provider.dart';
import '../providers/data_provider.dart';

class MatchDetailScreen extends StatefulWidget {
  final MatchModel match;
  const MatchDetailScreen({super.key, required this.match});
  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  late MatchModel _currentMatch;
  bool _isLoadingDetails = true;
  Timer? _liveTimer;

  @override
  void initState() {
    super.initState();
    _currentMatch = widget.match;
    _loadDeepStats();

    _liveTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_currentMatch.isLive) {
        _loadDeepStats();
      }
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDeepStats() async {
    if (_currentMatch.status == "CANCELLED") {
      if (mounted) setState(() => _isLoadingDetails = false);
      return;
    }
    final detailedMatch = await Provider.of<DataProvider>(
      context,
      listen: false,
    ).getMatchDetails(_currentMatch.id);
    if (detailedMatch != null && mounted) {
      setState(() {
        _currentMatch = detailedMatch;
        _isLoadingDetails = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingDetails = false);
    }
  }

  void _showRatingPicker(LineupPlayer player) {
    if (_currentMatch.status != "FINISHED" ||
        player.appeared == false ||
        (player.appeared == null && !player.isStarter)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Оценки доступны после матча для участвовавших игроков",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Оцените игрока",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  player.playerName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: List.generate(10, (i) {
                    double val = i + 1.0;
                    return InkWell(
                      onTap: () async {
                        Navigator.pop(context);
                        await runAuthenticatedAction(
                          this.context,
                          action: 'поставить оценку игроку',
                          onAuthenticated: (_) async {
                            final success = await this.context
                                .read<DataProvider>()
                                .ratePlayer(player.id, val);
                            if (!mounted) return;
                            if (success) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('Оценка принята!'),
                                ),
                              );
                              _loadDeepStats();
                            }
                          },
                        );
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _getRatingColor(val.toString()),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          val.toInt().toString(),
                          style: TextStyle(
                            color: AppTheme.foregroundOn(
                              _getRatingColor(val.toString()),
                            ),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataProvider>(context);
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final events = List<MatchEvent>.from(_currentMatch.events)
      ..sort((a, b) => a.minute.compareTo(b.minute));

    final isLive = _currentMatch.isLive;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: theme.background,
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: theme.textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      _currentMatch.tournament.name.replaceAll(
                        RegExp(r'\s*\([^)]*\)'),
                        '',
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: theme.panel(),
                padding: const EdgeInsets.only(top: 10, bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _teamColumn(_currentMatch.homeTeam, data, theme),
                    Expanded(
                      child: Column(
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              (_currentMatch.status == "SCHEDULED" ||
                                      _currentMatch.status == "DELAYED")
                                  ? "-- : --"
                                  : "${_currentMatch.scoreHome ?? '-'} : ${_currentMatch.scoreAway ?? '-'}",
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: theme.textColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.accentColor.withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              _currentMatch.needsStatusCheck
                                  ? 'СТАТУС УТОЧНЯЕТСЯ'
                                  : _currentMatch.status == "DELAYED"
                                  ? "ОТЛОЖЕН"
                                  : isLive
                                  ? _currentMatch.liveLabel
                                  : _currentMatch.status,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isLive
                                    ? Colors.redAccent
                                    : (_currentMatch.status == 'DELAYED'
                                          ? Colors.orange
                                          : theme.accentColor),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _teamColumn(_currentMatch.awayTeam, data, theme),
                  ],
                ),
              ),
              if (_isLoadingDetails)
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: theme.accentColor),
                  ),
                )
              else
                Expanded(
                  child: DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        TabBar(
                          indicatorColor: theme.accentColor,
                          labelColor: theme.accentColor,
                          unselectedLabelColor: theme.dimTextColor,
                          tabs: const [
                            Tab(text: "Составы"),
                            Tab(text: "Статистика"),
                            Tab(text: "Хронология"),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              LineupView(
                                match: _currentMatch,
                                onRate: _showRatingPicker,
                              ),
                              _buildStats(theme),
                              _buildTimeline(theme, events),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRatingColor(String rStr) {
    if (rStr == "-") return Colors.grey.withOpacity(0.5);
    double r = double.tryParse(rStr) ?? 0;
    if (r >= 8.0) return Colors.green;
    if (r >= 7.0) return Colors.lightGreen;
    if (r >= 6.0) return Colors.orange;
    return Colors.redAccent;
  }

  Widget _buildStats(AppCustomTheme theme) {
    bool hasStats =
        _currentMatch.shotsHome > 0 ||
        _currentMatch.shotsAway > 0 ||
        _currentMatch.cornersHome > 0;
    if (!hasStats)
      return Center(
        child: Text(
          "Статистика недоступна",
          style: TextStyle(color: theme.dimTextColor),
        ),
      );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sBar(
          "Владение",
          "${_currentMatch.possessionHome}%",
          "${_currentMatch.possessionAway}%",
          theme,
          vH: _currentMatch.possessionHome.toDouble(),
          vA: _currentMatch.possessionAway.toDouble(),
        ),
        _sBar(
          "Удары (в створ)",
          "${_currentMatch.shotsHome} (${_currentMatch.shotsOnTargetHome})",
          "${_currentMatch.shotsAway} (${_currentMatch.shotsOnTargetAway})",
          theme,
          vH: _currentMatch.shotsHome.toDouble(),
          vA: _currentMatch.shotsAway.toDouble(),
        ),
        _sBar(
          "Пасы",
          "${_currentMatch.passesHome}",
          "${_currentMatch.passesAway}",
          theme,
          vH: _currentMatch.passesHome.toDouble(),
          vA: _currentMatch.passesAway.toDouble(),
        ),
        _sBar(
          "Точность пасов",
          "${_currentMatch.passAccuracyHome}%",
          "${_currentMatch.passAccuracyAway}%",
          theme,
          vH: _currentMatch.passAccuracyHome.toDouble(),
          vA: _currentMatch.passAccuracyAway.toDouble(),
        ),
        _sBar(
          "Сейвы",
          "${_currentMatch.savesHome}",
          "${_currentMatch.savesAway}",
          theme,
          vH: _currentMatch.savesHome.toDouble(),
          vA: _currentMatch.savesAway.toDouble(),
        ),
        _sBar(
          "Угловые",
          "${_currentMatch.cornersHome}",
          "${_currentMatch.cornersAway}",
          theme,
          vH: _currentMatch.cornersHome.toDouble(),
          vA: _currentMatch.cornersAway.toDouble(),
        ),
        _sBar(
          "Фолы",
          "${_currentMatch.foulsHome}",
          "${_currentMatch.foulsAway}",
          theme,
          vH: _currentMatch.foulsHome.toDouble(),
          vA: _currentMatch.foulsAway.toDouble(),
        ),
        _sBar(
          "Желтые карточки",
          "${_currentMatch.yellowCardsHome}",
          "${_currentMatch.yellowCardsAway}",
          theme,
          vH: _currentMatch.yellowCardsHome.toDouble(),
          vA: _currentMatch.yellowCardsAway.toDouble(),
        ),
        _sBar(
          "Красные карточки",
          "${_currentMatch.redCardsHome}",
          "${_currentMatch.redCardsAway}",
          theme,
          vH: _currentMatch.redCardsHome.toDouble(),
          vA: _currentMatch.redCardsAway.toDouble(),
        ),
        _sBar(
          "Офсайды",
          "${_currentMatch.offsidesHome}",
          "${_currentMatch.offsidesAway}",
          theme,
          vH: _currentMatch.offsidesHome.toDouble(),
          vA: _currentMatch.offsidesAway.toDouble(),
        ),
      ],
    );
  }

  Widget _sBar(
    String t,
    String h,
    String a,
    AppCustomTheme th, {
    double vH = 0,
    double vA = 0,
  }) {
    double total = vH + vA;
    int fH = total == 0 ? 1 : (vH * 10).toInt();
    int fA = total == 0 ? 1 : (vA * 10).toInt();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: th.panel(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                h,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: th.textColor,
                ),
              ),
              Text(
                t,
                style: TextStyle(
                  color: th.dimTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                a,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: th.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Expanded(
                  flex: fH,
                  child: Container(height: 6, color: th.accentColor),
                ),
                const SizedBox(width: 3),
                Expanded(
                  flex: fA,
                  child: Container(height: 6, color: th.dividerColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(AppCustomTheme theme, List<MatchEvent> events) {
    if (events.isEmpty)
      return Center(
        child: Text(
          "События не зафиксированы",
          style: TextStyle(color: theme.dimTextColor),
        ),
      );
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final e = events[index];
        bool isHome = e.player.teamId == _currentMatch.homeTeam.id;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: isHome ? _evContent(e, isHome, theme) : const SizedBox(),
              ),
              Container(
                width: 36,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: theme.cardBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  "${e.minute}'",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: theme.textColor,
                  ),
                ),
              ),
              Expanded(
                child: !isHome
                    ? _evContent(e, isHome, theme)
                    : const SizedBox(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _evContent(MatchEvent e, bool isHome, AppCustomTheme theme) {
    Widget icon;
    String mainText = e.player.name;
    String subText = e.secondaryPlayer?.name ?? "";
    if (e.type == 'GOAL')
      icon = Icon(Icons.sports_soccer, color: theme.textColor, size: 14);
    else if (e.type == 'YELLOW_CARD')
      icon = Container(
        width: 10,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    else if (e.type == 'RED_CARD')
      icon = Container(
        width: 10,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    else if (e.type == 'SUBSTITUTION') {
      return Column(
        crossAxisAlignment: isHome
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: isHome
                ? [
                    Flexible(
                      child: Text(
                        "В: $mainText",
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 11, color: theme.textColor),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_upward,
                      color: Colors.green,
                      size: 12,
                    ),
                  ]
                : [
                    const Icon(
                      Icons.arrow_upward,
                      color: Colors.green,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        "В: $mainText",
                        textAlign: TextAlign.left,
                        style: TextStyle(fontSize: 11, color: theme.textColor),
                      ),
                    ),
                  ],
          ),
          if (subText.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: isHome
                  ? [
                      Flexible(
                        child: Text(
                          "У: $subText",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.dimTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_downward,
                        color: Colors.redAccent,
                        size: 12,
                      ),
                    ]
                  : [
                      const Icon(
                        Icons.arrow_downward,
                        color: Colors.redAccent,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          "У: $subText",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.dimTextColor,
                          ),
                        ),
                      ),
                    ],
            ),
        ],
      );
    } else {
      icon = Icon(Icons.info_outline, size: 14, color: theme.dimTextColor);
    }

    Widget textPart = Flexible(
      child: RichText(
        textAlign: isHome ? TextAlign.right : TextAlign.left,
        text: TextSpan(
          children: [
            if (e.type == 'GOAL' && subText.isNotEmpty)
              TextSpan(
                text: "($subText) ",
                style: TextStyle(fontSize: 9, color: theme.dimTextColor),
              ),
            TextSpan(
              text: mainText,
              style: TextStyle(
                fontSize: 11,
                color: theme.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
    List<Widget> children = [textPart, const SizedBox(width: 6), icon];
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: isHome
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: isHome ? children : children.reversed.toList(),
    );
  }

  Widget _teamColumn(
    Team team,
    DataProvider data,
    AppCustomTheme currentTheme,
  ) {
    final isFav = data.isTeamFavorite(team.id);
    return Expanded(
      child: Column(
        children: [
          GestureDetector(
            onTap: () => runAuthenticatedAction(
              context,
              action: 'добавить команду в избранное',
              onAuthenticated: (resumed) async {
                if (resumed && data.isTeamFavorite(team.id)) return;
                await data.toggleTeamFavorite(team.id);
              },
            ),
            child: Icon(
              isFav ? Icons.star : Icons.star_border,
              color: isFav ? Colors.amber : currentTheme.dimTextColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 10),
          TeamLink(
            team: team,
            child: Container(
              key: ValueKey('match-team-block-${team.id}'),
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: currentTheme.panel(radius: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FootballLogo(url: team.logoUrl, size: 60),
                  const SizedBox(height: 10),
                  Text(
                    tr(team.name),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: currentTheme.textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

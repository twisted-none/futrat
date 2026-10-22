import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/theme_provider.dart';
import '../core/app_theme.dart';
import '../core/auth_gate.dart';
import '../core/translator.dart';
import '../models/all_models.dart';
import 'match_detail_screen.dart';
import '../widgets/grouped_matches_list.dart';
import '../widgets/round_selector.dart';
import '../widgets/team_link.dart';
import '../widgets/football_logo.dart';

// --- КЛАСС ДЛЯ БЕЗОПАСНОГО ОТОБРАЖЕНИЯ И ПЕРЕРАСЧЕТА ТАБЛИЦЫ ---
class UITableRow {
  final int rank;
  final Team team;
  final int played;
  final int won;
  final int draw;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int points;
  final List<String> form;
  final String groupName;

  UITableRow({
    required this.rank,
    required this.team,
    required this.played,
    required this.won,
    required this.draw,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.points,
    required this.form,
    required this.groupName,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _activeStageFilter = "1/8";

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<DataProvider>(context, listen: false).initData(),
    );
  }

  int _getMaxRounds(String? leagueName, int teamsCount) {
    if (leagueName == null) return 38;
    final l = leagueName.toLowerCase();

    // Лига Конференций - строго 6 туров в группе
    if (l.contains("conference") || l.contains("конференц")) return 6;
    // ЛЧ и ЛЕ - строго 8 туров
    if (l.contains("champions") ||
        l.contains("europa") ||
        l.contains("(uefa)") ||
        l.contains("чемпион") ||
        l.contains("европ"))
      return 8;

    if (l.contains("(usa-1)")) return 34;
    if (teamsCount > 0) return (teamsCount * 2) - 2;
    return 38;
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataProvider>(context);
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final name = data.selectedLeague?.name ?? "";
    final lName = name.toLowerCase();

    final isVirtual = (data.selectedLeague?.id ?? 0) < 0;
    final code = data.selectedLeague?.apiCode;
    final pendingDraw = data.selectedLeague?.type == 'PendingDraw';
    final pendingSchedule = data.selectedLeague?.type == 'PendingSchedule';
    final isPending = pendingDraw || pendingSchedule;
    final isNational = const {
      'uefa.nations',
      'caf.nations',
      'uefa.euroq',
    }.contains(code);
    final isGoalCup = const {
      'rus.cup',
      'eng.fa',
      'esp.super_cup',
    }.contains(code);

    // Определяем Лигу Конференций
    final isConference =
        lName.contains("conference") || lName.contains("конференц");
    // Общая проверка на еврокубки
    final isUefaMatch = code != null
        ? const {
            'uefa.champions',
            'uefa.europa',
            'uefa.europa.conf',
          }.contains(code)
        : lName.contains("champions") ||
              lName.contains("europa") ||
              isConference ||
              name.contains("(UEFA)") ||
              lName.contains("чемпион") ||
              lName.contains("европ");
    final uefaLimit = isConference ? 6 : 8; // Лимит туров/матчей

    final isEuroCups = isUefaMatch;
    final isWorldCup = name.contains("(FIFA)");
    final isFriendly = name.contains("(INT)");
    final isDomesticCup =
        name.contains("CUP)") || name.contains("-LC)") || name.contains("-SC)");
    final isChampionship = name.contains("(ENG-2)");
    final isMLS = name.contains("(USA-1)");

    final bool isBigTable = [
      "(ENG-1)",
      "(ESP-1)",
      "(GER-1)",
      "(FRA-1)",
      "(ITA-1)",
      "(RUS-1)",
      "(NED-1)",
      "(POR-1)",
      "(TUR-1)",
      "(KSA-1)",
    ].any((tag) => name.contains(tag));

    int maxRounds = _getMaxRounds(name, data.currentStandings.length);
    int safeMaxRounds = maxRounds;

    // Жесткое ограничение для туров: УЕФА турниры не могут раздуваться больше своего лимита
    if (!isUefaMatch && data.selectedRound > safeMaxRounds) {
      safeMaxRounds = data.selectedRound;
    }

    int safeValue = data.selectedRound;
    if (safeValue < 1) safeValue = 1;
    if (safeValue > safeMaxRounds) safeValue = safeMaxRounds;

    List<Tab> tabs = [];
    List<Widget> views = [];

    if (isPending) {
      views = [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_note_outlined,
                  size: 52,
                  color: theme.accentColor,
                ),
                const SizedBox(height: 20),
                Text(
                  pendingDraw
                      ? 'Евро — ${data.selectedLeague?.currentSeason ?? "2028"}'
                      : 'Отбор Евро — ${data.selectedLeague?.currentSeason ?? "2028"}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  pendingDraw
                      ? 'Ждём полную жеребьёвку. Группы и матчи появятся после её проведения.'
                      : 'Ждём публикацию расписания нового отбора.',
                  style: TextStyle(color: theme.dimTextColor, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ];
    } else if (isVirtual) {
      views = [
        GroupedMatchesList(
          matches: data.matches,
          feedId: data.selectedLeague!.id,
        ),
      ];
    } else if (isNational || isGoalCup) {
      // National groups and Russia's two cup paths do not use the club UEFA bracket.
      tabs = [
        if (isNational) const Tab(text: 'Группы'),
        const Tab(text: 'Матчи'),
        const Tab(text: 'Недавние игры'),
      ];
      views = [
        if (isNational) _buildStandingsList(data, theme, false),
        _buildMatchesList(data.matches, data, theme),
        _buildOverviewTab(data, theme),
      ];
    } else if (isFriendly) {
      tabs = const [Tab(text: "Предстоящие матчи"), Tab(text: "Недавние игры")];
      views = [
        _buildMatchesList(
          data.matches.where((m) => m.status == "SCHEDULED").toList(),
          data,
          theme,
        ),
        _buildMatchesList(
          data.matches
              .where((m) => m.status == "FINISHED")
              .toList()
              .reversed
              .toList(),
          data,
          theme,
        ),
      ];
    } else if (isEuroCups) {
      tabs = const [
        Tab(text: "Таблица"),
        Tab(text: "Групповой этап"),
        Tab(text: "Плей-офф"),
        Tab(text: "Недавние игры"),
      ];
      views = [
        _buildStandingsList(
          data,
          theme,
          false,
          isUefa: true,
          uefaMatchLimit: uefaLimit,
        ),
        _buildRoundsTab(
          data.matches.where((m) => m.round == safeValue).toList(),
          safeMaxRounds,
          safeValue,
          data,
          theme,
        ),
        _buildPlayoffTree(data, theme),
        _buildOverviewTab(data, theme),
      ];
    } else if (isWorldCup) {
      tabs = const [
        Tab(text: "Групповой этап"),
        Tab(text: "Плей-офф"),
        Tab(text: "Недавние игры"),
      ];
      views = [
        _buildStandingsList(data, theme, false),
        _buildPlayoffTree(data, theme),
        _buildOverviewTab(data, theme),
      ];
    } else if (isChampionship) {
      tabs = const [
        Tab(text: "Таблица"),
        Tab(text: "Туры"),
        Tab(text: "Плей-офф"),
        Tab(text: "Недавние игры"),
      ];
      views = [
        _buildStandingsList(data, theme, false),
        _buildRoundsTab(
          data.matches.where((m) => m.round == safeValue).toList(),
          safeMaxRounds,
          safeValue,
          data,
          theme,
        ),
        _buildPlayoffTree(data, theme),
        _buildOverviewTab(data, theme),
      ];
    } else if (isDomesticCup) {
      tabs = const [Tab(text: "Сетка турнира"), Tab(text: "Недавние игры")];
      views = [_buildPlayoffTree(data, theme), _buildOverviewTab(data, theme)];
    } else if (isMLS) {
      tabs = const [
        Tab(text: "Конференции"),
        Tab(text: "Регулярный сезон"),
        Tab(text: "Плей-офф"),
        Tab(text: "Недавние игры"),
      ];
      views = [
        _buildStandingsList(data, theme, false),
        _buildRoundsTab(
          data.matches.where((m) => m.round == safeValue).toList(),
          safeMaxRounds,
          safeValue,
          data,
          theme,
        ),
        _buildPlayoffTree(data, theme),
        _buildOverviewTab(data, theme),
      ];
    } else {
      tabs = const [
        Tab(text: "Таблица"),
        Tab(text: "Туры"),
        Tab(text: "Недавние игры"),
      ];
      views = [
        _buildStandingsList(data, theme, isBigTable),
        _buildRoundsTab(
          data.matches.where((m) => m.round == safeValue).toList(),
          safeMaxRounds,
          safeValue,
          data,
          theme,
        ),
        _buildOverviewTab(data, theme),
      ];
    }

    return Container(
      decoration: theme.background,
      child: DefaultTabController(
        key: ValueKey(data.selectedLeague?.id),
        length: views.length,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              name.isEmpty
                  ? "Матчи"
                  : name.replaceAll(RegExp(r'\s*\([^)]*\)'), ''),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            centerTitle: true,
            iconTheme: IconThemeData(color: theme.textColor),
            bottom: isVirtual || isFriendly || isPending
                ? null
                : TabBar(
                    isScrollable: tabs.length != 3,
                    tabAlignment: tabs.length == 3
                        ? TabAlignment.fill
                        : TabAlignment.start,
                    labelPadding: tabs.length == 3 ? EdgeInsets.zero : null,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorColor: theme.accentColor,
                    labelColor: theme.accentColor,
                    unselectedLabelColor: theme.dimTextColor,
                    tabs: [
                      for (var i = 0; i < tabs.length; i++)
                        if (tabs.length == 3)
                          Tab(
                            key: ValueKey('league-tab-$i'),
                            height:
                                (MediaQuery.textScalerOf(context).scale(14) *
                                            2.4 +
                                        8)
                                    .clamp(52, 160)
                                    .toDouble(),
                            child: SizedBox(
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: Text(
                                  tabs[i].text ?? '',
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                          )
                        else
                          tabs[i],
                    ],
                  ),
          ),
          drawer: _buildDrawer(context, data, theme),
          body: data.isLoading
              ? Center(
                  child: CircularProgressIndicator(color: theme.accentColor),
                )
              : TabBarView(children: views),
        ),
      ),
    );
  }

  Widget _buildMatchesList(
    List<MatchModel> matches,
    DataProvider data,
    AppCustomTheme theme,
  ) {
    if (matches.isEmpty) {
      return Center(
        child: Text("Нет матчей", style: TextStyle(color: theme.dimTextColor)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: matches.length,
      itemBuilder: (ctx, i) =>
          _buildMatchCard(context, matches[i], data, theme),
    );
  }

  // БЕЗОТКАЗНЫЙ МЕТОД: Определяет стадию УЕФА исключительно по дате (месяцу)
  String _getUefaStageByDate(DateTime dt) {
    int m = dt.month;
    int d = dt.day;
    if (m == 2) return "1/16";
    if (m == 3) return "1/8";
    if (m == 4 && d <= 25) return "1/4";
    if ((m == 4 && d > 25) || (m == 5 && d <= 15)) return "1/2";
    if (m == 5 && d > 15) return "ФИНАЛ";
    if (m == 6) return "ФИНАЛ";
    return ""; // Группы или неизвестно
  }

  static const Map<String, List<_StrictUefaSlot>> _strictUefaSlots = {
    "champions": [
      _StrictUefaSlot("1/16", "left", "psg", "monaco"),
      _StrictUefaSlot("1/16", "left", "juventus", "galatasaray"),
      _StrictUefaSlot("1/16", "left", "real_madrid", "benfica"),
      _StrictUefaSlot("1/16", "left", "atalanta", "dortmund"),
      _StrictUefaSlot("1/16", "right", "newcastle", "qarabag"),
      _StrictUefaSlot("1/16", "right", "atletico_madrid", "brugge"),
      _StrictUefaSlot("1/16", "right", "inter", "bodo_glimt"),
      _StrictUefaSlot("1/16", "right", "bayer", "olympiacos"),
      _StrictUefaSlot("1/8", "left", "chelsea", "psg"),
      _StrictUefaSlot("1/8", "left", "liverpool", "galatasaray"),
      _StrictUefaSlot("1/8", "left", "manchester_city", "real_madrid"),
      _StrictUefaSlot("1/8", "left", "bayern", "atalanta"),
      _StrictUefaSlot("1/8", "right", "barcelona", "newcastle"),
      _StrictUefaSlot("1/8", "right", "tottenham", "atletico_madrid"),
      _StrictUefaSlot("1/8", "right", "sporting", "bodo_glimt"),
      _StrictUefaSlot("1/8", "right", "arsenal", "bayer"),
      _StrictUefaSlot("1/4", "left", "psg", "liverpool"),
      _StrictUefaSlot("1/4", "left", "real_madrid", "bayern"),
      _StrictUefaSlot("1/4", "right", "barcelona", "atletico_madrid"),
      _StrictUefaSlot("1/4", "right", "arsenal", "sporting"),
    ],
    "europa": [
      _StrictUefaSlot("1/16", "left", "ferencvaros", "ludogorets"),
      _StrictUefaSlot("1/16", "left", "viktoria_plzen", "panathinaikos"),
      _StrictUefaSlot("1/16", "left", "genk", "dinamo_zagreb"),
      _StrictUefaSlot("1/16", "left", "celta", "paok"),
      _StrictUefaSlot("1/16", "right", "stuttgart", "celtic"),
      _StrictUefaSlot("1/16", "right", "nottingham", "fenerbahce"),
      _StrictUefaSlot("1/16", "right", "bologna", "brann"),
      _StrictUefaSlot("1/16", "right", "crvena_zvezda", "lille"),
      _StrictUefaSlot("1/8", "left", "braga", "ferencvaros"),
      _StrictUefaSlot("1/8", "left", "betis", "panathinaikos"),
      _StrictUefaSlot("1/8", "left", "freiburg", "genk"),
      _StrictUefaSlot("1/8", "left", "lyon", "celta"),
      _StrictUefaSlot("1/8", "right", "porto", "stuttgart"),
      _StrictUefaSlot("1/8", "right", "midtjylland", "nottingham"),
      _StrictUefaSlot("1/8", "right", "roma", "bologna"),
      _StrictUefaSlot("1/8", "right", "aston_villa", "lille"),
      _StrictUefaSlot("1/4", "left", "braga", "betis"),
      _StrictUefaSlot("1/4", "left", "freiburg", "celta"),
      _StrictUefaSlot("1/4", "right", "porto", "nottingham"),
      _StrictUefaSlot("1/4", "right", "bologna", "aston_villa"),
    ],
    "conference": [
      _StrictUefaSlot("1/16", "left", "lech", "kups"),
      _StrictUefaSlot("1/16", "left", "alkmaar", "noah"),
      _StrictUefaSlot("1/16", "left", "crystal_palace", "zrinjski"),
      _StrictUefaSlot("1/16", "left", "fiorentina", "jagiellonia"),
      _StrictUefaSlot("1/16", "right", "samsunspor", "shkendija"),
      _StrictUefaSlot("1/16", "right", "celje", "drita"),
      _StrictUefaSlot("1/16", "right", "lausanne_sport", "sigma"),
      _StrictUefaSlot("1/16", "right", "rijeka", "omonia"),
      _StrictUefaSlot("1/8", "left", "shakhtar", "lech"),
      _StrictUefaSlot("1/8", "left", "sparta", "alkmaar"),
      _StrictUefaSlot("1/8", "left", "aek_larnaca", "crystal_palace"),
      _StrictUefaSlot("1/8", "left", "rakow", "fiorentina"),
      _StrictUefaSlot("1/8", "right", "rayo", "samsunspor"),
      _StrictUefaSlot("1/8", "right", "aek_athens", "celje"),
      _StrictUefaSlot("1/8", "right", "mainz", "sigma"),
      _StrictUefaSlot("1/8", "right", "strasbourg", "rijeka"),
      _StrictUefaSlot("1/4", "left", "shakhtar", "alkmaar"),
      _StrictUefaSlot("1/4", "left", "crystal_palace", "fiorentina"),
      _StrictUefaSlot("1/4", "right", "rayo", "aek_athens"),
      _StrictUefaSlot("1/4", "right", "mainz", "strasbourg"),
    ],
  };

  static const Map<String, List<String>> _strictTeamAliases = {
    "psg": ["psg", "paris saint", "псж"],
    "monaco": ["monaco", "монако"],
    "juventus": ["juventus", "ювентус"],
    "galatasaray": ["galatasaray", "галатасарай"],
    "real_madrid": ["real madrid", "реал мадрид"],
    "benfica": ["benfica", "бенфика"],
    "atalanta": ["atalanta", "аталанта"],
    "dortmund": ["dortmund", "боруссия дортмунд"],
    "newcastle": ["newcastle", "ньюкасл"],
    "qarabag": ["qarabag", "карабах"],
    "atletico_madrid": ["atletico madrid", "atletico", "атлетико мадрид"],
    "brugge": ["brugge", "брюгге"],
    "inter": ["inter milan", "internazionale", "inter", "интер"],
    "bodo_glimt": ["bodo glimt", "bodo", "glimt", "буде", "глимт"],
    "bayer": ["bayer", "leverkusen", "байер"],
    "olympiacos": ["olympiacos", "olympiakos", "олимпиакос"],
    "chelsea": ["chelsea", "челси"],
    "liverpool": ["liverpool", "ливерпуль"],
    "manchester_city": ["manchester city", "man city", "манчестер сити"],
    "bayern": ["bayern", "бавария"],
    "barcelona": ["barcelona", "барселона"],
    "tottenham": ["tottenham", "spurs", "тоттенхэм"],
    "sporting": ["sporting", "спортинг"],
    "arsenal": ["arsenal", "арсенал"],
    "ferencvaros": ["ferencvaros", "ференцварош"],
    "ludogorets": ["ludogorets", "лудогорец"],
    "viktoria_plzen": ["viktoria plzen", "plzen", "виктория плзень"],
    "panathinaikos": ["panathinaikos", "панатинаикос"],
    "genk": ["genk", "генк"],
    "dinamo_zagreb": ["dinamo zagreb", "dynamo zagreb", "динамо загреб"],
    "celta": ["celta", "сельта"],
    "paok": ["paok", "паок"],
    "stuttgart": ["stuttgart", "штутгарт"],
    "celtic": ["celtic", "селтик"],
    "nottingham": ["nottingham forest", "nottingham", "ноттингем"],
    "fenerbahce": ["fenerbahce", "фенербахче"],
    "bologna": ["bologna", "болонья"],
    "brann": ["brann", "бранн"],
    "crvena_zvezda": ["crvena zvezda", "red star", "црвена звезда"],
    "lille": ["lille", "лилль"],
    "braga": ["braga", "брага"],
    "betis": ["betis", "бетис"],
    "freiburg": ["freiburg", "фрайбург"],
    "lyon": ["lyon", "лион"],
    "porto": ["porto", "порту"],
    "midtjylland": ["midtjylland", "митьюлланд"],
    "roma": ["roma", "рома"],
    "aston_villa": ["aston villa", "астон вилла"],
    "lech": ["lech", "лех"],
    "kups": ["kups", "купс"],
    "alkmaar": ["az alkmaar", "alkmaar", "алкмаар"],
    "noah": ["noah", "noa", "ноа"],
    "crystal_palace": ["crystal palace", "кристал пэлас"],
    "zrinjski": ["zrinjski", "зриньски"],
    "fiorentina": ["fiorentina", "фиорентина"],
    "jagiellonia": ["jagiellonia", "ягеллония"],
    "samsunspor": ["samsunspor", "самсунспор", "самунспор"],
    "shkendija": ["shkendija", "шкендия"],
    "celje": ["celje", "целе"],
    "drita": ["drita", "дрита"],
    "lausanne_sport": ["lausanne sport", "lausanne", "лозанна"],
    "sigma": ["sigma", "сигма"],
    "rijeka": ["rijeka", "риека"],
    "omonia": ["omonia", "омония"],
    "shakhtar": ["shakhtar", "шахтер", "шахтар"],
    "sparta": ["sparta", "спарта"],
    "aek_larnaca": ["aek larnaca", "ларнака"],
    "rakow": ["rakow", "ракув"],
    "rayo": ["rayo", "райо"],
    "aek_athens": ["aek athens", "aek athen", "аек афины"],
    "mainz": ["mainz", "майнц"],
    "strasbourg": ["strasbourg", "страсбур"],
  };

  String? _strictUefaLeagueKey(String leagueName) {
    final l = leagueName.toLowerCase();
    if (l.contains("conference") || l.contains("конференц")) {
      return "conference";
    }
    if (l.contains("champions") || l.contains("чемпион")) return "champions";
    if (l.contains("europa") || l.contains("европ")) return "europa";
    return null;
  }

  String _normalizeStrictName(String value) {
    return value
        .toLowerCase()
        .replaceAll("ø", "o")
        .replaceAll("ö", "o")
        .replaceAll("ó", "o")
        .replaceAll("á", "a")
        .replaceAll("à", "a")
        .replaceAll("é", "e")
        .replaceAll("è", "e")
        .replaceAll("í", "i")
        .replaceAll("ï", "i")
        .replaceAll("ú", "u")
        .replaceAll("ü", "u")
        .replaceAll("ý", "y")
        .replaceAll("ň", "n")
        .replaceAll("ž", "z")
        .replaceAll("ç", "c")
        .replaceAll("ğ", "g")
        .replaceAll("ş", "s")
        .replaceAll("ć", "c")
        .replaceAll("ł", "l")
        .replaceAll("ё", "е")
        .replaceAll(RegExp(r"[^a-zа-я0-9]+"), " ")
        .trim();
  }

  bool _teamMatchesStrictToken(Team team, String token) {
    final name = _normalizeStrictName(team.name);
    return (_strictTeamAliases[token] ?? [token])
        .map(_normalizeStrictName)
        .any(name.contains);
  }

  bool _slotMatchesPair(_StrictUefaSlot slot, MatchPair pair) {
    final home = pair.firstLeg.homeTeam;
    final away = pair.firstLeg.awayTeam;
    return (_teamMatchesStrictToken(home, slot.homeToken) &&
            _teamMatchesStrictToken(away, slot.awayToken)) ||
        (_teamMatchesStrictToken(home, slot.awayToken) &&
            _teamMatchesStrictToken(away, slot.homeToken));
  }

  List<MatchPair>? _strictUefaStagePairs(
    List<MatchPair> pairs,
    String leagueName,
    String? stage, {
    String? side,
  }) {
    final leagueKey = _strictUefaLeagueKey(leagueName);
    if (leagueKey == null || stage == null) return null;

    final slots = (_strictUefaSlots[leagueKey] ?? [])
        .where((s) => s.stage == stage && (side == null || s.side == side))
        .toList();
    if (slots.isEmpty) return null;

    final usedPairs = <MatchPair>{};
    final result = <MatchPair>[];
    for (final slot in slots) {
      for (final pair in pairs) {
        if (!usedPairs.contains(pair) && _slotMatchesPair(slot, pair)) {
          usedPairs.add(pair);
          result.add(pair);
          break;
        }
      }
    }
    return result;
  }

  // --- СУПЕР СТРОГИЙ АЛГОРИТМ РАСПРЕДЕЛЕНИЯ КОМАНД ПО СЕТКЕ ---
  int _getStrictTeamOrder(Team t, String leagueName) {
    final n = t.name.toLowerCase();
    final l = leagueName.toLowerCase();

    // ЛИГА ЧЕМПИОНОВ
    if (l.contains("champions") || l.contains("чемпион")) {
      if (n.contains('psg') ||
          n.contains('псж') ||
          n.contains('monaco') ||
          n.contains('монако') ||
          n.contains('chelsea') ||
          n.contains('челси'))
        return 11;
      if (n.contains('juventus') ||
          n.contains('ювентус') ||
          n.contains('galatasaray') ||
          n.contains('галатасарай') ||
          n.contains('liverpool') ||
          n.contains('ливерпуль'))
        return 12;
      if (n.contains('real madrid') ||
          n.contains('реал') ||
          n.contains('benfica') ||
          n.contains('бенфика') ||
          n.contains('manchester city') ||
          n.contains('манчестер'))
        return 13;
      if (n.contains('atalanta') ||
          n.contains('аталанта') ||
          n.contains('dortmund') ||
          n.contains('боруссия') ||
          n.contains('bayern') ||
          n.contains('бавария'))
        return 14;

      if (n.contains('newcastle') ||
          n.contains('ньюкасл') ||
          n.contains('qarabag') ||
          n.contains('карабах') ||
          n.contains('barcelona') ||
          n.contains('барселона'))
        return 21;
      if (n.contains('atletico') ||
          n.contains('атлетико') ||
          n.contains('brugge') ||
          n.contains('брюгге') ||
          n.contains('tottenham') ||
          n.contains('тоттенхэм') ||
          n.contains('spurs'))
        return 22;
      if (n.contains('inter') ||
          n.contains('интер') ||
          n.contains('bodo') ||
          n.contains('буде') ||
          n.contains('glimt') ||
          n.contains('sporting') ||
          n.contains('спортинг'))
        return 23;
      if (n.contains('bayer') ||
          n.contains('байер') ||
          n.contains('olympiacos') ||
          n.contains('олимпиакос') ||
          n.contains('arsenal') ||
          n.contains('арсенал'))
        return 24;

      // ЛИГА ЕВРОПЫ
    } else if (l.contains("europa") || l.contains("европ")) {
      if (n.contains('ferencváros') ||
          n.contains('ferencvaros') ||
          n.contains('ференцварош') ||
          n.contains('ludogorets') ||
          n.contains('лудогорец') ||
          n.contains('braga') ||
          n.contains('брага'))
        return 11;
      if (n.contains('viktoria') ||
          n.contains('виктория') ||
          n.contains('plzen') ||
          n.contains('плзень') ||
          n.contains('panathinaikos') ||
          n.contains('панатинаикос') ||
          n.contains('betis') ||
          n.contains('бетис'))
        return 12;
      if (n.contains('genk') ||
          n.contains('генк') ||
          n.contains('zagreb') ||
          n.contains('загреб') ||
          n.contains('freiburg') ||
          n.contains('фрайбург'))
        return 13;
      if (n.contains('celta') ||
          n.contains('сельта') ||
          n.contains('paok') ||
          n.contains('паок') ||
          n.contains('lyon') ||
          n.contains('лион'))
        return 14;

      if (n.contains('stuttgart') ||
          n.contains('штутгарт') ||
          n.contains('celtic') ||
          n.contains('селтик') ||
          n.contains('portu') ||
          n.contains('porto') ||
          n.contains('порту'))
        return 21;
      if (n.contains('nottingham') ||
          n.contains('ноттингем') ||
          n.contains('fenerbahce') ||
          n.contains('фенербахче') ||
          n.contains('midtjylland') ||
          n.contains('митьюлланд'))
        return 22;
      if (n.contains('bologna') ||
          n.contains('болонья') ||
          n.contains('brann') ||
          n.contains('бранн') ||
          n.contains('roma') ||
          n.contains('рома'))
        return 23;
      if (n.contains('crvena') ||
          n.contains('црвена') ||
          n.contains('zvezda') ||
          n.contains('звезд') ||
          n.contains('lille') ||
          n.contains('лилль') ||
          n.contains('aston villa') ||
          n.contains('астон вилла'))
        return 24;

      // ЛИГА КОНФЕРЕНЦИЙ
    } else if (l.contains("conference") || l.contains("конференц")) {
      if (n.contains('lech') ||
          n.contains('лех') ||
          n.contains('kups') ||
          n.contains('купс') ||
          n.contains('shakhtar') ||
          n.contains('шахтер'))
        return 11;
      if (n.contains('alkmaar') ||
          n.contains('алкмаар') ||
          n.contains('noah') ||
          n.contains('noa') ||
          n.contains('ноа') ||
          n.contains('sparta') ||
          n.contains('спарта'))
        return 12;
      if (n.contains('crystal palace') ||
          n.contains('кристал') ||
          n.contains('zrinjski') ||
          n.contains('зриньски') ||
          n.contains('larnaca') ||
          n.contains('ларнака'))
        return 13;
      if (n.contains('fiorentina') ||
          n.contains('фиорентина') ||
          n.contains('jagiellonia') ||
          n.contains('ягеллония') ||
          n.contains('rakow') ||
          n.contains('ракув'))
        return 14;

      if (n.contains('samsunspor') ||
          n.contains('самсунспор') ||
          n.contains('shkendija') ||
          n.contains('шкендия') ||
          n.contains('rayo') ||
          n.contains('райо'))
        return 21;
      if (n.contains('celje') ||
          n.contains('целе') ||
          n.contains('drita') ||
          n.contains('дрита') ||
          n.contains('athens') ||
          n.contains('афины'))
        return 22;
      if (n.contains('lausanne') ||
          n.contains('лозанна') ||
          n.contains('sigma') ||
          n.contains('сигма') ||
          n.contains('mainz') ||
          n.contains('майнц'))
        return 23;
      if (n.contains('rijeka') ||
          n.contains('риека') ||
          n.contains('omonia') ||
          n.contains('омония') ||
          n.contains('strasbourg') ||
          n.contains('страсбур'))
        return 24;
    }

    if (n.contains('argentina') || n.contains('бразил') || n.contains('brazil'))
      return 11;
    if (n.contains('france') ||
        n.contains('франц') ||
        n.contains('england') ||
        n.contains('англи'))
      return 12;
    if (n.contains('spain') ||
        n.contains('испани') ||
        n.contains('germany') ||
        n.contains('германи'))
      return 13;
    if (n.contains('italy') ||
        n.contains('итали') ||
        n.contains('portugal') ||
        n.contains('португал'))
      return 14;

    return 99;
  }

  List<MatchPair> _getStagePairs(
    List<int> rounds,
    List<MatchModel> all,
    String leagueName, {
    String? uefaStageFilter,
  }) {
    Map<String, MatchPair> pairs = {};

    Iterable<MatchModel> filtered;
    if (uefaStageFilter != null) {
      filtered = all.where(
        (m) => _getUefaStageByDate(m.dateTime.toLocal()) == uefaStageFilter,
      );
    } else {
      filtered = all.where((m) => rounds.contains(m.round));
    }

    for (var m in filtered) {
      String key = ([m.homeTeam.id, m.awayTeam.id]..sort()).join("_");
      if (!pairs.containsKey(key)) {
        pairs[key] = MatchPair(m);
      } else {
        pairs[key]!.addMatch(m);
      }
    }
    final rawPairs = pairs.values.toList();
    final strictPairs = _strictUefaStagePairs(
      rawPairs,
      leagueName,
      uefaStageFilter,
    );
    if (strictPairs != null) return strictPairs;

    return rawPairs..sort((a, b) {
      int oA =
          _getStrictTeamOrder(a.firstLeg.homeTeam, leagueName) <
              _getStrictTeamOrder(a.firstLeg.awayTeam, leagueName)
          ? _getStrictTeamOrder(a.firstLeg.homeTeam, leagueName)
          : _getStrictTeamOrder(a.firstLeg.awayTeam, leagueName);
      int oB =
          _getStrictTeamOrder(b.firstLeg.homeTeam, leagueName) <
              _getStrictTeamOrder(b.firstLeg.awayTeam, leagueName)
          ? _getStrictTeamOrder(b.firstLeg.homeTeam, leagueName)
          : _getStrictTeamOrder(b.firstLeg.awayTeam, leagueName);
      return oA.compareTo(oB);
    });
  }

  Map<String, List<int>> _getPlayoffStages(String name, int maxR) {
    final lName = name.toLowerCase();
    // УЕФА фильтруется по дате, поэтому round тут игнорируется
    if (lName.contains("champions") ||
        lName.contains("europa") ||
        lName.contains("conference") ||
        name.contains("(UEFA)")) {
      return {"1/16": [], "1/8": [], "1/4": [], "1/2": [], "ФИНАЛ": []};
    }
    if (name.contains("(FIFA)")) {
      return {
        "1/8": [4],
        "1/4": [5],
        "1/2": [6],
        "ФИНАЛ": [7, 8],
      };
    }
    if (name.contains("(ENG-2)")) {
      return {
        "1/2": [47],
        "ФИНАЛ": [48],
      };
    }

    Map<String, List<int>> map = {};
    if (maxR > 0) {
      map["ФИНАЛ"] = [maxR];
      if (maxR - 1 > 0) map["1/2"] = [maxR - 1];
      if (maxR - 2 > 0) map["1/4"] = [maxR - 2];
      if (maxR - 3 > 0) map["1/8"] = [maxR - 3];
      if (maxR - 4 > 0) map["1/16"] = [maxR - 4];
      if (maxR - 5 > 0) map["1/32"] = [maxR - 5];
    } else {
      map["ФИНАЛ"] = [];
    }
    return map;
  }

  Widget _buildPlayoffTree(DataProvider data, AppCustomTheme theme) {
    int maxR = 0;
    for (var m in data.matches) {
      if (m.round > maxR) maxR = m.round;
    }
    String leagueName = data.selectedLeague?.name ?? "";
    final lName = leagueName.toLowerCase();
    bool isUefa =
        lName.contains("champions") ||
        lName.contains("europa") ||
        lName.contains("conference") ||
        leagueName.contains("(UEFA)");

    final stages = _getPlayoffStages(leagueName, maxR);

    if (!stages.containsKey(_activeStageFilter)) {
      _activeStageFilter = stages.keys.isNotEmpty ? stages.keys.first : "ФИНАЛ";
    }

    List<MatchPair> activePairs = [];
    if (stages.containsKey(_activeStageFilter)) {
      activePairs = _getStagePairs(
        stages[_activeStageFilter]!,
        data.matches,
        leagueName,
        uefaStageFilter: isUefa ? _activeStageFilter : null,
      );

      int limit = 16;
      if (_activeStageFilter == "1/32") limit = 32;
      if (_activeStageFilter == "1/16") limit = 8;
      if (_activeStageFilter == "1/8") limit = 8;
      if (_activeStageFilter == "1/4") limit = 4;
      if (_activeStageFilter == "1/2") limit = 2;
      if (_activeStageFilter == "ФИНАЛ") limit = 1;

      if (activePairs.length > limit) {
        activePairs = activePairs.sublist(0, limit);
      }
    }

    List<Widget> bottomCards = [];
    for (var p in activePairs) {
      bottomCards.add(
        _buildMatchCard(
          context,
          p.firstLeg,
          data,
          theme,
          subtitle: p.secondLeg != null ? "ПЕРВЫЙ МАТЧ" : null,
        ),
      );
      if (p.secondLeg != null) {
        bottomCards.add(
          _buildMatchCard(
            context,
            p.secondLeg!,
            data,
            theme,
            subtitle: "ОТВЕТНЫЙ МАТЧ",
          ),
        );
      }
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (stages.containsKey("1/32"))
                      _buildBracketColumn(
                        "1/32",
                        _getStagePairs(
                          stages["1/32"]!,
                          data.matches,
                          leagueName,
                          uefaStageFilter: isUefa ? "1/32" : null,
                        ),
                        theme,
                        leagueName,
                        side: "left",
                      ),
                    if (stages.containsKey("1/16"))
                      _buildBracketColumn(
                        "1/16",
                        _getStagePairs(
                          stages["1/16"]!,
                          data.matches,
                          leagueName,
                          uefaStageFilter: isUefa ? "1/16" : null,
                        ),
                        theme,
                        leagueName,
                        side: "left",
                      ),
                    if (stages.containsKey("1/8"))
                      _buildBracketColumn(
                        "1/8",
                        _getStagePairs(
                          stages["1/8"]!,
                          data.matches,
                          leagueName,
                          uefaStageFilter: isUefa ? "1/8" : null,
                        ),
                        theme,
                        leagueName,
                        side: "left",
                      ),
                    if (stages.containsKey("1/4"))
                      _buildBracketColumn(
                        "1/4",
                        _getStagePairs(
                          stages["1/4"]!,
                          data.matches,
                          leagueName,
                          uefaStageFilter: isUefa ? "1/4" : null,
                        ),
                        theme,
                        leagueName,
                        side: "left",
                      ),

                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBracketColumn(
                          "ФИНАЛ",
                          _getStagePairs(
                            stages["ФИНАЛ"]!,
                            data.matches,
                            leagueName,
                            uefaStageFilter: isUefa ? "ФИНАЛ" : null,
                          ),
                          theme,
                          leagueName,
                          isFinal: true,
                        ),
                        const SizedBox(height: 15),
                        if (stages.containsKey("1/2"))
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildBracketColumn(
                                "1/2",
                                _getStagePairs(
                                  stages["1/2"]!,
                                  data.matches,
                                  leagueName,
                                  uefaStageFilter: isUefa ? "1/2" : null,
                                ),
                                theme,
                                leagueName,
                                side: "left",
                              ),
                              const SizedBox(width: 4),
                              _buildBracketColumn(
                                "1/2",
                                _getStagePairs(
                                  stages["1/2"]!,
                                  data.matches,
                                  leagueName,
                                  uefaStageFilter: isUefa ? "1/2" : null,
                                ),
                                theme,
                                leagueName,
                                side: "right",
                              ),
                            ],
                          ),
                      ],
                    ),

                    if (stages.containsKey("1/4"))
                      _buildBracketColumn(
                        "1/4",
                        _getStagePairs(
                          stages["1/4"]!,
                          data.matches,
                          leagueName,
                          uefaStageFilter: isUefa ? "1/4" : null,
                        ),
                        theme,
                        leagueName,
                        side: "right",
                      ),
                    if (stages.containsKey("1/8"))
                      _buildBracketColumn(
                        "1/8",
                        _getStagePairs(
                          stages["1/8"]!,
                          data.matches,
                          leagueName,
                          uefaStageFilter: isUefa ? "1/8" : null,
                        ),
                        theme,
                        leagueName,
                        side: "right",
                      ),
                    if (stages.containsKey("1/16"))
                      _buildBracketColumn(
                        "1/16",
                        _getStagePairs(
                          stages["1/16"]!,
                          data.matches,
                          leagueName,
                          uefaStageFilter: isUefa ? "1/16" : null,
                        ),
                        theme,
                        leagueName,
                        side: "right",
                      ),
                    if (stages.containsKey("1/32"))
                      _buildBracketColumn(
                        "1/32",
                        _getStagePairs(
                          stages["1/32"]!,
                          data.matches,
                          leagueName,
                          uefaStageFilter: isUefa ? "1/32" : null,
                        ),
                        theme,
                        leagueName,
                        side: "right",
                      ),
                  ],
                ),
              ),
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: theme.headerBg,
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: stages.keys.map((s) {
                      bool isSelected = _activeStageFilter == s;
                      final activeTextColor = theme.onAccentColor;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(
                            s,
                            style: TextStyle(
                              color: isSelected
                                  ? activeTextColor
                                  : theme.textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          selectedColor: theme.accentColor,
                          backgroundColor: theme.dividerColor,
                          checkmarkColor: activeTextColor,
                          selected: isSelected,
                          onSelected: (v) {
                            setState(() => _activeStageFilter = s);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "МАТЧИ ЭТАПА: $_activeStageFilter",
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.dimTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(10),
            children: bottomCards.isNotEmpty
                ? bottomCards
                : [
                    Center(
                      child: Text(
                        "Нет матчей для этого этапа",
                        style: TextStyle(color: theme.dimTextColor),
                      ),
                    ),
                  ],
          ),
        ],
      ),
    );
  }

  Widget _buildBracketColumn(
    String title,
    List<MatchPair> pairs,
    AppCustomTheme theme,
    String leagueName, {
    String? side,
    bool isFinal = false,
  }) {
    List<MatchPair> toDisplay = [];
    final strictSidePairs = _strictUefaStagePairs(
      pairs,
      leagueName,
      title,
      side: side,
    );

    if (!isFinal && strictSidePairs != null) {
      toDisplay = strictSidePairs;
    } else if (isFinal) {
      toDisplay = pairs;
    } else {
      toDisplay = pairs.where((p) {
        int order = _getStrictTeamOrder(p.firstLeg.homeTeam, leagueName);
        if (order == 99) {
          order = _getStrictTeamOrder(p.firstLeg.awayTeam, leagueName);
        }
        if (order == 99) order = (p.firstLeg.id % 2 == 0) ? 15 : 25;
        bool isLeft = order < 20;
        return side == "left" ? isLeft : !isLeft;
      }).toList();
    }

    int limit = 8;
    if (title == "1/32") limit = 16;
    if (title == "1/16") limit = 4;
    if (title == "1/8") limit = 4;
    if (title == "1/4") limit = 2;
    if (title == "1/2") limit = 1;
    if (title == "ФИНАЛ") limit = 1;

    if (toDisplay.length > limit) {
      toDisplay = toDisplay.sublist(0, limit);
    }

    return Container(
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 10),
          ...toDisplay.map((p) => _buildPairCard(p, theme)).toList(),
          if (toDisplay.isEmpty)
            Container(
              height: 60,
              width: 110,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPairCard(MatchPair p, AppCustomTheme theme) {
    final m = p.secondLeg ?? p.firstLeg;
    final bool hasAgg = p.secondLeg != null;
    int? aggH, aggA;
    if (hasAgg) {
      aggH = (p.secondLeg!.homeTeam.id == p.firstLeg.homeTeam.id)
          ? ((p.firstLeg.scoreHome ?? 0) + (p.secondLeg!.scoreHome ?? 0))
          : ((p.firstLeg.scoreAway ?? 0) + (p.secondLeg!.scoreHome ?? 0));
      aggA = (p.secondLeg!.awayTeam.id == p.firstLeg.awayTeam.id)
          ? ((p.firstLeg.scoreAway ?? 0) + (p.secondLeg!.scoreAway ?? 0))
          : ((p.firstLeg.scoreHome ?? 0) + (p.secondLeg!.scoreAway ?? 0));
    }
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MatchDetailScreen(match: m)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.cardBorder),
        ),
        child: Column(
          children: [
            _bracketRow(m.homeTeam, m.scoreHome, hasAgg ? aggH : null, theme),
            const SizedBox(height: 4),
            _bracketRow(m.awayTeam, m.scoreAway, hasAgg ? aggA : null, theme),
          ],
        ),
      ),
    );
  }

  Widget _bracketRow(Team t, int? s, int? agg, AppCustomTheme theme) {
    return Row(
      children: [
        Expanded(
          child: TeamLink(
            team: t,
            child: Row(
              children: [
                _buildLogo(t.logoUrl, theme, size: 16, padding: 2),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    tr(t.name),
                    style: TextStyle(fontSize: 8, color: theme.textColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        Text(
          "${s ?? ''}${agg != null ? ' ($agg)' : ''}",
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
      ],
    );
  }

  // МЕТОД ПЕРЕРАСЧЕТА ЕВРОКУБКОВ (ограничение только до групповых матчей)
  List<UITableRow> _calculateUefaStandings(
    List<StandingRow> baseStandings,
    List<MatchModel> allMatches,
    int limit,
  ) {
    Map<int, Map<String, dynamic>> stats = {};

    // Инициализируем команды
    for (var row in baseStandings) {
      stats[row.team.id] = {
        'team': row.team,
        'played': 0,
        'won': 0,
        'draw': 0,
        'lost': 0,
        'gf': 0,
        'ga': 0,
        'pts': 0,
        'form': <String>[],
        'matches': <MatchModel>[],
      };
    }

    // Раскидываем все матчи по командам
    for (var m in allMatches) {
      if (stats.containsKey(m.homeTeam.id))
        stats[m.homeTeam.id]!['matches'].add(m);
      if (stats.containsKey(m.awayTeam.id))
        stats[m.awayTeam.id]!['matches'].add(m);
    }

    List<UITableRow> result = [];

    for (var entry in stats.entries) {
      var s = entry.value;
      List<MatchModel> teamMatches = s['matches'];
      // Сортируем строго по дате
      teamMatches.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      int count = 0;
      for (var m in teamMatches) {
        if (count >= limit) break; // Считаем только первые N матчей (группа)
        if (m.status == 'FINISHED') {
          s['played'] += 1;
          int gf = (m.homeTeam.id == entry.key)
              ? (m.scoreHome ?? 0)
              : (m.scoreAway ?? 0);
          int ga = (m.homeTeam.id == entry.key)
              ? (m.scoreAway ?? 0)
              : (m.scoreHome ?? 0);
          s['gf'] += gf;
          s['ga'] += ga;

          if (gf > ga) {
            s['won'] += 1;
            s['pts'] += 3;
            s['form'].add('W');
          } else if (gf == ga) {
            s['draw'] += 1;
            s['pts'] += 1;
            s['form'].add('D');
          } else {
            s['lost'] += 1;
            s['form'].add('L');
          }
        }
        count++; // Учитываем матч, даже если он запланирован, чтобы отсечь плей-офф
      }
    }

    var listStats = stats.values.toList();
    // Сортировка таблицы: очки -> разница мячей -> забитые -> алфавит
    listStats.sort((a, b) {
      if (a['pts'] != b['pts'])
        return (b['pts'] as int).compareTo(a['pts'] as int);
      int gdA = (a['gf'] as int) - (a['ga'] as int);
      int gdB = (b['gf'] as int) - (b['ga'] as int);
      if (gdA != gdB) return gdB.compareTo(gdA);
      if (a['gf'] != b['gf']) return (b['gf'] as int).compareTo(a['gf'] as int);
      return (a['team'] as Team).name.compareTo((b['team'] as Team).name);
    });

    for (int i = 0; i < listStats.length; i++) {
      var s = listStats[i];
      List<String> form = s['form'];
      if (form.length > 5) form = form.sublist(form.length - 5);
      result.add(
        UITableRow(
          rank: i + 1,
          team: s['team'],
          played: s['played'],
          won: s['won'],
          draw: s['draw'],
          lost: s['lost'],
          goalsFor: s['gf'],
          goalsAgainst: s['ga'],
          points: s['pts'],
          form: form,
          groupName: "ТАБЛИЦА",
        ),
      );
    }

    return result;
  }

  Widget _buildStandingsList(
    DataProvider data,
    AppCustomTheme theme,
    bool isBigTable, {
    bool isUefa = false,
    int uefaMatchLimit = 8,
  }) {
    if (data.currentStandings.isEmpty) {
      return Center(
        child: Text(
          "Загрузка таблицы...",
          style: TextStyle(color: theme.dimTextColor),
        ),
      );
    }

    List<UITableRow> uiRows = [];

    if (isUefa) {
      uiRows = _calculateUefaStandings(
        data.currentStandings,
        data.matches,
        uefaMatchLimit,
      );
    } else {
      uiRows = data.currentStandings
          .map(
            (r) => UITableRow(
              rank: r.rank,
              team: r.team,
              played: r.played,
              won: r.won,
              draw: r.draw,
              lost: r.lost,
              goalsFor: r.goalsFor,
              goalsAgainst: r.goalsAgainst,
              points: r.points,
              form: r.form.map((e) => e.toString()).toList(),
              groupName: r.groupName ?? "Таблица",
            ),
          )
          .toList();
    }

    Map<String, List<UITableRow>> groups = {};
    for (var row in uiRows) {
      String g = row.groupName;
      if (!groups.containsKey(g)) groups[g] = [];
      groups[g]!.add(row);
    }

    if (isBigTable && groups.length == 1) {
      return Container(
        margin: const EdgeInsets.all(8),
        decoration: theme.panel(),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) =>
              _buildDynamicTable(groups.values.first, theme, constraints),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: groups.entries.map((entry) {
          return Card(
            margin: const EdgeInsets.all(8),
            child: Column(
              children: [
                if (groups.length > 1 || entry.key != "Таблица")
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: theme.dividerColor,
                    child: Text(
                      entry.key.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                _buildStaticTable(entry.value, theme),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _tableTeamCell(
    Team team,
    AppCustomTheme theme, {
    required double fontSize,
    required double logoSize,
  }) => Expanded(
    child: TeamLink(
      team: team,
      child: Row(
        children: [
          _buildLogo(team.logoUrl, theme, size: logoSize, padding: 0),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              tr(team.name),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: theme.textColor,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildDynamicTable(
    List<UITableRow> rows,
    AppCustomTheme theme,
    BoxConstraints constraints,
  ) {
    double totalH = constraints.maxHeight;
    double headerH = 30.0;

    double exactRowH = (totalH - headerH) / rows.length;
    if (exactRowH < 22.0) exactRowH = 22.0;

    double fontSize = (exactRowH * 0.35).clamp(9.0, 14.0);
    double logoSize = (exactRowH * 0.6).clamp(14.0, 26.0);
    double numW = (fontSize * 1.8).clamp(16.0, 22.0);
    double goalW = (fontSize * 2.2).clamp(20.0, 28.0);

    Widget headerCell(String text, double w) => SizedBox(
      width: w,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: theme.dimTextColor, fontSize: 10),
      ),
    );
    Widget cell(String text, double w, {bool bold = false, Color? color}) =>
        SizedBox(
          width: w,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color ?? theme.dimTextColor,
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );

    return Column(
      children: [
        Container(
          height: headerH,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          color: theme.headerBg,
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: Text(
                  "#",
                  style: TextStyle(color: theme.dimTextColor, fontSize: 10),
                ),
              ),
              Expanded(
                child: Text(
                  " Команда",
                  style: TextStyle(color: theme.dimTextColor, fontSize: 10),
                ),
              ),
              headerCell("И", numW),
              headerCell("В", numW),
              headerCell("Н", numW),
              headerCell("П", numW),
              headerCell("ЗМ", goalW),
              headerCell("ПМ", goalW),
              headerCell("РМ", goalW),
              headerCell("О", goalW),
              SizedBox(
                width: 60,
                child: Text(
                  "Форма",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.dimTextColor, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const ClampingScrollPhysics(),
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              return Container(
                height: exactRowH,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: theme.dividerColor)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      child: Text(
                        "${row.rank}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                    _tableTeamCell(
                      row.team,
                      theme,
                      fontSize: fontSize,
                      logoSize: logoSize,
                    ),
                    cell("${row.played}", numW, color: theme.textColor),
                    cell("${row.won}", numW, color: theme.textColor),
                    cell("${row.draw}", numW, color: theme.textColor),
                    cell("${row.lost}", numW, color: theme.textColor),
                    cell("${row.goalsFor}", goalW, color: theme.textColor),
                    cell("${row.goalsAgainst}", goalW, color: theme.textColor),
                    cell(
                      "${row.goalsFor - row.goalsAgainst}",
                      goalW,
                      color: theme.textColor,
                    ),
                    cell(
                      "${row.points}",
                      goalW,
                      color: theme.accentColor,
                      bold: true,
                    ),
                    SizedBox(
                      width: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: row.form.map((res) {
                          Color c = Colors.grey;
                          if (res == 'W') c = Colors.green;
                          if (res == 'L') c = Colors.red;
                          return Container(
                            margin: const EdgeInsets.only(left: 2),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStaticTable(List<UITableRow> rows, AppCustomTheme theme) {
    Widget cell(String text, double w, {bool bold = false, Color? color}) =>
        SizedBox(
          width: w,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color ?? theme.dimTextColor,
              fontSize: 10,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          color: theme.headerBg,
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: Text(
                  "#",
                  style: TextStyle(color: theme.dimTextColor, fontSize: 10),
                ),
              ),
              Expanded(
                child: Text(
                  " Команда",
                  style: TextStyle(color: theme.dimTextColor, fontSize: 10),
                ),
              ),
              cell("И", 16),
              cell("В", 16),
              cell("Н", 16),
              cell("П", 16),
              cell("ЗМ", 20),
              cell("ПМ", 20),
              cell("РМ", 20),
              cell("О", 20),
              SizedBox(
                width: 60,
                child: Text(
                  "Форма",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.dimTextColor, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      "${row.rank}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  _tableTeamCell(row.team, theme, fontSize: 11, logoSize: 18),
                  cell("${row.played}", 16, color: theme.textColor),
                  cell("${row.won}", 16, color: theme.textColor),
                  cell("${row.draw}", 16, color: theme.textColor),
                  cell("${row.lost}", 16, color: theme.textColor),
                  cell("${row.goalsFor}", 20, color: theme.textColor),
                  cell("${row.goalsAgainst}", 20, color: theme.textColor),
                  cell(
                    "${row.goalsFor - row.goalsAgainst}",
                    20,
                    color: theme.textColor,
                  ),
                  cell(
                    "${row.points}",
                    20,
                    color: theme.accentColor,
                    bold: true,
                  ),
                  SizedBox(
                    width: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: row.form.map((res) {
                        Color c = Colors.grey;
                        if (res == 'W') c = Colors.green;
                        if (res == 'L') c = Colors.red;
                        return Container(
                          margin: const EdgeInsets.only(left: 2),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRoundsTab(
    List<MatchModel> matches,
    int safeMaxRounds,
    int safeValue,
    DataProvider data,
    AppCustomTheme theme,
  ) {
    return Column(
      children: [
        RoundSelector(
          current: safeValue,
          total: safeMaxRounds,
          onChanged: data.setSelectedRound,
        ),
        Expanded(
          child: matches.isEmpty
              ? Center(
                  child: Text(
                    "Матчи не найдены",
                    style: TextStyle(color: theme.dimTextColor),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: matches.length,
                  itemBuilder: (context, index) =>
                      _buildMatchCard(context, matches[index], data, theme),
                ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(DataProvider data, AppCustomTheme theme) {
    final finished = data.matches
        .where((m) => m.status == "FINISHED")
        .toList()
        .reversed
        .take(5)
        .toList();
    final upcoming = data.matches
        .where((m) => m.status == "SCHEDULED")
        .toList()
        .take(5)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        if (finished.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              "Недавние игры",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textColor,
                fontSize: 16,
              ),
            ),
          ),
          ...finished
              .map((m) => _buildMatchCard(context, m, data, theme))
              .toList(),
        ],
        if (upcoming.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 20, bottom: 10),
            child: Text(
              "Предстоящие матчи",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textColor,
                fontSize: 16,
              ),
            ),
          ),
          ...upcoming
              .map((m) => _buildMatchCard(context, m, data, theme))
              .toList(),
        ],
      ],
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    DataProvider data,
    AppCustomTheme theme,
  ) {
    Color drawerTitleColor = theme.cardBg.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
    return Drawer(
      backgroundColor: theme.scaffoldBg,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.cardBg),
            child: Center(
              child: Text(
                "FUTRAT",
                style: TextStyle(
                  color: drawerTitleColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.today, color: theme.textColor),
            title: Text(
              "Матчи сегодня",
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              data.selectLeague(data.todayVirtual);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.play_circle_fill,
              color: Colors.redAccent,
            ),
            title: Text(
              "Матчи сейчас",
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              data.selectLeague(data.liveVirtual);
              Navigator.pop(context);
            },
          ),
          Divider(color: theme.dividerColor),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: data.tournaments.length,
              itemBuilder: (ctx, i) {
                final t = data.tournaments[i];
                final isSel = t.id == data.selectedLeague?.id;
                final isFav = data.isLeagueFavorite(t.id);
                String drawerName = t.name.replaceAll(
                  RegExp(r'\s*\([^)]*\)'),
                  '',
                );
                return ListTile(
                  leading: _buildLogo(t.logoUrl, theme, size: 36, padding: 4),
                  title: Text(
                    drawerName,
                    style: TextStyle(
                      color: isSel ? theme.accentColor : theme.textColor,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      isFav ? Icons.star : Icons.star_border,
                      color: isFav ? Colors.amber : theme.dimTextColor,
                    ),
                    onPressed: () => runAuthenticatedAction(
                      context,
                      action: 'добавить лигу в избранное',
                      onAuthenticated: (resumed) async {
                        if (resumed && data.isLeagueFavorite(t.id)) return;
                        await data.toggleTournamentFavorite(t.id);
                      },
                    ),
                  ),
                  onTap: () {
                    data.selectLeague(t);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(
    BuildContext context,
    MatchModel match,
    DataProvider data,
    AppCustomTheme theme, {
    String? subtitle,
  }) {
    final isHomeFav = data.isTeamFavorite(match.homeTeam.id);
    final isAwayFav = data.isTeamFavorite(match.awayTeam.id);

    final isLive = match.isLive;
    String displayStatus = match.status;

    if (match.status == 'SCHEDULED') {
      displayStatus = DateFormat('dd.MM.yyyy').format(match.dateTime.toLocal());
    } else if (match.status == 'FINISHED') {
      displayStatus = 'ЗАВЕРШЕН';
    } else if (match.status == 'DELAYED') {
      displayStatus = 'ОТЛОЖЕН';
    } else if (match.needsStatusCheck) {
      displayStatus = 'СТАТУС УТОЧНЯЕТСЯ';
    } else if (isLive) {
      displayStatus = match.liveLabel;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MatchDetailScreen(match: match)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.cardBorder),
        ),
        child: Column(
          children: [
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.dimTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => runAuthenticatedAction(
                          context,
                          action: 'добавить команду в избранное',
                          onAuthenticated: (resumed) async {
                            if (resumed &&
                                data.isTeamFavorite(match.homeTeam.id))
                              return;
                            await data.toggleTeamFavorite(match.homeTeam.id);
                          },
                        ),
                        child: Icon(
                          isHomeFav ? Icons.star : Icons.star_border,
                          color: isHomeFav ? Colors.amber : theme.dimTextColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLogo(match.homeTeam.logoUrl, theme, size: 45),
                          const SizedBox(height: 8),
                          Text(
                            tr(match.homeTeam.name),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 85,
                  child: Column(
                    children: [
                      Text(
                        (match.status == 'SCHEDULED' ||
                                match.status == 'DELAYED')
                            ? DateFormat(
                                'HH:mm',
                              ).format(match.dateTime.toLocal())
                            : "${match.scoreHome ?? 0} - ${match.scoreAway ?? 0}",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayStatus,
                        style: TextStyle(
                          fontSize: 10,
                          color: isLive
                              ? Colors.redAccent
                              : (match.status == 'DELAYED'
                                    ? Colors.orange
                                    : theme.accentColor),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => runAuthenticatedAction(
                          context,
                          action: 'добавить команду в избранное',
                          onAuthenticated: (resumed) async {
                            if (resumed &&
                                data.isTeamFavorite(match.awayTeam.id))
                              return;
                            await data.toggleTeamFavorite(match.awayTeam.id);
                          },
                        ),
                        child: Icon(
                          isAwayFav ? Icons.star : Icons.star_border,
                          color: isAwayFav ? Colors.amber : theme.dimTextColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLogo(match.awayTeam.logoUrl, theme, size: 45),
                          const SizedBox(height: 8),
                          Text(
                            tr(match.awayTeam.name),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(
    String? url,
    AppCustomTheme theme, {
    double size = 45,
    double padding = 6,
  }) {
    return FootballLogo(url: url, size: size, padding: padding, framed: true);
  }
}

class MatchPair {
  late MatchModel firstLeg;
  MatchModel? secondLeg;
  MatchPair(MatchModel m) {
    firstLeg = m;
  }
  void addMatch(MatchModel m) {
    if (m.dateTime.isAfter(firstLeg.dateTime)) {
      secondLeg = m;
    } else {
      secondLeg = firstLeg;
      firstLeg = m;
    }
  }
}

class _StrictUefaSlot {
  final String stage;
  final String side;
  final String homeToken;
  final String awayToken;

  const _StrictUefaSlot(this.stage, this.side, this.homeToken, this.awayToken);
}

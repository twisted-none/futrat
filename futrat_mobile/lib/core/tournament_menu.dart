import '../models/all_models.dart';
import '../providers/tournament_menu_preferences.dart';

class TournamentMenuGroup {
  TournamentMenuGroup(this.code, this.title, this.favorite, this.leagues);
  final String code, title;
  final bool favorite;
  final List<Tournament> leagues;
  String get key => '${favorite ? 'favorite' : 'other'}:$code';
  String get zone => '${favorite ? 'favorite' : 'other'}:groups';
}

String menuLeagueKey(Tournament league) => league.apiCode ?? 'id:${league.id}';

const _national = {
  'fifa.world',
  'fifa.friendly',
  'uefa.nations',
  'caf.nations',
  'uefa.euroq',
  'uefa.euro',
};
const _european = {
  'uefa.champions',
  'uefa.europa',
  'uefa.europa.conf',
  'uefa.super_cup',
};
const _countries = {
  'eng': 'Англия',
  'esp': 'Испания',
  'ger': 'Германия',
  'ita': 'Италия',
  'fra': 'Франция',
  'rus': 'Россия',
  'ned': 'Нидерланды',
  'por': 'Португалия',
  'tur': 'Турция',
  'ksa': 'Саудовская Аравия',
  'usa': 'США',
};
const _countryCodes = {
  'england': 'eng',
  'spain': 'esp',
  'germany': 'ger',
  'italy': 'ita',
  'france': 'fra',
  'russia': 'rus',
  'netherlands': 'ned',
  'portugal': 'por',
  'turkey': 'tur',
  'saudi arabia': 'ksa',
  'usa': 'usa',
  'united states': 'usa',
};

(String, String) _group(Tournament league) {
  final code = league.apiCode ?? '';
  // National UEFA competitions must be classified before club competitions.
  if (_national.contains(code)) return ('national', 'Сборные');
  if (_european.contains(code)) return ('european', 'Еврокубки');
  final prefix = code.split('.').first;
  if (_countries.containsKey(prefix)) return (prefix, _countries[prefix]!);
  final country = league.country?.trim() ?? '';
  final known = _countryCodes[country.toLowerCase()];
  if (known != null) return (known, _countries[known]!);
  if (country.isNotEmpty && country.toLowerCase() != 'global') {
    return (country.toLowerCase(), country);
  }
  return ('other', 'Другие турниры');
}

List<TournamentMenuGroup> tournamentMenuGroups(
  List<Tournament> leagues,
  Set<int> favorites,
  TournamentMenuPreferences preferences,
) {
  final result = <TournamentMenuGroup>[];
  for (final favorite in [true, false]) {
    final groups = <String, TournamentMenuGroup>{};
    for (final league in leagues) {
      if (league.id < 0 || favorites.contains(league.id) != favorite) continue;
      final (code, title) = _group(league);
      groups
          .putIfAbsent(
            code,
            () => TournamentMenuGroup(code, title, favorite, []),
          )
          .leagues
          .add(league);
    }
    for (final group in groups.values) {
      final sorted = preferences.ordered(
        group.key,
        group.leagues,
        menuLeagueKey,
      );
      group.leagues
        ..clear()
        ..addAll(sorted);
    }
    result.addAll(
      preferences.ordered(
        '${favorite ? 'favorite' : 'other'}:groups',
        groups.values,
        (group) => group.code,
      ),
    );
  }
  return result;
}

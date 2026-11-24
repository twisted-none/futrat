import '../models/all_models.dart';

class _Role {
  const _Role(this.line, this.side);
  final int line, side;
}

_Role? _role(String position) {
  final text = position.toLowerCase().replaceAll(RegExp('[^a-z]'), '');
  if (['goalkeeper', 'keeper', 'gk', 'g'].contains(text)) {
    return const _Role(0, 0);
  }
  final left =
      text.contains('left') ||
      [
        'lb',
        'lcb',
        'lwb',
        'ldm',
        'lcm',
        'lm',
        'lam',
        'lw',
        'lf',
      ].contains(text);
  final right =
      text.contains('right') ||
      [
        'rb',
        'rcb',
        'rwb',
        'rdm',
        'rcm',
        'rm',
        'ram',
        'rw',
        'rf',
      ].contains(text);
  final center =
      text.contains('center') ||
      text.contains('central') ||
      ['lcb', 'rcb', 'lcm', 'rcm'].contains(text);
  final side = left
      ? (center ? -1 : -2)
      : right
      ? (center ? 1 : 2)
      : 0;
  final int line;
  if (text.contains('wingback') || ['lwb', 'rwb'].contains(text)) {
    line = 15;
  } else if (text.contains('back') ||
      text.contains('defender') ||
      ['lb', 'rb', 'cb', 'lcb', 'rcb'].contains(text)) {
    line = 10;
  } else if (text.contains('defensivemidfield') ||
      ['dm', 'cdm', 'ldm', 'rdm'].contains(text)) {
    line = 20;
  } else if (text.contains('attackingmidfield') ||
      ['am', 'cam', 'lam', 'ram'].contains(text)) {
    line = 40;
  } else if (text.contains('midfield') ||
      ['cm', 'lcm', 'rcm', 'lm', 'rm'].contains(text)) {
    line = 30;
  } else if (text.contains('secondstriker') || text == 'ss') {
    line = 45;
  } else if (text.contains('forward') ||
      text.contains('striker') ||
      text.contains('winger') ||
      ['f', 'st', 'cf', 'lf', 'rf', 'lw', 'rw'].contains(text)) {
    line = 50;
  } else {
    return null;
  }
  return _Role(line, side);
}

/// Rows run from goalkeeper to attack, left-to-right facing up the pitch.
/// Provider tactical/jersey numbers are never treated as sequential grid slots.
List<List<LineupPlayer>>? confirmedLineupRows(
  List<LineupPlayer> players,
  String? formation,
) {
  if (formation == null ||
      !RegExp(r'^\d(?:-\d){1,4}$').hasMatch(formation) ||
      players.length != 11 ||
      players.map((p) => p.id).toSet().length != 11) {
    return null;
  }
  final counts = [1, ...formation.split('-').map(int.parse)];
  if (counts.any((n) => n <= 0) || counts.reduce((a, b) => a + b) != 11) {
    return null;
  }
  final roles = <int, _Role>{};
  for (final player in players) {
    final role = _role(player.position);
    if (role == null) return null;
    roles[player.id] = role;
  }
  final ordered = [...players]
    ..sort((a, b) => roles[a.id]!.line.compareTo(roles[b.id]!.line));
  if (roles[ordered.first.id]!.line != 0 || roles[ordered[1].id]!.line == 0) {
    return null;
  }
  final rows = <List<LineupPlayer>>[];
  var offset = 0;
  for (final count in counts) {
    final end = offset + count;
    // Splitting indistinguishable role groups between formation lines would
    // invent which player plays deeper, so fall back to the list instead.
    if (end < 11 &&
        roles[ordered[end - 1].id]!.line == roles[ordered[end].id]!.line) {
      return null;
    }
    final row = ordered.sublist(offset, end);
    if (row.map((p) => roles[p.id]!.side).toSet().length != count) return null;
    row.sort((a, b) => roles[a.id]!.side.compareTo(roles[b.id]!.side));
    rows.add(row);
    offset = end;
  }
  // A formation's first outfield line must actually consist of defenders.
  if (rows[1].any((p) => ![10, 15].contains(roles[p.id]!.line))) return null;
  return rows;
}

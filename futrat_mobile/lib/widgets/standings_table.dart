import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/translator.dart';
import '../models/all_models.dart';
import 'football_logo.dart';
import 'team_link.dart';

class StandingsEntry {
  const StandingsEntry({
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
  });
  final int rank, played, won, draw, lost, goalsFor, goalsAgainst, points;
  final Team team;
  final List<String> form;
}

/// One vertical scroll outside this widget; the club column stays visible while
/// all numerical columns share one horizontal scroll.
class StandingsTable extends StatelessWidget {
  const StandingsTable({super.key, required this.rows});
  final List<StandingsEntry> rows;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final colors = Theme.of(context).colorScheme;
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final rowHeight = math.max(56.0, 14 * scale * 2.7 + 16);
      final pinnedWidth = (constraints.maxWidth * .54)
          .clamp(132.0, 250.0)
          .toDouble();
      final numberWidth = math.max(48.0, 38 * scale);
      final headerHeight = math.max(48.0, 18 * scale + 20);
      Widget cell(
        String label, {
        required double width,
        bool header = false,
        bool primary = false,
      }) => Container(
        width: width,
        height: header ? headerHeight : rowHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          color: header ? colors.surfaceContainerHighest : null,
        ),
        child: Text(
          label,
          style: AppTheme.numberStyle.copyWith(
            fontSize: header ? 12 : 14,
            color: primary
                ? colors.primary
                : header
                ? colors.onSurfaceVariant
                : colors.onSurface,
            fontWeight: primary ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      );
      const columns = [
        ('И', 'Игры'),
        ('О', 'Очки'),
        ('В', 'Победы'),
        ('Н', 'Ничьи'),
        ('П', 'Поражения'),
        ('ЗМ', 'Забитые мячи'),
        ('ПМ', 'Пропущенные мячи'),
        ('РМ', 'Разница мячей'),
      ];
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: pinnedWidth,
            child: Column(
              children: [
                Container(
                  height: headerHeight,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  color: colors.surfaceContainerHighest,
                  child: Text(
                    'Команда',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                for (final row in rows)
                  Container(
                    height: rowHeight,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: colors.outlineVariant),
                      ),
                    ),
                    child: TeamLink(
                      team: row.team,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text(
                                '${row.rank}',
                                style: AppTheme.numberStyle.copyWith(
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            FootballLogo(url: row.team.logoUrl, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Tooltip(
                                message: tr(row.team.name),
                                child: Text(
                                  tr(row.team.name),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              key: const PageStorageKey('standings-columns'),
              child: Column(
                children: [
                  Row(
                    children: [
                      for (final col in columns)
                        Tooltip(
                          message: col.$2,
                          child: cell(col.$1, width: numberWidth, header: true),
                        ),
                      cell('Форма', width: 160 * scale, header: true),
                    ],
                  ),
                  for (final row in rows)
                    Row(
                      children: [
                        for (final value in [
                          row.played,
                          row.points,
                          row.won,
                          row.draw,
                          row.lost,
                          row.goalsFor,
                          row.goalsAgainst,
                          row.goalsFor - row.goalsAgainst,
                        ].indexed)
                          cell(
                            '${value.$2}',
                            width: numberWidth,
                            primary: value.$1 == 1,
                          ),
                        Container(
                          width: 160 * scale,
                          height: rowHeight,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: colors.outlineVariant),
                            ),
                          ),
                          child: row.form.isEmpty
                              ? const Text('—')
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (final result in row.form.take(5))
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        child: Text(
                                          const {
                                                'W': 'В',
                                                'D': 'Н',
                                                'L': 'П',
                                              }[result] ??
                                              result,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: result == 'L'
                                                ? colors.error
                                                : colors.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

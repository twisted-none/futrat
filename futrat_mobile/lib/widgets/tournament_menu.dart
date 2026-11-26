import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/auth_gate.dart';
import '../core/tournament_menu.dart';
import '../models/all_models.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/tournament_menu_preferences.dart';
import 'football_logo.dart';

class TournamentDrawer extends StatelessWidget {
  const TournamentDrawer({super.key});
  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final theme = context.watch<ThemeProvider>().currentTheme;
    final user = context.watch<AuthProvider>().currentUser;
    final scope = user == null ? 'guest' : 'user-${user.id}';
    return Drawer(
      backgroundColor: theme.scaffoldBg,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Image.asset('assets/icon.png', width: 32, height: 32),
                  const SizedBox(width: 12),
                  Text(
                    'FUTRAT',
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final item in [
            (data.todayVirtual, Icons.today),
            (data.liveVirtual, Icons.play_circle_fill),
          ])
            ListTile(
              leading: Icon(
                item.$2,
                color: item.$1.id == -2 ? Colors.redAccent : theme.textColor,
              ),
              title: Text(
                item.$1.name,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                data.selectLeague(item.$1);
                Navigator.pop(context);
              },
            ),
          Divider(color: theme.dividerColor),
          Expanded(
            child: _SavedTournamentMenu(
              key: ValueKey(scope),
              scope: scope,
              data: data,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedTournamentMenu extends StatefulWidget {
  const _SavedTournamentMenu({
    super.key,
    required this.scope,
    required this.data,
    required this.theme,
  });
  final String scope;
  final DataProvider data;
  final AppCustomTheme theme;
  @override
  State<_SavedTournamentMenu> createState() => _SavedTournamentMenuState();
}

class _SavedTournamentMenuState extends State<_SavedTournamentMenu> {
  late final preferences = TournamentMenuPreferences(scope: widget.scope);
  @override
  void dispose() {
    preferences.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TournamentMenu(
    tournaments: widget.data.tournaments,
    favoriteIds: widget.data.tournaments
        .where((t) => widget.data.isLeagueFavorite(t.id))
        .map((t) => t.id)
        .toSet(),
    selectedId: widget.data.selectedLeague?.id,
    preferences: preferences,
    theme: widget.theme,
    onSelect: (league) {
      widget.data.selectLeague(league);
      Navigator.pop(context);
    },
    onFavorite: (league) => runAuthenticatedAction(
      context,
      action: 'добавить лигу в избранное',
      onAuthenticated: (resumed) async {
        if (resumed && widget.data.isLeagueFavorite(league.id)) return;
        await widget.data.toggleTournamentFavorite(league.id);
      },
    ),
  );
}

class _MenuDrag {
  const _MenuDrag(this.zone, this.id);
  final String zone, id;
}

class TournamentMenu extends StatefulWidget {
  const TournamentMenu({
    super.key,
    required this.tournaments,
    required this.favoriteIds,
    required this.selectedId,
    required this.preferences,
    required this.theme,
    required this.onSelect,
    required this.onFavorite,
  });
  final List<Tournament> tournaments;
  final Set<int> favoriteIds;
  final int? selectedId;
  final TournamentMenuPreferences preferences;
  final AppCustomTheme theme;
  final ValueChanged<Tournament> onSelect, onFavorite;
  @override
  State<TournamentMenu> createState() => _TournamentMenuState();
}

class _TournamentMenuState extends State<TournamentMenu> {
  final _scroll = ScrollController();
  final _viewport = GlobalKey();
  Timer? _autoScroll;
  Offset? _pointer;

  @override
  void dispose() {
    _stopDrag();
    _scroll.dispose();
    super.dispose();
  }

  void _stopDrag() {
    _autoScroll?.cancel();
    _pointer = null;
  }

  void _startDrag() {
    _autoScroll?.cancel();
    _autoScroll = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final box = _viewport.currentContext?.findRenderObject();
      if (!_scroll.hasClients ||
          _pointer == null ||
          box is! RenderBox ||
          !box.attached) {
        return;
      }
      final y = box.globalToLocal(_pointer!).dy;
      final step = y < 48
          ? -12.0
          : y > box.size.height - 48
          ? 12.0
          : 0.0;
      if (step != 0) {
        _scroll.jumpTo(
          (_scroll.offset + step).clamp(0.0, _scroll.position.maxScrollExtent),
        );
      }
    });
  }

  Widget _movable(
    String zone,
    String id,
    List<String> siblings,
    String label,
    Widget child, {
    VoidCallback? onTap,
  }) {
    final index = siblings.indexOf(id);
    return GestureDetector(
      // Keep the enclosing Drawer from claiming horizontal motion while the
      // user is waiting for the hold delay. Vertical scrolling still competes.
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (_) {},
      child: DragTarget<_MenuDrag>(
        onWillAcceptWithDetails: (details) =>
            details.data.zone == zone &&
            details.data.id != id &&
            siblings.contains(details.data.id),
        onAcceptWithDetails: (details) =>
            widget.preferences.move(zone, siblings, details.data.id, id),
        builder: (context, candidates, rejected) => Semantics(
          customSemanticsActions: {
            if (index > 0)
              CustomSemanticsAction(label: 'Переместить выше'): () => widget
                  .preferences
                  .move(zone, siblings, id, siblings[index - 1]),
            if (index + 1 < siblings.length)
              CustomSemanticsAction(label: 'Переместить ниже'): () => widget
                  .preferences
                  .move(zone, siblings, id, siblings[index + 1]),
          },
          child: LongPressDraggable<_MenuDrag>(
            data: _MenuDrag(zone, id),
            delay: const Duration(seconds: 1),
            hitTestBehavior: HitTestBehavior.opaque,
            maxSimultaneousDrags: 1,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            onDragStarted: _startDrag,
            onDragUpdate: (details) => _pointer = details.globalPosition,
            onDragEnd: (_) => _stopDrag(),
            onDraggableCanceled: (_, _) => _stopDrag(),
            feedback: Material(
              key: const ValueKey('menu-drag-feedback'),
              elevation: 6,
              color: widget.theme.cardBg,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 240,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: widget.theme.accentColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: widget.theme.textColor),
                ),
              ),
            ),
            childWhenDragging: Opacity(opacity: .35, child: child),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: candidates.isEmpty
                        ? Colors.transparent
                        : widget.theme.accentColor,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SizedBox(width: double.infinity, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.preferences,
    builder: (context, _) {
      final groups = tournamentMenuGroups(
        widget.tournaments,
        widget.favoriteIds,
        widget.preferences,
      );
      return ListView(
        key: _viewport,
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
        children: [
          for (final favorite in [true, false]) ...[
            if (groups.any((g) => g.favorite == favorite))
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                child: Text(
                  favorite ? 'Избранное' : 'Все турниры',
                  style: TextStyle(
                    color: widget.theme.dimTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            for (final group in groups.where((g) => g.favorite == favorite))
              _group(
                group,
                groups
                    .where((g) => g.favorite == favorite)
                    .map((g) => g.code)
                    .toList(),
              ),
          ],
          if (groups.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Турниры пока не загружены'),
            ),
        ],
      );
    },
  );

  Widget _group(TournamentMenuGroup group, List<String> siblings) {
    final collapsed = widget.preferences.isCollapsed(group.key);
    final theme = widget.theme;
    return Container(
      key: ValueKey('menu-group-${group.key}'),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardBg,
        border: Border.all(color: theme.cardBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _movable(
            group.zone,
            group.code,
            siblings,
            group.title,
            ListTile(
              key: ValueKey('group-header-${group.key}'),
              title: Text(
                group.title,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${group.leagues.length}',
                    style: TextStyle(color: theme.dimTextColor),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.drag_indicator,
                    size: 18,
                    color: theme.dimTextColor,
                  ),
                  Icon(
                    collapsed ? Icons.expand_more : Icons.expand_less,
                    color: theme.dimTextColor,
                  ),
                ],
              ),
            ),
            onTap: () => widget.preferences.toggleCollapsed(group.key),
          ),
          if (!collapsed)
            for (final league in group.leagues) _league(group, league),
        ],
      ),
    );
  }

  Widget _league(TournamentMenuGroup group, Tournament league) {
    final theme = widget.theme;
    final selected = league.id == widget.selectedId;
    final name = league.name.replaceAll(RegExp(r'\s*\([^)]*\)'), '');
    return _movable(
      group.key,
      menuLeagueKey(league),
      group.leagues.map(menuLeagueKey).toList(),
      name,
      ListTile(
        key: ValueKey('league-${group.key}-${menuLeagueKey(league)}'),
        contentPadding: const EdgeInsets.only(left: 16, right: 4),
        selected: selected,
        selectedTileColor: theme.accentColor.withValues(alpha: .08),
        leading: FootballLogo(url: league.logoUrl, size: 28, padding: 3),
        title: Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? theme.accentColor : theme.textColor,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: IconButton(
          tooltip: group.favorite
              ? 'Убрать из избранного'
              : 'Добавить в избранное',
          icon: Icon(
            group.favorite ? Icons.star : Icons.star_border,
            color: group.favorite ? theme.accentColor : theme.dimTextColor,
          ),
          onPressed: () => widget.onFavorite(league),
        ),
        onTap: () => widget.onSelect(league),
      ),
    );
  }
}

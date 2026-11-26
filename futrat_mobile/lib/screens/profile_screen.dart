import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/data_provider.dart';
import '../core/app_theme.dart';
import '../core/auth_gate.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final appearance = context.watch<ThemeProvider>();
    final theme = appearance.currentTheme;
    final user = auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    child: Icon(Icons.person_outline),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Tooltip(
                          message: user?.username ?? 'Гость',
                          child: Text(
                            user?.username ?? 'Гость',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user == null
                              ? 'Смотрите матчи без регистрации'
                              : 'Аккаунт Futrat',
                          style: TextStyle(color: theme.dimTextColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (user == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: FilledButton.icon(
                onPressed: () => openAuthScreen(context),
                icon: const Icon(Icons.login),
                label: const Text('Войти / зарегистрироваться'),
              ),
            ),
          const SizedBox(height: 12),
          Text('Оформление', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  leading: Icon(
                    theme.isDark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                  ),
                  title: const Text('Тема'),
                  subtitle: Text(theme.isDark ? 'Тёмная' : 'Светлая'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemePicker(context),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text('Акцентный цвет'),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth < 432
                        ? 432.0
                        : constraints.maxWidth;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: width,
                        child: Row(
                          children: [
                            for (final accent in AppAccent.values)
                              Expanded(
                                child: Semantics(
                                  button: true,
                                  selected: appearance.currentAccent == accent,
                                  label: accent.label,
                                  child: Tooltip(
                                    message: accent.label,
                                    child: InkResponse(
                                      key: ValueKey('accent-${accent.name}'),
                                      onTap: () => appearance.setAccent(accent),
                                      child: SizedBox(
                                        height: 48,
                                        child: Center(
                                          child: Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: accent.color,
                                              border: Border.all(
                                                color:
                                                    appearance.currentAccent ==
                                                        accent
                                                    ? theme.textColor
                                                    : theme.cardBorder,
                                                width:
                                                    appearance.currentAccent ==
                                                        accent
                                                    ? 2
                                                    : 1,
                                              ),
                                            ),
                                            child:
                                                appearance.currentAccent ==
                                                    accent
                                                ? Icon(
                                                    Icons.check,
                                                    size: 14,
                                                    color:
                                                        AppTheme.foregroundOn(
                                                          accent.color,
                                                        ),
                                                  )
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: OutlinedButton.icon(
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted)
                    context.read<DataProvider>().clearFavorites();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Выйти'),
              ),
            ),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final provider = sheetContext.watch<ThemeProvider>();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Выберите тему',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                for (final type in AppThemeType.values)
                  ListTile(
                    leading: Icon(
                      type == AppThemeType.light
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                    title: Text(
                      type == AppThemeType.light ? 'Светлая' : 'Тёмная',
                    ),
                    selected: provider.currentType == type,
                    trailing: provider.currentType == type
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () {
                      provider.setTheme(type);
                      Navigator.pop(sheetContext);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

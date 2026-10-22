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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      child: Icon(Icons.person_outline, size: 36),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.username ?? 'Гость',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user == null
                          ? 'Смотрите матчи без регистрации'
                          : 'Аккаунт Futrat',
                      style: TextStyle(color: theme.dimTextColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      theme.isDark
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                    ),
                    title: const Text('Тема оформления'),
                    subtitle: Text(theme.isDark ? 'Тёмная' : 'Светлая'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showThemePicker(context),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Акцентный цвет'),
                        const SizedBox(height: 8),
                        Row(
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
                                        height: 44,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: user == null
                  ? () => openAuthScreen(context)
                  : () async {
                      await auth.logout();
                      if (context.mounted) {
                        context.read<DataProvider>().clearFavorites();
                      }
                    },
              icon: Icon(user == null ? Icons.login : Icons.exit_to_app),
              label: Text(
                user == null ? 'Войти / зарегистрироваться' : 'Выйти',
              ),
            ),
          ],
        ),
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

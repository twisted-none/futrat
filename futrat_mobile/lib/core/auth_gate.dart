import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../screens/auth_screen.dart';

Future<bool> openAuthScreen(BuildContext context) async {
  context.read<AuthProvider>().clearError();
  final signedIn =
      await Navigator.of(
        context,
        rootNavigator: true,
      ).push<bool>(MaterialPageRoute(builder: (_) => const AuthScreen())) ??
      false;
  if (signedIn && context.mounted) {
    await context.read<DataProvider>().fetchFavorites();
  }
  return signedIn;
}

Future<void> runAuthenticatedAction(
  BuildContext context, {
  required String action,
  required Future<void> Function(bool resumedAfterLogin) onAuthenticated,
}) async {
  var resumedAfterLogin = false;
  if (!context.read<AuthProvider>().isAuthenticated) {
    final shouldSignIn = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Нужен аккаунт'),
        content: Text('Чтобы $action, войдите или зарегистрируйтесь.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Позже'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Войти / зарегистрироваться'),
          ),
        ],
      ),
    );
    if (shouldSignIn != true || !context.mounted) return;
    if (!await openAuthScreen(context) || !context.mounted) return;
    resumedAfterLogin = true;
  }
  await onAuthenticated(resumedAfterLogin);
}

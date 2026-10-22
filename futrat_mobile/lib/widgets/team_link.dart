import 'package:flutter/material.dart';
import '../core/translator.dart';
import '../models/all_models.dart';
import '../screens/team_screen.dart';

class TeamLink extends StatelessWidget {
  const TeamLink({super.key, required this.team, required this.child});
  final Team team;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Открыть профиль команды ${tr(team.name)}',
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TeamScreen(teamId: team.id, name: tr(team.name)),
          ),
        ),
        child: child,
      ),
    ),
  );
}

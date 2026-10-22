import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:futrat_mobile/core/forecast_api.dart';
import 'package:futrat_mobile/models/all_models.dart';
import 'package:futrat_mobile/providers/auth_provider.dart';
import 'package:futrat_mobile/providers/data_provider.dart';
import 'package:futrat_mobile/screens/forecasts_screen.dart';

class ForecastAuth extends AuthProvider {
  final bool signedIn;
  ForecastAuth(this.signedIn);
  @override
  bool get isAuthenticated => signedIn;
}

class ForecastData extends DataProvider {
  final MatchModel game = MatchModel.fromJson({
    'id': 1,
    'date_time': DateTime.now()
        .toUtc()
        .add(const Duration(seconds: 30))
        .toIso8601String(),
    'status': 'SCHEDULED',
    'home_team': {'id': 1, 'name': 'Home'},
    'away_team': {'id': 2, 'name': 'Away'},
    'tournament': {'id': 1, 'name': 'League', 'type': 'League'},
    'events': [],
  });
  @override
  List<MatchModel> get allMatches => [game];
}

class FakeForecastApi extends ForecastApi {
  int count = 0;
  String? outcome;
  @override
  Future<List<Map<String, dynamic>>> mine({
    String? day,
    int offset = 0,
  }) async => [];
  @override
  Future<int> used(String day) async => count;
  @override
  Future<void> choose(int matchId, String value) async {
    outcome = value;
    count = 1;
  }

  @override
  Future<Map<String, dynamic>> rankings({
    String? month,
    int offset = 0,
  }) async => {'rows': [], 'total': 0};
  @override
  Future<Map<String, dynamic>?> myRank({String? month}) async => null;
}

Widget screen(ForecastApi api, bool signedIn) => MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthProvider>(create: (_) => ForecastAuth(signedIn)),
    ChangeNotifierProvider<DataProvider>(create: (_) => ForecastData()),
  ],
  child: MaterialApp(home: ForecastsScreen(api: api)),
);

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test('Moscow day switches at 21 UTC', () {
    expect(moscowDay(DateTime.utc(2026, 10, 17, 20, 59)), '2026-10-17');
    expect(moscowDay(DateTime.utc(2026, 10, 17, 21)), '2026-10-18');
  });
  testWidgets('signed in user chooses an outcome and sees day quota', (
    tester,
  ) async {
    final api = FakeForecastApi();
    await tester.pumpWidget(screen(api, true));
    await tester.pumpAndSettle();
    expect(find.text('Выбрано 0 из 10'), findsOneWidget);
    await tester.tap(find.text('П1'));
    await tester.pumpAndSettle();
    expect(api.outcome, 'HOME');
    expect(find.text('Выбрано 1 из 10'), findsOneWidget);
  });
  testWidgets('guest can view rankings and needs auth only when choosing', (
    tester,
  ) async {
    final api = FakeForecastApi();
    await tester.pumpWidget(screen(api, false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('П1'));
    await tester.pumpAndSettle();
    expect(find.text('Нужен аккаунт'), findsOneWidget);
    expect(api.outcome, isNull);
    await tester.tap(find.text('Позже'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Рейтинг'));
    await tester.pumpAndSettle();
    expect(
      find.text('В этом периоде ещё нет рассчитанных прогнозов'),
      findsOneWidget,
    );
  });
}

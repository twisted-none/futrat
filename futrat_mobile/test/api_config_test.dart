import 'package:flutter_test/flutter_test.dart';
import 'package:futrat_mobile/core/api_client.dart';

void main() {
  test('API client uses the server address supplied at build time', () {
    const expected = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://127.0.0.1:8000',
    );
    expect(ApiClient().dio.options.baseUrl, expected);
  });
}

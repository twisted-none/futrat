import 'package:dio/dio.dart';
import 'api_client.dart';

class ForecastApi {
  final Dio dio;
  ForecastApi({Dio? client}) : dio = client ?? ApiClient().dio;

  Future<List<Map<String, dynamic>>> mine({String? day, int offset = 0}) async {
    final response = await dio.get(
      '/interactive/predictions',
      queryParameters: {if (day != null) 'day': day, 'offset': offset},
    );
    return (response.data as List)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<int> used(String day) async {
    final response = await dio.get(
      '/interactive/prediction-quota',
      queryParameters: {'day': day},
    );
    return response.data['used'] as int;
  }

  Future<Map<String, dynamic>> rankings({String? month, int offset = 0}) async {
    final response = await dio.get(
      '/interactive/rankings',
      queryParameters: {if (month != null) 'month': month, 'offset': offset},
    );
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>?> myRank({String? month}) async {
    final response = await dio.get(
      '/interactive/my-rank',
      queryParameters: {if (month != null) 'month': month},
    );
    return response.data == null
        ? null
        : Map<String, dynamic>.from(response.data);
  }

  Future<void> choose(int matchId, String outcome) async {
    await dio.put(
      '/interactive/predictions/$matchId',
      data: {'outcome': outcome},
    );
  }

  Future<void> cancel(int matchId) async {
    await dio.delete('/interactive/predictions/$matchId');
  }
}

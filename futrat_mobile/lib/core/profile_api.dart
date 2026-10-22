import 'package:dio/dio.dart';
import 'api_client.dart';

class ProfileApi {
  final Dio dio;
  ProfileApi({Dio? client}) : dio = client ?? ApiClient().dio;
  Future<Map<String, dynamic>> team(
    int id, {
    int? season,
    int? cursor,
    String direction = 'past',
  }) async {
    final response = await dio.get(
      '/api/teams/$id/matches',
      queryParameters: {
        if (season != null) 'season': season,
        if (cursor != null) 'cursor': cursor,
        'direction': direction,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> player(int id) async =>
      Map<String, dynamic>.from((await dio.get('/api/players/$id')).data);
  Future<Map<String, dynamic>> playerMatches(
    int id, {
    int? season,
    String kind = 'all',
    int offset = 0,
  }) async {
    final response = await dio.get(
      '/api/players/$id/matches',
      queryParameters: {
        if (season != null) 'season': season,
        'kind': kind,
        'offset': offset,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }
}

import 'package:a2c_inventario/core/storage/cached_json.dart';
import 'package:a2c_inventario/core/storage/local_database.dart';
import 'package:a2c_inventario/core/network/api_failure.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _OfflineAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late LocalDatabase database;
  late Dio dio;

  setUp(() {
    database = LocalDatabase(NativeDatabase.memory());
    dio = Dio()..httpClientAdapter = _OfflineAdapter();
  });

  tearDown(() async {
    dio.close();
    await database.close();
  });

  test('uses the last cached GET response when transport is offline', () async {
    final body = {
      'totals': {'assets': 8},
      'sites': [
        {'id': 'site-1', 'name': 'Obra Norte'},
      ],
    };
    await database.putCache('dashboard:full', body);

    final cached = await getCachedJson(
      dio: dio,
      database: database,
      key: 'dashboard:full',
      path: '/dashboard',
    );

    expect(cached, body);
  });

  test('returns an offline failure when there is no cached response', () async {
    await expectLater(
      getCachedJson(
        dio: dio,
        database: database,
        key: 'dashboard:full',
        path: '/dashboard',
      ),
      throwsA(isA<ApiFailure>()),
    );
  });
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/dio_client.dart';
import '../domain/site.dart';

class SitesRepository {
  SitesRepository(this._dio);

  final Dio _dio;

  Future<List<Site>> list() => guardApi(() async {
    final response = await _dio.get<List<dynamic>>('/sites');
    return (response.data ?? const [])
        .map((json) => Site.fromJson(json as Map<String, dynamic>))
        .toList(growable: false);
  });

  Future<Site> get(String id) => guardApi(() async {
    final response = await _dio.get<Map<String, dynamic>>('/sites/$id');
    return Site.fromJson(response.data!);
  });

  Future<List<SiteStockItem>> stock(String id, {String? type}) =>
      guardApi(() async {
        final queryParameters = <String, dynamic>{};
        if (type != null) queryParameters['type'] = type;
        final response = await _dio.get<List<dynamic>>(
          '/sites/$id/stock',
          queryParameters: queryParameters,
        );
        return (response.data ?? const [])
            .map((json) => SiteStockItem.fromJson(json as Map<String, dynamic>))
            .toList(growable: false);
      });

  Future<Site> create({
    required String name,
    required String ownerName,
    String? address,
    double? lat,
    double? lng,
  }) => guardApi(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/sites',
      data: {
        'name': name,
        'ownerName': ownerName,
        if (address?.isNotEmpty ?? false) 'address': address,
        if (lat != null && lng != null) 'lat': lat,
        if (lat != null && lng != null) 'lng': lng,
      },
    );
    return Site.fromJson(response.data!);
  });

  Future<Site> update({
    required String id,
    required String name,
    required String ownerName,
    String? address,
    double? lat,
    double? lng,
  }) => guardApi(() async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/sites/$id',
      data: {
        'name': name,
        'ownerName': ownerName,
        'address': address,
        'lat': lat,
        'lng': lng,
      },
    );
    return Site.fromJson(response.data!);
  });

  Future<Site> close(String id) => guardApi(() async {
    final response = await _dio.post<Map<String, dynamic>>('/sites/$id/close');
    return Site.fromJson(response.data!);
  });

  Future<Site> reopen(String id) => guardApi(() async {
    final response = await _dio.post<Map<String, dynamic>>('/sites/$id/reopen');
    return Site.fromJson(response.data!);
  });
}

final sitesRepositoryProvider = Provider<SitesRepository>(
  (ref) => SitesRepository(ref.watch(dioProvider)),
);

final sitesListProvider = FutureProvider.autoDispose<List<Site>>(
  (ref) => ref.watch(sitesRepositoryProvider).list(),
);

final siteDetailProvider = FutureProvider.autoDispose.family<Site, String>(
  (ref, id) => ref.watch(sitesRepositoryProvider).get(id),
);

final siteStockProvider = FutureProvider.autoDispose
    .family<List<SiteStockItem>, String>(
      (ref, id) => ref.watch(sitesRepositoryProvider).stock(id),
    );

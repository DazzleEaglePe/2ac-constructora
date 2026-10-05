import 'package:url_launcher/url_launcher.dart';

Future<bool> openSiteInMaps({
  required String? address,
  required double? lat,
  required double? lng,
}) {
  final query = lat != null && lng != null
      ? '$lat,$lng'
      : (address ?? '').trim();
  if (query.isEmpty) return Future.value(false);
  final uri = Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': query,
  });
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

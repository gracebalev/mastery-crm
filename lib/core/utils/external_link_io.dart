import 'dart:async';

import 'package:url_launcher/url_launcher.dart';

void openExternalLink(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
}

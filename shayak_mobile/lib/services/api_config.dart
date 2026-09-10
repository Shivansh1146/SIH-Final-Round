import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
        return 'http://$host:8000';
      }
    }
    // On physical mobile devices, default to local Wi-Fi IP (and USB reverse fallback)
    return 'http://192.168.29.29:8000';
  }
}

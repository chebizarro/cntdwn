import 'package:flutter/foundation.dart';

class Config {
  // Configuración de Nostr
  static const List<String> nostrRelays = [
    'wss://nos.lol',
    'wss://relay.primal.net',
    'wss://relay.nostr.band',
    'wss://nostr.mom',
  ];

  static const String cntDwnPubKey =
    '4f3ffaebf6dc13553161a03c95088746b6c25f393a6e905203e498dc31ab24ba';

  static const Duration nostrConnectionTimeout = Duration(seconds: 30);

  static bool get isDebug => !kReleaseMode;

}

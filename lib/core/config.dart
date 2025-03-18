import 'package:flutter/foundation.dart';

class Config {
  // Configuración de Nostr
  static const List<String> nostrRelays = [
    'wss://relay.mostro.network',
	  //'ws://127.0.0.1:7000',
    //'ws://192.168.1.103:7000',
    //'ws://10.0.2.2:7000', // mobile emulator
  ];

  // hexkey de CntDwn
  static const String cntDwnPubKey =
    '82fa8cb978b43c79b2156585bac2c011176a21d2aead6d9f7c575c005be88390';

  static const Duration nostrConnectionTimeout = Duration(seconds: 30);

  // Modo de depuración
  static bool get isDebug => !kReleaseMode;

}

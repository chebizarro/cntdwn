import 'package:cntdwn/core/config.dart';
import 'package:cntdwn/data/preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesNotifier extends StateNotifier<Preferences> {
  final SharedPreferencesAsync _prefs;

  PreferencesNotifier(this._prefs) : super(_defaultSettings());

  static Preferences _defaultSettings() {
    return Preferences(relays: Config.nostrRelays);
  }
}

import 'package:cntdwn/data/preferences.dart';
import 'package:cntdwn/providers/preferences_provider.dart';
import 'package:cntdwn/services/nostr_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nostrServiceProvider = Provider<NostrService>((ref) {
  final settings = ref.read(preferencesProvider);
  final nostrService = NostrService(settings);

  ref.listen<Preferences>(preferencesProvider, (previous, next) {
    nostrService.updateSettings(next);
  });

  return nostrService;
});

import 'package:vidrome/data/preferences.dart';
import 'package:vidrome/providers/preferences_provider.dart';
import 'package:vidrome/services/nostr_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nostrServiceProvider = Provider<NostrService>((ref) {
  final settings = ref.read(preferencesProvider);
  final nostrService = NostrService(settings);

  ref.listen<Preferences>(preferencesProvider, (previous, next) {
    nostrService.updateSettings(next);
  });

  return nostrService;
});

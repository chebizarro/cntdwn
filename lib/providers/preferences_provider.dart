import 'package:vidrome/data/preferences.dart';
import 'package:vidrome/features/preferences/preferences_notifier.dart';
import 'package:vidrome/providers/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, Preferences>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return PreferencesNotifier(prefs);
    });

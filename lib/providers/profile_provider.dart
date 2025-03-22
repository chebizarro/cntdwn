import 'package:cntdwn/providers/nostr_cache_provider.dart';
import 'package:cntdwn/providers/nostr_service_provider.dart';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileEventProvider = FutureProvider.family<NostrEvent?, String>((
  ref,
  pubkey,
) async {
  final cache = ref.watch(nostrCacheProvider);

  try {
    final cachedProfile = cache.eventCache.values.firstWhere(
      (e) => e.kind == 0 && e.pubkey == pubkey,
    );
    return cachedProfile;
  } catch (e) {
    if (e is! StateError) {
      print('Error: $e');
      return null;
    }
  }

  final client = ref.watch(nostrServiceProvider);
  final filter = NostrFilter(kinds: [0], authors: [pubkey], limit: 1);

  final subscription = client.subscribeToEvents(filter);

  await for (final event in subscription) {
    cache.add(event);
    return event;
  }

  return null;
});

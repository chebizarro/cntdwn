import 'package:vidrome/providers/nostr_service_provider.dart';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final relatedEventsProvider = StreamProvider.family<List<NostrEvent>, String>((
  ref,
  eventId,
) {
  final client = ref.watch(nostrServiceProvider);
  final filter = NostrFilter(
    kinds: [1, 7, 9735], // kind 1 = text reply, 7 = reaction (like), 9735 = zap
    additionalFilters: {
      '#e': [eventId],
    },
  );

  final events = <NostrEvent>[];
  final subscription = client.subscribeToEvents(filter);

  subscription.listen((event) => events.add(event), onError: (e) => throw e);

  return subscription.toList().asStream();
});

import 'package:dart_nostr/dart_nostr.dart';

class NostrCache {
  final Map<String, NostrEvent> eventCache = {};
  
  bool contains(String eventId) => eventCache.containsKey(eventId);
  
  NostrEvent? get(String eventId) => eventCache[eventId];
  
  void add(NostrEvent event) {
    eventCache[event.id!] = event;
  }
}

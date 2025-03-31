import 'dart:async';
import 'dart:convert';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vidrome/data/models/user_profile.dart';

class UserRepository {
  static const _prefsKeyPubkey = 'nostr_pubkey';

  String? userPubKey;

  Future<String?> loadPubkey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKeyPubkey);
  }

  Future<void> savePubkey(String pubkey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyPubkey, pubkey);
  }

  Future<String?> login(String pubKey) async {
    userPubKey = pubKey;
    await savePubkey(pubKey);
    return pubKey;
  }

  Future<UserProfile?> fetchUserProfile(String pubkey) async {
    final pkHex = Nostr.instance.services.bech32.decodeBech32(pubkey);

    final request = NostrRequest(
      filters: <NostrFilter>[
        NostrFilter(
          kinds: [0],
          authors: [pkHex[0]],
          limit: 1,
        ),
      ],
    );

    final subscription = Nostr.instance.services.relays.startEventsSubscription(
      request: request,
      relays: [
        'wss://relay.primal.net',
        'wss://nos.lol',
        'wss://relay.nostrsf.org'
      ],
      onEose: (relayUrl, eoseMessage) {
        // EOSE => end of stream for this subscription
        Nostr.instance.services.relays.closeEventsSubscription(
          eoseMessage.subscriptionId,
        );
      },
    );

    final completer = Completer<UserProfile?>();

    final streamSubscription = subscription.stream.listen(
      (NostrEvent event) {
        final content = event.content;
        try {
          final data = json.decode(content!) as Map<String, dynamic>;

          final userProfile = UserProfile(
            pubkey: pubkey,
          );

          completer.complete(userProfile);
          Nostr.instance.services.relays.closeEventsSubscription(
            event.subscriptionId!,
          );
        } catch (e) {
          completer.completeError(e);
        }
      },
      onError: (error) {
        if (!completer.isCompleted) completer.completeError(error);
      },
    );

    final profile = await completer.future.catchError((e) {
      streamSubscription.cancel();
      return null;
    });

    streamSubscription.cancel();
    return profile;
  }



}

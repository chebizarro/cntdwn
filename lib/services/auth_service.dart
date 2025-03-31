import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:vidrome/data/models/user_profile.dart';
import 'package:vidrome/features/signer/nip55_signer.dart';

class AuthService {
  static final nip55 = Nip55Signer();

  static const _privateKeyStorageKey = 'user_private_key';
  static const _storage = FlutterSecureStorage();
  final Nostr _nostr = Nostr.instance;

  /// Login using NIP-55: generates or retrieves a locally stored private key.
  Future<UserProfile> loginWithNip55({String? existingPrivateKey}) async {
    String privateKey;

    if (existingPrivateKey != null) {
      // Use the provided private key
      privateKey = existingPrivateKey;
    } else {
      // Check if key is already stored
      privateKey =
          await _storage.read(key: _privateKeyStorageKey) ??
          _generateNewPrivateKey();

      // Store securely
      await _storage.write(key: _privateKeyStorageKey, value: privateKey);
    }

    final keyPair = _nostr.keysService.generateKeyPairFromExistingPrivateKey(
      privateKey,
    );

    // Fetch user's metadata (kind 0)
    final profile = await _fetchNip01ProfileMetadata(keyPair.public);

    return profile;
  }

  /// Login using NIP-46 (Remote Signer)
  Future<UserProfile> loginWithNip46({
    required String signerRelayUrl,
    required String remoteSignerPubkey,
  }) async {
    // Example: simple handshake with remote signer (implementation depends on your signer setup)
    final nip46Client = _nostr;

    await nip46Client.relaysService.init(relaysUrl: [signerRelayUrl]);

    final subscription = nip46Client.relaysService.startEventsSubscriptionAsync(
      request: NostrRequest(
        filters: [
          NostrFilter(
            kinds: [24133], // NIP-46 specific kind
            authors: [remoteSignerPubkey],
          ),
        ],
      ),
    );

    // Normally you'd implement your own handshake logic here. Simplified example:
    final events = await subscription;

    if (events.isEmpty) {
      throw Exception("Remote signer unavailable or handshake failed.");
    }

    // Assume you successfully authenticated; you get back the user's pubkey
    final userPubkey = remoteSignerPubkey;

    // Fetch user's metadata (kind 0)
    final profile = await _fetchNip01ProfileMetadata(userPubkey);

    return profile;
  }

  /// Logout: clears private key from storage
  Future<void> logout() async {
    await _storage.delete(key: _privateKeyStorageKey);
  }

  /// Helper: Generate new random private key
  String _generateNewPrivateKey() {
    final keyPair = _nostr.keysService.generateKeyPair();
    return keyPair.private;
  }

  /// Helper: Fetch NIP-01 profile metadata from relays
  Future<UserProfile> _fetchNip01ProfileMetadata(String pubkey) async {
    await _nostr.relaysService.init(relaysUrl: ['wss://relay.damus.io']);

    final events = await _nostr.relaysService.startEventsSubscriptionAsync(
      request: NostrRequest(
        filters: [
          NostrFilter(kinds: [0], authors: [pubkey]),
        ],
      ),
    );

    if (events.isEmpty) {
      return UserProfile(
        pubkey: pubkey,
        displayName: 'Unknown',
        about: '',
        pictureUrl: '',
      );
    }

    final metadata = events.first;
    final data = metadata.content;

    // Assuming metadata content is JSON
    final Map<String, dynamic> metaJson = Nostr.instance.utilsService
        .decodeJson(data);

    return UserProfile(
      pubkey: pubkey,
      displayName: metaJson['display_name'] ?? metaJson['name'] ?? 'User',
      about: metaJson['about'] ?? '',
      pictureUrl: metaJson['picture'] ?? '',
    );
  }

  /// Check if user is already authenticated (has private key stored)
  Future<bool> isAuthenticated() async {
    return (await _storage.read(key: _privateKeyStorageKey)) != null;
  }

  /// Retrieve stored public key without exposing private key
  Future<String?> getStoredPubkey() async {
    final privateKey = await _storage.read(key: _privateKeyStorageKey);
    if (privateKey == null) return null;

    final keyPair = _nostr.keysService.generateKeyPairFromExistingPrivateKey(
      privateKey,
    );
    return keyPair.public;
  }
}

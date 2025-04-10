import 'package:vidrome/core/config.dart';
import 'package:vidrome/data/preferences.dart';
import 'package:vidrome/utils/nostr_utils.dart';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:dart_nostr/nostr/model/relay_informations.dart';
import 'package:logger/logger.dart';
import 'package:collection/collection.dart';

class NostrService {
  Preferences settings;
  final Nostr _nostr = Nostr.instance;

  NostrService(this.settings);

  final Logger _logger = Logger();
  bool _isInitialized = false;

  Future<void> init() async {
    try {
      await _nostr.services.relays.init(
        relaysUrl: settings.relays,
        connectionTimeout: Config.nostrConnectionTimeout,
        shouldReconnectToRelayOnNotice: true,
        onRelayListening: (relay, url, channel) {
          _logger.i('Connected to relay: $relay');
        },
        onRelayConnectionError: (relay, error, channel) {
          _logger.w('Failed to connect to relay $relay: $error');
        },
        onRelayConnectionDone: (relay, socket) {
          _logger.i('Connection to relay: $relay via $socket is done');
        },
        retryOnClose: true,
        retryOnError: true,
      );
      _isInitialized = true;
      _logger.i('Nostr initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize Nostr: $e');
      rethrow;
    }
  }

  Future<void> updateSettings(Preferences newSettings) async {
    settings = newSettings.copyWith();
    final relays = Nostr.instance.services.relays.relaysList;
    if (!ListEquality().equals(relays, settings.relays)) {
      _logger.i('Updating relays...');
      await init();
    }
  }

  Future<RelayInformations?> getRelayInfo(String relayUrl) async {
    return await Nostr.instance.services.relays.relayInformationsDocumentNip11(
      relayUrl: relayUrl,
    );
  }

  Future<void> publishEvent(NostrEvent event) async {
    if (!_isInitialized) {
      throw Exception('Nostr is not initialized. Call init() first.');
    }

    try {
      await _nostr.services.relays.sendEventToRelaysAsync(
        event,
        timeout: Config.nostrConnectionTimeout,
      );
      _logger.i('Event published successfully');
    } catch (e) {
      _logger.w('Failed to publish event: $e');
      rethrow;
    }
  }

  Stream<NostrEvent> subscribeToEvents(NostrFilter filter) {
    if (!_isInitialized) {
      throw Exception('Nostr is not initialized. Call init() first.');
    }

    final request = NostrRequest(filters: [filter]);
    final subscription = _nostr.services.relays.startEventsSubscription(
      request: request,
    );

    return subscription.stream;
  }

  Future<List<NostrEvent>> subscribeToEventsAsync(NostrFilter filter) async {
    if (!_isInitialized) {
      throw Exception('Nostr is not initialized. Call init() first.');
    }

    final request = NostrRequest(filters: [filter]);
    final events = await _nostr.services.relays.startEventsSubscriptionAsync(
      request: request,
      timeout: Config.nostrConnectionTimeout,
    );

    return events;
  }

  Future<void> disconnectFromRelays() async {
    if (!_isInitialized) return;

    await _nostr.services.relays.disconnectFromRelays();
    _isInitialized = false;
    _logger.i('Disconnected from all relays');
  }

  bool get isInitialized => _isInitialized;

  Future<NostrKeyPairs> generateKeyPair() async {
    final keyPair = NostrUtils.generateKeyPair();
    return keyPair;
  }

  NostrKeyPairs generateKeyPairFromPrivateKey(String privateKey) {
    return NostrUtils.generateKeyPairFromPrivateKey(privateKey);
  }

  String getMostroPubKey() {
    return Config.cntDwnPubKey;
  }

  Future<NostrEvent> createNIP59Event(
    String content,
    String recipientPubKey,
    String senderPrivateKey,
  ) async {
    if (!_isInitialized) {
      throw Exception('Nostr is not initialized. Call init() first.');
    }

    return NostrUtils.createNIP59Event(
      content,
      recipientPubKey,
      senderPrivateKey,
    );
  }

  Future<NostrEvent> decryptNIP59Event(
    NostrEvent event,
    String privateKey,
  ) async {
    if (!_isInitialized) {
      throw Exception('Nostr is not initialized. Call init() first.');
    }

    return NostrUtils.decryptNIP59Event(event, privateKey);
  }

  Future<String> createRumor(
    NostrKeyPairs senderKeyPair,
    String wrapperKey,
    String recipientPubKey,
    String content,
  ) async {
    return NostrUtils.createRumor(
      senderKeyPair,
      wrapperKey,
      recipientPubKey,
      content,
    );
  }

  Future<String> createSeal(
    NostrKeyPairs senderKeyPair,
    String wrapperKey,
    String recipientPubKey,
    String encryptedContent,
  ) async {
    return NostrUtils.createSeal(
      senderKeyPair,
      wrapperKey,
      recipientPubKey,
      encryptedContent,
    );
  }

  Future<NostrEvent> createWrap(
    NostrKeyPairs wrapperKeyPair,
    String sealedContent,
    String recipientPubKey,
  ) async {
    return NostrUtils.createWrap(
      wrapperKeyPair,
      sealedContent,
      recipientPubKey,
    );
  }
}

import 'dart:async';
import 'package:vidrome/data/models/nostr_event.dart';
import 'package:vidrome/data/preferences.dart';
import 'package:vidrome/services/nostr_service.dart';
import 'package:dart_nostr/nostr/model/event/event.dart';
import 'package:dart_nostr/nostr/model/request/filter.dart';
import 'package:logger/logger.dart';

const orderEventKind = 38383;
const orderFilterDurationHours = 48;

class VideoRepository {
  final NostrService _nostrService;
  NostrEvent? _mostroInstance;
  Preferences _preferences;

  final StreamController<List<NostrEvent>> _eventStreamController =
      StreamController.broadcast();
  final List<NostrEvent> _events = [];
  final _logger = Logger();
  StreamSubscription<NostrEvent>? _subscription;

  NostrEvent? get mostroInstance => _mostroInstance;

  VideoRepository(this._nostrService, this._preferences) {
    _subscribeToStreams();
  }

  void _subscribeToStreams() {
    _subscription?.cancel();

    var filter = NostrFilter(kinds: const [1, 21, 22]);

    _subscription = _nostrService
        .subscribeToEvents(filter)
        .listen(
          (event) {
            if (event.videoUrl != null || event.isNip71Video) {
              _events.add(event);
              _eventStreamController.add(_events);
              _logger.i('Loaded event: $event');
            }
          },
          onError: (error) {
            _logger.e('Error in order subscription: $error');
          },
        );
  }

  void dispose() {
    _subscription?.cancel();
    _eventStreamController.close();
    _events.clear();
  }

  Stream<List<NostrEvent>> get eventsStream => _eventStreamController.stream;

  void updateSettings(Preferences settings) {
    _preferences = settings.copyWith();
  }
}

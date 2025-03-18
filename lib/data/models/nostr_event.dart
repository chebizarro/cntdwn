import 'package:dart_nostr/dart_nostr.dart';

extension NostrEventExtensions on NostrEvent {
  // Getters para acceder fácilmente a los tags específicos
  String? get recipient => _getTagValue('p');
  String? get dTag => _getTagValue('d');
  String? get videoUrl => _getTagValue('r');

  String? _getTagValue(String key) {
    final tag = tags?.firstWhere((t) => t[0] == key, orElse: () => []);
    return (tag != null && tag.length > 1) ? tag[1] : null;
  }
}

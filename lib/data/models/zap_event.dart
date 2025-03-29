import 'package:dart_nostr/nostr/model/event/event.dart';

/// An extension that parses a [NostrEvent] as a Lightning Zap receipt (NIP-57).
/// This extension only makes sense for events with `kind == 9735`.
extension ZapReceiptEventExtension on NostrEvent {
  /// Checks whether this event has `kind == 9735`.
  bool get isZapReceipt => kind == 9735;

  /// Returns the LN invoice that was used for the zap, if present.
  /// Often found in a `["bolt11", "lnbc..."]` tag.
  String? get bolt11Invoice {
    final tag = tags!.firstWhere(
      (t) => t.isNotEmpty && t.first == 'bolt11',
      orElse: () => [],
    );
    if (tag.length > 1) return tag[1];
    return null;
  }

  /// Returns the LN payment preimage (hex-encoded), if present.
  /// Found in a `["preimage", "<hex>"]` tag.
  String? get preimage {
    final tag = tags!.firstWhere(
      (t) => t.isNotEmpty && t.first == 'preimage',
      orElse: () => [],
    );
    if (tag.length > 1) return tag[1];
    return null;
  }

  /// The LN invoice description, which is often a JSON string referencing
  /// the original event, the pubkey, and other metadata. If present,
  /// it is found in a `["description", "..."]` tag.
  String? get description {
    final tag = tags!.firstWhere(
      (t) => t.isNotEmpty && t.first == 'description',
      orElse: () => [],
    );
    if (tag.length > 1) return tag[1];
    return null;
  }

  /// The LNURL used for this zap, if any, found in a `["lnurl", "..."]` tag.
  String? get lnurl {
    final tag = tags!.firstWhere(
      (t) => t.isNotEmpty && t.first == 'lnurl',
      orElse: () => [],
    );
    if (tag.length > 1) return tag[1];
    return null;
  }

  /// The zapped event ID, if this zap references a specific note or other
  /// event. NIP-57 typically uses the last `["e", <id>]` (or `["a", ...]` if
  /// zapping a parameterized replaceable event).
  ///
  /// This tries "e" tags first, and if none found, looks for "a" tags.
  /// Return whichever suits your usage, or extend to handle both.
  String? get zappedEventId {
    // Attempt to find the last "e" tag
    final eTags =
        tags != null
            ? tags!.where((t) => t.isNotEmpty && t.first == 'e').toList()
            : [];
    if (eTags.isNotEmpty) {
      return eTags.last.length > 1 ? eTags.last[1] : null;
    }

    // If no "e" tag found, maybe it's an addressable event "a" tag
    final aTag =
        tags != null
            ? tags!.firstWhere(
              (t) => t.isNotEmpty && t.first == 'a',
              orElse: () => [],
            )
            : [];
    if (aTag.length > 1) return aTag[1];
    return null;
  }

  /// The pubkey of the user who is being zapped. Usually, if you "zap" a
  /// note, that note's author is included as a `p` tag. The last `p` is
  /// considered the actual target. Some zaps only set one `p` tag.
  String? get zappedAuthorPubkey {
    final pTags =
        tags != null
            ? tags!.where((t) => t.isNotEmpty && t.first == 'p').toList()
            : [];
    if (pTags.isEmpty) return null;
    return pTags.last.length > 1 ? pTags.last[1] : null;
  }

  /// The amount of the zap in **millisats**, if present, from a tag
  /// like `["amount","1000"]`. 1000 msats = 1 sat.
  int? get amountMsats {
    final tag = tags!.firstWhere(
      (t) => t.isNotEmpty && t.first == 'amount',
      orElse: () => [],
    );
    if (tag.length > 1) {
      return int.tryParse(tag[1]);
    }
    return null;
  }

  /// Returns a list of recommended or known relays, often used to verify
  /// the context of the zapped event or the profile. Found in `["relays", ...]`.
  /// They might appear multiple times or in a single tag with multiple URLs.
  List<String> get relays {
    // Possibly multiple "relays" tags
    final allRelayTags = tags!.where(
      (t) => t.isNotEmpty && t.first == 'relays',
    );
    if (allRelayTags.isEmpty) return [];
    // Collect all subsequent items from each tag
    final results = <String>[];
    for (final relayTag in allRelayTags) {
      if (relayTag.length > 1) {
        // everything after index 0 is a relay url
        results.addAll(relayTag.sublist(1));
      }
    }
    return results;
  }
}

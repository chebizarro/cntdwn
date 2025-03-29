import 'package:dart_nostr/nostr/model/event/event.dart';

/// Lightweight model for custom emoji data.
class CustomEmoji {
  /// The shortcode (e.g. "soapbox")
  final String shortCode;

  /// The image URL to display (PNG, JPEG, etc).
  final String url;

  const CustomEmoji({required this.shortCode, required this.url});

  @override
  String toString() => ':$shortCode: -> $url';
}

/// Possible reaction types per NIP-25.
enum ReactionType {
  like,
  dislike,
  customEmoji, // e.g. :heart_eyes:
}

/// Provides NIP-25 helpers for kind 7 reaction events.
extension ReactionEventExtension on NostrEvent {
  /// Check if this event is indeed a kind 7 reaction event.
  bool get isNip25Reaction => kind == 7;

  /// Returns the short reaction content (the `.content`).
  ///
  /// - A single `+` or empty string means "like"
  /// - A single `-` means "dislike"
  /// - Any other string is typically a custom emoji or textual reaction
  String get reactionContent {
    // If content is empty, interpret that as a `+` (like).
    if (content == null || content!.trim().isEmpty) {
      return '+';
    }
    return content!.trim();
  }

  /// Derives the [ReactionType] from the content.
  ReactionType get reactionType {
    final r = reactionContent;
    if (r == '+' || r.isEmpty) {
      return ReactionType.like;
    } else if (r == '-') {
      return ReactionType.dislike;
    } else {
      return ReactionType.customEmoji;
    }
  }

  /// Parses out any custom emojis from NIP-30 "emoji" tags.
  /// Each tag has the shape: `["emoji", "<shortcode>", "<url>"]`.
  List<CustomEmoji> get customEmojis {
    return tags != null
        ? tags!
            .where((t) => t.isNotEmpty && t.first == 'emoji')
            .map((t) {
              final shortCode = t.length > 1 ? t[1] : '';
              final url = t.length > 2 ? t[2] : '';
              return CustomEmoji(shortCode: shortCode, url: url);
            })
            .where((ce) => ce.shortCode.isNotEmpty && ce.url.isNotEmpty)
            .toList()
        : [];
  }

  /// Returns the ID of the event being reacted to.
  /// NIP-25 states the last `["e", <event-id>]` tag is the target,
  /// but often clients supply exactly one `e` tag.
  String? get reactedEventId {
    // Find the last e-tag. If you trust the last is the target,
    // or you can just do a single search if you expect one e-tag only.
    final eTags =
        tags != null
            ? tags!.where((t) => t.isNotEmpty && t.first == 'e').toList()
            : [];
    if (eTags.isEmpty) {
      return null;
    }
    return eTags.last.length > 1 ? eTags.last[1] : null;
  }

  /// Returns the pubkey of the author of the event being reacted to (optional).
  /// If multiple `["p", <pubkey>]` tags exist, we follow NIP-25's note that
  /// the last p-tag is the actual target.
  String? get reactedAuthorPubkey {
    final pTags =
        tags != null
            ? tags!.where((t) => t.isNotEmpty && t.first == 'p').toList()
            : [];
    if (pTags.isEmpty) {
      return null;
    }
    return pTags.last.length > 1 ? pTags.last[1] : null;
  }

  /// If present, the `'k'` tag might indicate the original event's kind
  /// for the reacted event (some clients include this).
  /// This is optional per NIP-25.
  int? get reactedEventKind {
    final kTag =
        tags != null
            ? tags!.firstWhere(
              (tag) => tag.isNotEmpty && tag.first == 'k',
              orElse: () => [],
            )
            : [];
    if (kTag.length > 1) {
      final val = int.tryParse(kTag[1]);
      return val;
    }
    return null;
  }
}

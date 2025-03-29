import 'package:vidrome/data/models/video_variants.dart';
import 'package:dart_nostr/dart_nostr.dart';

extension NostrEventExtensions on NostrEvent {
  // Getters para acceder fácilmente a los tags específicos
  String? get recipient => _getTagValue('p');
  String? get dTag => _getTagValue('d');

  String? _getTagValue(String key) {
    final tag = tags?.firstWhere((t) => t[0] == key, orElse: () => []);
    return (tag != null && tag.length > 1) ? tag[1] : null;
  }

  String? get videoUrl {
    final rTagUrl = tags
        ?.firstWhere(
          (tag) =>
              tag.firstOrNull == 'r' &&
              tag.length > 1 &&
              tag[1].endsWith('.mp4'),
          orElse: () => [],
        )
        .elementAtOrNull(1);

    // Fallback to content parsing if no r tag is found.
    if (rTagUrl == null || rTagUrl.isEmpty) {
      final contentUrl = _extractUrlFromContent(content!);
      return contentUrl;
    }

    return rTagUrl;
  }

  String? _extractUrlFromContent(String text) {
    final urlRegEx = RegExp(
      r'(https?:\/\/[^\s]+\.mp4)',
    ); // Match .mp4 URLs only
    final match = urlRegEx.firstMatch(text);
    return match?.group(0);
  }
}

extension Nip71 on NostrEvent {
  /// True if this event is a NIP-71 “video” event (kind 21 or 22).
  bool get isNip71Video => kind == 21 || kind == 22;

  /// The "title" field, if present. (["title", "some text"])
  String? get videoTitle {
    final t = _findTagValue('title');
    return t.isNotEmpty ? t : null;
  }

  /// The "published_at" tag, as an integer timestamp if valid.
  int? get videoPublishedAt {
    final raw = _findTagValue('published_at');
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  /// The “duration” tag, in seconds if present.
  int? get videoDuration {
    final raw = _findTagValue('duration');
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  /// The “content-warning” tag, if present (for NSFW or similar).
  String? get videoContentWarning {
    final cw = _findTagValue('content-warning');
    return cw.isNotEmpty ? cw : null;
  }

  /// Retrieves all the `["imeta", ...]` tags, returning
  /// a structured list of `VideoVariant`.
  List<VideoVariant> get videoVariants {
    final variants = <VideoVariant>[];

    // Extract all "imeta" tags from event
    final imetaTags = tags?.where(
      (tag) => tag.isNotEmpty && tag.first == 'imeta',
    );
    for (final tag in imetaTags!) {
      // tag structure is like:
      // ["imeta",
      //   "dim 1920x1080",
      //   "url https://some.com/1080/12345.mp4",
      //   "x <some file hash>",
      //   "m video/mp4",
      //   "image https://some.com/1080/preview.jpg",
      //   "fallback https://somebackup.com/1080/12345.mp4",
      //   "service nip96",
      //   ...]
      //
      // We parse out each property by prefix: "dim", "url", "x", "m", "image", "fallback", "service", ...
      String? dimension;
      String? url;
      String? hash;
      String? mimeType;
      final images = <String>[];
      final fallbackUrls = <String>[];
      String? service;

      // Skip the first element "imeta", parse the rest
      for (int i = 1; i < tag.length; i++) {
        final segment = tag[i];
        // Each segment is something like: "dim 1920x1080" or "url https://..."
        final parts = segment.split(' ');
        if (parts.isEmpty) continue;

        switch (parts[0]) {
          case 'dim':
            // e.g. "dim 1920x1080"
            if (parts.length > 1) dimension = parts.sublist(1).join(' ');
            break;
          case 'url':
            if (parts.length > 1) url = parts.sublist(1).join(' ');
            break;
          case 'x':
            if (parts.length > 1) hash = parts.sublist(1).join(' ');
            break;
          case 'm':
            if (parts.length > 1) mimeType = parts.sublist(1).join(' ');
            break;
          case 'image':
            if (parts.length > 1) {
              final imageUrl = parts.sublist(1).join(' ');
              images.add(imageUrl);
            }
            break;
          case 'fallback':
            if (parts.length > 1) {
              final fallback = parts.sublist(1).join(' ');
              fallbackUrls.add(fallback);
            }
            break;
          case 'service':
            if (parts.length > 1) service = parts.sublist(1).join(' ');
            break;
        }
      }

      variants.add(
        VideoVariant(
          dimension: dimension,
          url: url,
          hash: hash,
          mimeType: mimeType,
          images: images,
          fallbackUrls: fallbackUrls,
          service: service,
        ),
      );
    }

    return variants;
  }

  // Helper to search for a single-value tag like ["title", "Video Title"] or ["duration", "120"] etc.
  String _findTagValue(String tagName) {
    for (final tag in tags!) {
      // Each tag is a List<String>, e.g. ["title", "A Great Video"]
      if (tag.isNotEmpty && tag.first == tagName && tag.length > 1) {
        return tag[1];
      }
    }
    return '';
  }
}

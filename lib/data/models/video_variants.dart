/// Represents a single video variant derived from a `["imeta", ...]` tag.
/// Typically each variant has a different resolution or format.
class VideoVariant {
  final String? dimension; // e.g. "1920x1080"
  final String? url; // primary server URL
  final String? hash; // `x` attribute (file hash, optional)
  final String? mimeType; // e.g. "video/mp4" or "application/x-mpegURL"
  final List<String> images; // preview image URLs
  final List<String> fallbackUrls; // fallback server URLs
  final String? service; // e.g. "nip96", if present

  VideoVariant({
    this.dimension,
    this.url,
    this.hash,
    this.mimeType,
    List<String>? images,
    List<String>? fallbackUrls,
    this.service,
  }) : images = images ?? [],
       fallbackUrls = fallbackUrls ?? [];
}

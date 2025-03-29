import 'dart:convert';
import 'package:dart_nostr/dart_nostr.dart';

class ProfileMetadata {
  final String? name;
  final String? about;
  final String? picture;
  final String? displayName;
  final String? website;
  final String? banner;
  final String? nip05;
  final bool bot;

  ProfileMetadata({
    this.name,
    this.about,
    this.picture,
    this.displayName,
    this.website,
    this.banner,
    this.nip05,
    this.bot = false,
  });
  
  factory ProfileMetadata.fromJson(Map<String, dynamic> json) {
    return ProfileMetadata(
      name: json['name'],
      about: json['about'],
      picture: json['picture'],
      displayName: json['display_name'],
      website: json['website'],
      banner: json['banner'],
      nip05: json['nip05'],
      bot: json['bot'] ?? false,
    );
  }
}

extension ProfileMetadataExt on NostrEvent {

  ProfileMetadata getProfileMetadata() {
    if (kind != 0) {
      throw Exception('Invalid kind for profile metadata: $kind');
    }

    final json = jsonDecode(content!);
    return ProfileMetadata.fromJson(json);
  }
}
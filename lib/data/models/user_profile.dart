import 'package:vidrome/data/models/profile_metadata.dart';

class UserProfile {
  final String pubkey;
  ProfileMetadata? metadata;

  UserProfile({required this.pubkey, this.metadata});
}

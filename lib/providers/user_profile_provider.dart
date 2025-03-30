import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserProfile {
  final String pubkey;
  final String displayName;
  final String about;
  final String pictureUrl;

  UserProfile({
    required this.pubkey,
    required this.displayName,
    required this.about,
    required this.pictureUrl,
  });
}

class UserProfileNotifier extends StateNotifier<UserProfile?> {
  UserProfileNotifier() : super(null);

  void login(UserProfile profile) {
    state = profile;
  }

  void logout() {
    state = null;
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile?>(
  (ref) => UserProfileNotifier(),
);

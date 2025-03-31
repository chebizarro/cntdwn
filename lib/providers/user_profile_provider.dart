import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidrome/data/models/user_profile.dart';

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

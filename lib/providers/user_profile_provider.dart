import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidrome/data/models/user_profile.dart';
import 'package:vidrome/services/auth_service.dart';

class UserProfileNotifier extends StateNotifier<UserProfile?> {
  final AuthService _authService;

  UserProfileNotifier(this._authService) : super(null);

  void login(UserProfile profile) {
    AuthService.nip55.getPublicKey();
    state = profile;
  }

  void logout() {
    state = null;
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile?>((ref) {
      final authService = AuthService();
      return UserProfileNotifier(authService);
    });

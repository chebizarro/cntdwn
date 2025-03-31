import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vidrome/data/models/user_profile.dart';
import 'package:vidrome/providers/user_profile_provider.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('You are not logged in.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _handleNip55Login(ref);
                },
                child: const Text('Login with NIP-55'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  _handleNip46Login(ref);
                },
                child: const Text('Login with NIP-46'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  context.push('/new_user');
                },
                child: const Text('New User'),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('User Profile'),
          actions: [
            IconButton(
              onPressed: () {
                // Log out
                ref.read(userProfileProvider.notifier).logout();
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage: NetworkImage(user.metadata!.picture!),
                  onBackgroundImageError: (error, stack) {
                    // fallback avatar
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  user.metadata!.displayName!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '@${user.pubkey.substring(0, 8)}...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Text(
                  user.metadata!.about!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Do something
                  },
                  child: const Text("Edit Profile"),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _handleNip55Login(WidgetRef ref) {
    final userProfile = UserProfile(
      pubkey: 'exampleNip55Pubkey',
    );
    ref.read(userProfileProvider.notifier).login(userProfile);
  }

  void _handleNip46Login(WidgetRef ref) {
    final userProfile = UserProfile(
      pubkey: 'exampleNip46Pubkey',
    );
    ref.read(userProfileProvider.notifier).login(userProfile);
  }
}

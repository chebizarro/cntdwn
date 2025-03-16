import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Example user data
    final userName = "John Doe";
    final videosCount = 10;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blueGrey,
            child: Text(
              userName[0],
              style: const TextStyle(fontSize: 32, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(userName, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text('$videosCount videos posted'),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/preferences');
            },
            child: const Text('App Preferences'),
          ),
          // Could display a grid of uploaded videos, etc.
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vidrome/data/models/profile_metadata.dart';
import 'package:vidrome/data/models/user_profile.dart';
import 'dart:math';

import 'package:vidrome/providers/user_profile_provider.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  CreateAccountScreenState createState() => CreateAccountScreenState();
}

class CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  final _displayNameCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  final _pictureCtrl = TextEditingController();

  late String newPrivKeyHex;

  @override
  void initState() {
    super.initState();
    newPrivKeyHex = _generateFakeHexPrivateKey();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                "Your new private key (keep safe):",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SelectableText(newPrivKeyHex),
              const SizedBox(height: 16),
              TextFormField(
                controller: _displayNameCtrl,
                decoration: const InputDecoration(labelText: "Display Name"),
                validator:
                    (val) =>
                        val == null || val.isEmpty ? "Required field" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _aboutCtrl,
                decoration: const InputDecoration(labelText: "About"),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pictureCtrl,
                decoration: const InputDecoration(labelText: "Picture URL"),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _onCreateAccount,
                child: const Text("Create & Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onCreateAccount() {
    if (_formKey.currentState?.validate() ?? false) {
      final userPubkey = "pubkey_of_${newPrivKeyHex.substring(0, 12)}";

      final user = UserProfile(
        pubkey: userPubkey,
        metadata: ProfileMetadata(
          displayName: _displayNameCtrl.text,
          about: _aboutCtrl.text,
          picture:
              _pictureCtrl.text.isNotEmpty
                  ? _pictureCtrl.text
                  : "https://placekitten.com/210/210",
        ),
      );
      ref.read(userProfileProvider.notifier).login(user);
      context.pop();
    }
  }

  String _generateFakeHexPrivateKey() {
    final rand = Random.secure();
    final values = List<int>.generate(32, (_) => rand.nextInt(256));
    return values.map((val) => val.toRadixString(16).padLeft(2, '0')).join();
  }
}

import 'dart:convert';

import 'package:vidrome/features/signer/key_signer.dart';
import 'package:nip55/signer_plugin.dart';
import 'package:vidrome/utils/nostr_utils.dart';

class Nip55Signer implements KeySigner {
  final _signer = SignerPlugin();
  String? _publicKey;

  @override
  Future<String> getPublicKey() async {
    if (_publicKey != null) return _publicKey!;
    final pubKeyResult = await _signer.getPublicKey();
    _publicKey = NostrUtils.decodeNpubKeyToPublicKey(pubKeyResult['npub']);
    return _publicKey!;
  }

  @override
  Future<String> sign(Map<String, dynamic> eventJson) async {
    final id = NostrUtils.generateId(eventJson);

    final signResult = await _signer.signEvent(
      jsonEncode(eventJson),
      id,
      _publicKey!,
    );

    return signResult['event'];
  }

  @override
  bool get isRemote => false;
}

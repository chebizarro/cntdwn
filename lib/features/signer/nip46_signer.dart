import 'key_signer.dart';

class Nip46Signer implements KeySigner {
  final String relayUrl;
  final String remoteSignerPubkey;

  Nip46Signer({required this.relayUrl, required this.remoteSignerPubkey});

  @override
  Future<String> getPublicKey() async => remoteSignerPubkey;

  @override
  Future<String> sign(Map<String, dynamic> eventJson) async {
    throw UnimplementedError('NIP-46 remote signing not implemented yet.');
  }

  @override
  bool get isRemote => true;
}

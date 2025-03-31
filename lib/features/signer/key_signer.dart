abstract class KeySigner {
  /// Returns the public key for this signer
  Future<String> getPublicKey();

  /// Signs the given event content and returns the signature
  Future<String> sign(Map<String, dynamic> eventJson);

  /// Optional: whether this signer is local or remote
  bool get isRemote;
}

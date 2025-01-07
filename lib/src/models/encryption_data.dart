class EncryptionData {
  final List<int> ciphertext;

  ///Nonce ("initialization vector", "IV", "salt") is a non-secret sequence of bytes required by most [Cipher] algorithms.
  final List<int> nonce;
  final List<int> tag;

  EncryptionData({
    required this.ciphertext,
    required this.nonce,
    required this.tag,
  });
}

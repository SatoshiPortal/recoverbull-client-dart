import 'dart:math';
import 'dart:typed_data';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip85/bip85.dart';

Uint8List generateRandomSalt({int length = 32}) {
  final secureRandom = Random.secure();
  final saltBytes = Uint8List(length);
  for (int i = 0; i < length; i++) {
    saltBytes[i] = secureRandom.nextInt(256);
  }
  return saltBytes;
}

List<int> deriveBip85({required String xprv, required String path}) {
  //TODO: Implement actual derivation logic
  // This is a dummy implementation for demonstration purposes.
  //
  //TODO; Finalize the derivation key length
  try {
  final derived = derive(xprv: xprv, path: path).sublist(0, 32);
  return derived;
  } catch (e) {
    throw BackupException('Failed to derive backup key: ${e.toString()}');
  }
}

//TODO; verify if both netowrktype values are correct
extension NetworkTypeGetter on String? {
  bip32.NetworkType get networkType {
    return (this == "mainnet" || this == null)
        ? bip32.NetworkType(
            wif: 0x80,
            bip32: bip32.Bip32Type(
              public: 0x0488b21e,
              private: 0x0488ade4,
            ),
          )
        : bip32.NetworkType(
            wif: 0xef,
            bip32: bip32.Bip32Type(
              public: 0x043587cf,
              private: 0x04358394,
            ),
          );
  }
}

import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

var _backupKey = '';
var _keychainUrl = '';
var _websocketUrl = '';
late KeyPair _pair;

class Global {
  static String get backupKey => _backupKey;
  static set backupKey(String v) => _backupKey = v;
  static String get keychainUrl => _keychainUrl;
  static String get websocketUrl => _websocketUrl;
  static KeyPair get pair => _pair;

  static Future<void> init() async {
    await dotenv.load(fileName: ".env");

    _keychainUrl = dotenv.env['KEYCHAIN_URL']!;
    _websocketUrl = dotenv.env['WEBSOCKET_URL']!;

    // TODO: backup key should be derivated (BIP85) from the wallet
    Global.backupKey = 'w3wpm7f1/9jZMp0FKYM0KowyNP87P6MqKSGHNB9xRtc=';

    // TODO: generate secure RSA key pair with BIP85
    _pair = await RSA.generate(2048);
  }
}

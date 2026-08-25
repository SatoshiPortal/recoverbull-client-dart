import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:recoverbull/recoverbull.dart';

void main() {
  final client = HttpClient();

  tearDownAll(() => client.close(force: true));

  for (final uri in [
    Uri.parse('https://keyserver.example'),
    Uri.parse('http://service.onion'),
    Uri.parse('http://nested.service.onion'),
    Uri.parse('http://localhost:8080'),
    Uri.parse('http://127.0.0.1:8080'),
    Uri.parse('http://[::1]:8080'),
  ]) {
    test('accepts $uri', () {
      expect(() => KeyServer(address: uri, client: client), returnsNormally);
    });
  }

  for (final uri in [
    Uri.parse('http://service.example'),
    Uri.parse('http://onion.com'),
    Uri.parse('ftp://localhost'),
    Uri.parse('file:///tmp/keyserver'),
    Uri.parse('https://user:password@keyserver.example'),
    Uri.parse('https://keyserver.example/path?query#fragment'),
  ]) {
    test('rejects unsafe $uri', () {
      expect(
        () => KeyServer(address: uri, client: client),
        throwsArgumentError,
      );
    });
  }
}

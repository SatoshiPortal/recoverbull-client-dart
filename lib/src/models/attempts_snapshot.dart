import 'dart:convert';
import 'dart:typed_data';

import 'package:hex/hex.dart';
import 'package:pointycastle/export.dart';

/// One entry of the public `/attempts` telemetry snapshot: the attempt
/// counters of one identifier currently rate-limited by the key server.
///
/// Timestamps are hour-truncated by the server on purpose: the snapshot is
/// public, and exact timestamps would ease correlation.
class AttemptEntry {
  /// SHA-256 over the **raw identifier bytes** (not the hex string).
  final String idHash;
  final int totalAttempts;
  final int failedAttempts;
  final DateTime windowStartedAt;
  final DateTime lastAttemptAt;

  AttemptEntry({
    required this.idHash,
    required this.totalAttempts,
    required this.failedAttempts,
    required this.windowStartedAt,
    required this.lastAttemptAt,
  });

  factory AttemptEntry.fromMap(Map<String, dynamic> map) {
    return AttemptEntry(
      idHash: map['id_hash'] as String,
      totalAttempts: map['total_attempts'] as int,
      failedAttempts: map['failed_attempts'] as int,
      windowStartedAt: DateTime.parse(map['window_started_at'] as String),
      lastAttemptAt: DateTime.parse(map['last_attempt_at'] as String),
    );
  }
}

/// The public `/attempts` telemetry snapshot: attempt counters for the
/// identifiers currently rate-limited by the key server.
///
/// Advisory by design: the server cannot distinguish an attacker from the
/// user or another of the user's devices, and a compromised server can
/// fabricate or suppress counters. Consumers must warn, never act
/// automatically.
class AttemptsSnapshot {
  final int version;
  final DateTime collectionStartedAt;
  final List<AttemptEntry> entries;

  AttemptsSnapshot({
    required this.version,
    required this.collectionStartedAt,
    required this.entries,
  });

  factory AttemptsSnapshot.fromMap(Map<String, dynamic> map) {
    return AttemptsSnapshot(
      version: map['version'] as int,
      collectionStartedAt:
          DateTime.parse(map['collection_started_at'] as String),
      entries: (map['entries'] as List<dynamic>)
          .map((e) => AttemptEntry.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Parses the decoded JSON body. Kept synchronous and top-level-friendly
  /// so it can run in a worker isolate.
  static AttemptsSnapshot parse(String body) =>
      AttemptsSnapshot.fromMap(json.decode(body) as Map<String, dynamic>);

  /// Returns only the entries matching locally known backup identifiers.
  /// The full snapshot (up to 100,000 entries) should never be retained:
  /// filter, then drop it.
  List<AttemptEntry> entriesMatching(Iterable<List<int>> backupIds) {
    final hashes = backupIds.map(attemptsIdHash).toSet();
    return entriesMatchingHashes(hashes);
  }

  /// Returns only the entries whose [AttemptEntry.idHash] is in [hashes].
  /// Consumers that store pre-computed identifier hashes (never the raw
  /// identifiers) match through this variant.
  List<AttemptEntry> entriesMatchingHashes(Iterable<String> hashes) {
    final wanted = hashes.toSet();
    return entries.where((e) => wanted.contains(e.idHash)).toList();
  }
}

/// The identifier hash published by the key server: SHA-256 over the **raw
/// identifier bytes** (not the hex string). Pinned byte-for-byte against the
/// server implementation by a shared test vector.
String attemptsIdHash(List<int> backupId) =>
    HEX.encode(SHA256Digest().process(Uint8List.fromList(backupId)));

/// Convenience hex variant for callers holding the identifier as hex.
String attemptsIdHashFromHex(String backupIdHex) =>
    attemptsIdHash(HEX.decode(backupIdHex));

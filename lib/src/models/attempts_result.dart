import 'package:recoverbull/src/models/attempts_snapshot.dart';

/// The result of a conditional `GET /attempts`.
sealed class AttemptsResult {
  const AttemptsResult();
}

/// The snapshot is unchanged since the caller's ETag: no body was parsed
/// and local state can be reused as-is.
class AttemptsNotModified extends AttemptsResult {
  const AttemptsNotModified();
}

/// A fresh snapshot was downloaded and parsed.
class AttemptsModified extends AttemptsResult {
  /// The snapshot's strong ETag: persist it and send it back as
  /// `If-None-Match` on the next poll.
  final String? etag;

  /// The server's `Cache-Control` max-age for this snapshot, in seconds.
  final int? maxAgeSeconds;

  final int version;
  final DateTime collectionStartedAt;

  /// Total entries in the snapshot, before filtering: compare with the
  /// server's `max_attempt_identifiers` from `/info` to detect map pressure.
  final int totalEntries;

  /// Only the entries matching the backup identifiers passed to
  /// [KeyServer.attempts]: the full snapshot (up to 100,000 entries) is
  /// parsed in a worker isolate and never retained by the caller.
  final List<AttemptEntry> matchingEntries;

  const AttemptsModified({
    required this.etag,
    required this.maxAgeSeconds,
    required this.version,
    required this.collectionStartedAt,
    required this.totalEntries,
    required this.matchingEntries,
  });
}

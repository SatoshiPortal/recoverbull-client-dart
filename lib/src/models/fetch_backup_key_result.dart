import 'package:recoverbull/src/models/attempt_status.dart';

/// The result of a successful `/fetch` or `/trash`: the recovered backup key
/// plus the exact attempt counters of the identifier's current rate-limit
/// window.
class FetchBackupKeyResult {
  final List<int> backupKey;

  /// The identifier's attempt counters. Null against older servers that do
  /// not send `attempt_status`: consumers must skip telemetry reconciliation
  /// rather than treat a fabricated value as authoritative.
  final AttemptStatus? attemptStatus;

  FetchBackupKeyResult({
    required this.backupKey,
    required this.attemptStatus,
  });
}

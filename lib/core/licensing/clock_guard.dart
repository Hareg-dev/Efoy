import 'secure_store.dart';

/// Best-effort offline clock-rollback detection.
///
/// The app records the newest wall-clock time it has ever observed (in
/// secure storage, keyed per installation). If the current device clock is
/// behind the recorded time by more than [rollbackTolerance], the device
/// clock was moved backwards (or restored from an old backup) and
/// time-limited licenses are treated as expired until the clock catches up.
///
/// Documented limitations (this is deliberately NOT tamper-proof):
/// - A user who resets/clears secure storage removes the recorded time
///   together with the installation id, so the license would fail on
///   installation-mismatch anyway.
/// - Winding the clock far FORWARD and back within the tolerance window
///   is not detected.
/// - Airplane mode plus never re-opening the app cannot be detected; the
///   app only checks while it runs.
class ClockGuard {
  ClockGuard({required SecureStore secureStore})
    // DI style keeps the store injectable from other libraries.
    // ignore: prefer_initializing_formals
    : _secureStore = secureStore;

  static const String _lastSeenKey = 'efoy_last_seen_clock_ms';

  /// How far the clock may sit in the past relative to the recorded
  /// high-water mark before we flag a rollback. Generous enough for time
  /// zone corrections, small manual adjustments and restore-from-backup
  /// scenarios; tight enough to catch deliberate multi-day rollbacks.
  static const Duration rollbackTolerance = Duration(hours: 24);

  final SecureStore _secureStore;

  /// Observes [now] and reports whether the clock appears rolled back.
  ///
  /// Updates the recorded high-water mark when the clock moves forward.
  Future<bool> checkAndRecord(DateTime now) async {
    final nowMs = now.millisecondsSinceEpoch;
    try {
      final stored = await _secureStore.read(_lastSeenKey);
      final lastSeenMs = stored == null ? null : int.tryParse(stored);

      if (lastSeenMs != null &&
          nowMs < lastSeenMs - rollbackTolerance.inMilliseconds) {
        // Clock moved back beyond tolerance. Keep the high-water mark so the
        // license stays blocked until the clock is corrected.
        return true;
      }

      if (lastSeenMs == null || nowMs > lastSeenMs) {
        await _secureStore.write(_lastSeenKey, nowMs.toString());
      }
      return false;
    } on SecureStoreUnavailableException {
      // Storage is unavailable: fail open for the *guard* (the licensing
      // service independently blocks operations when storage is broken).
      return false;
    }
  }

  /// The recorded high-water mark, for diagnostics. Null when unavailable.
  Future<DateTime?> lastSeenClock() async {
    try {
      final stored = await _secureStore.read(_lastSeenKey);
      final ms = stored == null ? null : int.tryParse(stored);
      return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    } on SecureStoreUnavailableException {
      return null;
    }
  }
}

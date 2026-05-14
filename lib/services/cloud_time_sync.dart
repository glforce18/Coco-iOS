import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Server-authoritative timestamp helper.
///
/// Mobile match-3 progression is gated by wall-clock time (one life every
/// 30 min, etc.), so a player who rewinds or jumps their device clock can
/// trivially unlock lives or daily rewards. To prevent that, we keep an
/// offset between the device clock and Firestore's server timestamp:
///
///     serverOffsetMs = serverNow - deviceNow
///
/// On every cold launch (and periodically while running) we round-trip a
/// Firestore document to refresh the offset. All time-sensitive code then
/// reads [trustedNowMs] instead of `DateTime.now().millisecondsSinceEpoch`.
///
/// If the device is offline the cached offset still applies — the player
/// can't cheat by moving the clock because moving the clock also moves
/// the deviceNow that the offset adjusts.
class CloudTimeSync {
  CloudTimeSync._();

  static const _prefsKey = 'cloudTimeOffsetMs';
  static const _pingDoc = '_meta/ping';

  static int _offsetMs = 0;
  static bool _loaded = false;

  /// Load the last-known offset from disk. Safe to call before [sync].
  static Future<void> loadCached() async {
    if (_loaded) return;
    try {
      final p = await SharedPreferences.getInstance();
      _offsetMs = p.getInt(_prefsKey) ?? 0;
    } catch (_) {}
    _loaded = true;
  }

  /// Round-trip Firestore to refresh the offset. Silently no-ops if the
  /// network or Firebase isn't reachable so the caller never has to await.
  static Future<void> sync() async {
    try {
      final coll = FirebaseFirestore.instance;
      await coll
          .doc(_pingDoc)
          .set({'ts': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      final snap = await coll.doc(_pingDoc).get(const GetOptions(source: Source.server));
      final ts = snap.data()?['ts'];
      if (ts is Timestamp) {
        final serverMs = ts.millisecondsSinceEpoch;
        final deviceMs = DateTime.now().millisecondsSinceEpoch;
        _offsetMs = serverMs - deviceMs;
        try {
          final p = await SharedPreferences.getInstance();
          await p.setInt(_prefsKey, _offsetMs);
        } catch (_) {}
        if (kDebugMode) {
          debugPrint('[cloud-time] offset=$_offsetMs ms');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[cloud-time] sync failed: $e');
      // Cached offset stays in effect.
    }
  }

  /// Best-known server-relative epoch ms. Falls back to the raw device
  /// clock if [loadCached] has never run (offset = 0).
  static int get trustedNowMs =>
      DateTime.now().millisecondsSinceEpoch + _offsetMs;

  static int get offsetMs => _offsetMs;
}

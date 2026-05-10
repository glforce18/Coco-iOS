import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Self-hosted in-app update check.
///
/// Fetches a small JSON manifest at app launch describing the latest
/// shipped version + the minimum supported version. Surfaces three
/// outcomes via [UpdateCheckResult]:
///   • [UpdateCheckResult.upToDate] — current build matches latest.
///   • [UpdateCheckResult.softUpdate] — newer release available, banner
///     prompts player but they can dismiss it.
///   • [UpdateCheckResult.forceUpdate] — current build is below
///     `minSupported`, blocking modal that links to store.
///
/// JSON shape (`https://ilacbilgi.org/coco/latest-version.json`):
/// ```json
/// {
///   "latest": "2.4.0",
///   "minSupported": "2.3.0",
///   "androidUrl": "https://...",
///   "iosUrl": "https://...",
///   "notes": "Yeni özellikler ve düzeltmeler."
/// }
/// ```
class UpdateChecker {
  UpdateChecker._();
  static final UpdateChecker instance = UpdateChecker._();

  static const _manifestUrl = 'https://ilacbilgi.org/coco/latest-version.json';

  Future<UpdateCheckResult> check() async {
    try {
      final pkg = await PackageInfo.fromPlatform();
      final current = pkg.version; // e.g. "2.3.7"

      final res = await http
          .get(Uri.parse(_manifestUrl))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) {
        return UpdateCheckResult.upToDate(current);
      }

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final latest = (json['latest'] as String?) ?? current;
      final minSupported = (json['minSupported'] as String?) ?? '0.0.0';
      final androidUrl = (json['androidUrl'] as String?) ?? '';
      final iosUrl = (json['iosUrl'] as String?) ?? '';
      final notes = (json['notes'] as String?) ?? '';
      final storeUrl = Platform.isIOS ? iosUrl : androidUrl;

      if (_compareVersions(current, minSupported) < 0) {
        return UpdateCheckResult(
          kind: UpdateKind.forceUpdate,
          currentVersion: current,
          latestVersion: latest,
          notes: notes,
          storeUrl: storeUrl,
        );
      }
      if (_compareVersions(current, latest) < 0) {
        return UpdateCheckResult(
          kind: UpdateKind.softUpdate,
          currentVersion: current,
          latestVersion: latest,
          notes: notes,
          storeUrl: storeUrl,
        );
      }
      return UpdateCheckResult.upToDate(current);
    } catch (e) {
      if (kDebugMode) debugPrint('[update] check failed: $e');
      return UpdateCheckResult.upToDate('0.0.0');
    }
  }

  /// Returns -1 if a < b, 0 if equal, 1 if a > b. Compares dotted
  /// numeric versions like "2.3.7" — non-numeric segments treated as 0.
  static int _compareVersions(String a, String b) {
    final aParts = a.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final bParts = b.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final len = aParts.length > bParts.length ? aParts.length : bParts.length;
    for (int i = 0; i < len; i++) {
      final av = i < aParts.length ? aParts[i] : 0;
      final bv = i < bParts.length ? bParts[i] : 0;
      if (av < bv) return -1;
      if (av > bv) return 1;
    }
    return 0;
  }
}

enum UpdateKind { upToDate, softUpdate, forceUpdate }

class UpdateCheckResult {
  final UpdateKind kind;
  final String currentVersion;
  final String latestVersion;
  final String notes;
  final String storeUrl;

  const UpdateCheckResult({
    required this.kind,
    required this.currentVersion,
    required this.latestVersion,
    required this.notes,
    required this.storeUrl,
  });

  factory UpdateCheckResult.upToDate(String version) => UpdateCheckResult(
        kind: UpdateKind.upToDate,
        currentVersion: version,
        latestVersion: version,
        notes: '',
        storeUrl: '',
      );

  bool get hasUpdate => kind != UpdateKind.upToDate;
  bool get isForced => kind == UpdateKind.forceUpdate;
}

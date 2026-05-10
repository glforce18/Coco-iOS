import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kReleaseMode, kDebugMode;

/// Centralised AdMob ID registry. Test IDs are Google's public sandbox
/// units (always show test ads, no revenue). Production IDs come from the
/// AdMob console — placeholders below MUST be replaced before App Store /
/// Play Store submission.
///
/// Usage: `AdIds.banner` returns the right unit for the current platform
/// AND the right environment (test in debug, prod in release).
class AdIds {
  AdIds._();

  // ─── Test IDs (Google sandbox — never produce revenue) ─────────────
  static const _testAppIdAndroid = 'ca-app-pub-3940256099942544~3347511713';
  static const _testAppIdIos = 'ca-app-pub-3940256099942544~1458002511';
  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';
  static const _testRewardedAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';

  // ─── Production IDs (TODO: replace before submission) ──────────────
  // To wire production IDs:
  //   1. AdMob console → Add app → Coco (Android + iOS separately).
  //   2. Create 3 ad units per app: banner / interstitial / rewarded.
  //   3. Paste the 8 resulting IDs below.
  //   4. Also update App ID in:
  //        android/app/src/main/AndroidManifest.xml (com.google.android.gms.ads.APPLICATION_ID)
  //        ios/Runner/Info.plist (GADApplicationIdentifier)
  //
  // Format: 'ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY' (App ID, with ~)
  //         'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY' (Ad unit, with /)
  // Coco production IDs (AdMob console, 2026-05-10).
  static const _prodAppIdAndroid = 'ca-app-pub-3086183300445644~8012578344';
  static const _prodAppIdIos = 'ca-app-pub-3086183300445644~7212678166';
  static const _prodBannerAndroid = 'ca-app-pub-3086183300445644/3331097304';
  static const _prodBannerIos = 'ca-app-pub-3086183300445644/5906885644';
  static const _prodInterstitialAndroid = 'ca-app-pub-3086183300445644/9595298926';
  static const _prodInterstitialIos = 'ca-app-pub-3086183300445644/4586514823';
  static const _prodRewardedAndroid = 'ca-app-pub-3086183300445644/6558072041';
  static const _prodRewardedIos = 'ca-app-pub-3086183300445644/1967640630';

  /// True when production IDs are wired up (i.e. NOT placeholder).
  /// We keep test IDs for any unit whose prod ID isn't filled in yet so
  /// the SDK never receives a malformed string.
  static bool _isProdReady(String prod) => prod != 'TODO_REPLACE' && prod.isNotEmpty;

  /// Pick test in debug, prod in release — falling back to test if the
  /// release build was shipped with placeholder IDs.
  static String _pick(String testId, String prodId) {
    if (kDebugMode || !kReleaseMode) return testId;
    return _isProdReady(prodId) ? prodId : testId;
  }

  /// AdMob "App ID" used in the manifest / Info.plist meta-data. Surfaced
  /// here for documentation; the actual injection happens in those native
  /// config files at build time.
  static String get appId {
    if (Platform.isIOS) return _pick(_testAppIdIos, _prodAppIdIos);
    return _pick(_testAppIdAndroid, _prodAppIdAndroid);
  }

  /// 320x50 banner unit for game over / profile / shop bottoms.
  static String get banner {
    if (Platform.isIOS) return _pick(_testBannerIos, _prodBannerIos);
    return _pick(_testBannerAndroid, _prodBannerAndroid);
  }

  /// Interstitial unit fired ~every 3-5 levels.
  static String get interstitial {
    if (Platform.isIOS) {
      return _pick(_testInterstitialIos, _prodInterstitialIos);
    }
    return _pick(_testInterstitialAndroid, _prodInterstitialAndroid);
  }

  /// Rewarded video — game over "+3 hamle reklam izle" reward.
  static String get rewarded {
    if (Platform.isIOS) return _pick(_testRewardedIos, _prodRewardedIos);
    return _pick(_testRewardedAndroid, _prodRewardedAndroid);
  }

  /// True when at least one prod ID has been filled in. Used by debug
  /// overlays to badge "TEST AD" so devs know what they're seeing.
  static bool get usingProductionIds {
    if (kDebugMode || !kReleaseMode) return false;
    return _isProdReady(_prodAppIdAndroid) || _isProdReady(_prodAppIdIos);
  }
}

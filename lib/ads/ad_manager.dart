import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:patpat_game/ads/ad_ids.dart';

/// Manages AdMob ads — banner, interstitial, rewarded.
///
/// Degrades gracefully when the SDK is unavailable (emulator without
/// Google Play Services, simulators that haven't been provisioned, etc.):
/// every method just returns/no-ops so the rest of the game keeps working.
///
/// Ad unit IDs are picked by `AdIds` based on platform + build mode, so
/// debug builds always show Google's test sandbox ads and release builds
/// show the production units (once they're filled in).
class AdManager {
  static final AdManager _instance = AdManager._();
  static AdManager get instance => _instance;
  AdManager._();

  bool _initialized = false;
  bool _adsDisabled = false;
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  int _levelsSinceAd = 0;
  int _adThreshold = 3; // Show interstitial every 3-5 levels.

  bool get isInitialized => _initialized;
  bool get isRewardedAdReady => _rewardedAd != null;
  bool get isInterstitialAdReady => _interstitialAd != null;

  set adsDisabled(bool value) {
    _adsDisabled = value;
    if (value) {
      // Drop any pre-loaded ads so we never accidentally serve one.
      _rewardedAd?.dispose();
      _rewardedAd = null;
      _interstitialAd?.dispose();
      _interstitialAd = null;
    }
  }

  Future<void> init() async {
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadRewardedAd();
      _loadInterstitialAd();
    } catch (e) {
      if (kDebugMode) debugPrint('[ads] init failed: $e');
    }
  }

  // ─── Rewarded ──────────────────────────────────────────────────────

  void _loadRewardedAd() {
    if (!_initialized || _adsDisabled || _rewardedAd != null) return;
    RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (e) {
          if (kDebugMode) debugPrint('[ads] rewarded load fail: $e');
          _rewardedAd = null;
        },
      ),
    );
  }

  /// Shows a rewarded ad. Returns true if the ad was shown, false otherwise.
  /// [onRewarded] is called only if the user watched enough of the ad.
  Future<bool> showRewardedAd({required Function() onRewarded}) async {
    if (_rewardedAd == null || _adsDisabled) return false;

    final ad = _rewardedAd!;
    _rewardedAd = null;

    bool rewarded = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAd();
        if (rewarded) onRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedAd();
      },
    );

    await ad.show(onUserEarnedReward: (_, __) => rewarded = true);
    return true;
  }

  // ─── Interstitial ──────────────────────────────────────────────────

  void _loadInterstitialAd() {
    if (!_initialized || _adsDisabled || _interstitialAd != null) return;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (e) {
          if (kDebugMode) debugPrint('[ads] interstitial load fail: $e');
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Returns true if an interstitial ad should be shown after this level.
  /// Level threshold is randomised 3-5 to avoid feeling like a metronome.
  bool shouldShowInterstitial() {
    if (_adsDisabled) return false;
    _levelsSinceAd++;
    return _levelsSinceAd >= _adThreshold && _interstitialAd != null;
  }

  /// Shows an interstitial ad and resets the counter.
  Future<void> showInterstitialAd({Function()? onDismissed}) async {
    if (_interstitialAd == null || _adsDisabled) {
      onDismissed?.call();
      return;
    }

    final ad = _interstitialAd!;
    _interstitialAd = null;
    _levelsSinceAd = 0;
    _adThreshold = 3 + (DateTime.now().millisecond % 3); // 3-5

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitialAd();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitialAd();
        onDismissed?.call();
      },
    );

    await ad.show();
  }

  // ─── Banner ────────────────────────────────────────────────────────

  /// Build a banner ad widget configured against the right unit.
  /// Returns null when ads are disabled (VIP / removeAds purchased).
  /// Caller is responsible for disposing the BannerAd via the widget's
  /// own lifecycle.
  BannerAd? buildBannerAd({
    AdSize size = AdSize.banner,
    void Function()? onLoaded,
    void Function()? onFailed,
  }) {
    if (_adsDisabled || !_initialized) return null;
    return BannerAd(
      size: size,
      adUnitId: AdIds.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded?.call(),
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) debugPrint('[ads] banner fail: $error');
          ad.dispose();
          onFailed?.call();
        },
      ),
    );
  }
}

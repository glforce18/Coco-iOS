import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Manages rewarded and interstitial ads.
/// Degrades gracefully when the ads SDK is unavailable (e.g. emulator).
class AdManager {
  static final AdManager _instance = AdManager._();
  static AdManager get instance => _instance;
  AdManager._();

  bool _initialized = false;
  bool _adsDisabled = false;
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  int _levelsSinceAd = 0;
  int _adThreshold = 3; // Show interstitial every 3-5 levels

  // Test ad unit IDs (replace with production IDs before release)
  static const _rewardedTestId = 'ca-app-pub-3940256099942544/5224354917';
  static const _interstitialTestId = 'ca-app-pub-3940256099942544/1033173712';

  bool get isRewardedAdReady => _rewardedAd != null;
  bool get isInterstitialAdReady => _interstitialAd != null;

  set adsDisabled(bool value) => _adsDisabled = value;

  Future<void> init() async {
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadRewardedAd();
      _loadInterstitialAd();
    } catch (_) {
      // Ads SDK not available — game runs without ads
    }
  }

  void _loadRewardedAd() {
    if (!_initialized || _adsDisabled) return;
    RewardedAd.load(
      adUnitId: _rewardedTestId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (_) => _rewardedAd = null,
      ),
    );
  }

  void _loadInterstitialAd() {
    if (!_initialized || _adsDisabled) return;
    InterstitialAd.load(
      adUnitId: _interstitialTestId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
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

  /// Returns true if an interstitial ad should be shown after this level.
  bool shouldShowInterstitial() {
    if (_adsDisabled) return false;
    _levelsSinceAd++;
    return _levelsSinceAd >= _adThreshold;
  }

  /// Shows an interstitial ad and resets the counter.
  Future<void> showInterstitialAd({Function()? onDismissed}) async {
    if (_interstitialAd == null || _adsDisabled) return;

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
}

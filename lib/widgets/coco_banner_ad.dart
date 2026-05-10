import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:patpat_game/ads/ad_manager.dart';

/// 320x50 banner ad surfaced at the bottom of the game-over overlay,
/// profile screen, and shop. Auto-renders nothing when ads are disabled
/// (VIP / removeAds purchased) or when the SDK fails to load — never
/// pushes the surrounding layout when a banner is unavailable, so the
/// UI is stable in either state.
class CocoBannerAd extends StatefulWidget {
  /// Optional fixed height — defaults to standard banner height (50).
  final double height;

  const CocoBannerAd({super.key, this.height = 50});

  @override
  State<CocoBannerAd> createState() => _CocoBannerAdState();
}

class _CocoBannerAdState extends State<CocoBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = AdManager.instance.buildBannerAd(
      onLoaded: () {
        if (mounted) setState(() => _loaded = true);
      },
      onFailed: () {
        if (mounted) setState(() => _ad = null);
      },
    );
    _ad?.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ad == null || !_loaded) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}

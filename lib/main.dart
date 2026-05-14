import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:patpat_game/auth/auth_manager.dart';
import 'package:patpat_game/billing/billing_manager.dart';
import 'package:patpat_game/ads/ad_manager.dart';
import 'package:patpat_game/notifications/notification_manager.dart';
import 'package:patpat_game/notifications/fcm_manager.dart';
import 'package:patpat_game/router.dart';
import 'package:patpat_game/providers/game_providers.dart';
import 'package:patpat_game/services/cloud_time_sync.dart';
import 'package:patpat_game/widgets/achievement_unlock_toast.dart';
import 'package:patpat_game/widgets/update_banner.dart';
import 'dart:io' show Platform;
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Hide Android system status + navigation bars (immersive sticky); user
  // can swipe from edges to temporarily reveal them. Returns to immersive
  // automatically after a few seconds.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Try to initialize Firebase, but don't crash if config is missing
  try {
    await Firebase.initializeApp();
    AuthManager.instance.firebaseReady = true;
  } catch (_) {
    // Firebase not configured yet — auth features will be disabled
    AuthManager.instance.firebaseReady = false;
  }

  // Pull the cached server-time offset before any time-sensitive code
  // (life regen, daily reward, spin wheel cooldown) reads the clock.
  // Refresh in the background once Firebase is up — the await is on
  // loadCached so we don't block startup waiting for network.
  await CloudTimeSync.loadCached();
  if (AuthManager.instance.firebaseReady) {
    // Fire-and-forget — first life-regen tick will use cached offset,
    // subsequent reads pick up the fresh one once Firestore responds.
    unawaited(CloudTimeSync.sync());
  }

  // Local notification scheduler — independent of Firebase, safe to init.
  await NotificationManager.instance.init();

  runApp(const ProviderScope(child: CocoApp()));
}

class CocoApp extends ConsumerStatefulWidget {
  const CocoApp({super.key});

  @override
  ConsumerState<CocoApp> createState() => _CocoAppState();
}

class _CocoAppState extends ConsumerState<CocoApp> {
  @override
  void initState() {
    super.initState();
    ref.read(playerProgressProvider.notifier).load();
    _initBilling();
    _initAds();
    _initFcm();
  }

  Future<void> _initFcm() async {
    if (!AuthManager.instance.firebaseReady) return;
    await FcmManager.instance.init(
      onToken: (token) async {
        await ref.read(playerProgressProvider.notifier).setFcmToken(token);
      },
    );
  }

  Future<void> _initAds() async {
    final progress = ref.read(playerProgressProvider);
    AdManager.instance.adsDisabled =
        progress.removeAdsPurchased || progress.vipActive;
    // iOS App Tracking Transparency — must be requested BEFORE the ads
    // SDK kicks off so the IDFA decision is in place. Android no-ops.
    await _requestTrackingPermissionIfNeeded();
    await AdManager.instance.init();
  }

  Future<void> _requestTrackingPermissionIfNeeded() async {
    if (!Platform.isIOS) return;
    try {
      final status =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // System prompt — only fires once. Tiny delay so the OS isn't
        // showing the launch image at the same time as the prompt.
        await Future<void>.delayed(const Duration(milliseconds: 250));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (_) {
      // ATT only available on iOS 14.5+ — fall through silently otherwise.
    }
  }

  Future<void> _initBilling() async {
    await BillingManager.instance.init();
    BillingManager.instance.setDeliveryCallback((productId) {
      ref.read(playerProgressProvider.notifier).deliverIAP(productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Coco',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0235),
      ),
      routerConfig: AppRouter.router,
      // Mount the global achievement unlock toast above every screen.
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            const AchievementUnlockToast(),
            // Update banner sits ABOVE the achievement toast so a forced
            // update modal can block all interaction.
            const UpdateBanner(),
          ],
        );
      },
    );
  }
}

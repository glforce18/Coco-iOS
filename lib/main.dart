import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:patpat_game/audio/haptic_manager.dart';
import 'package:patpat_game/audio/music_manager.dart';
import 'package:patpat_game/audio/sound_manager.dart';
import 'package:patpat_game/auth/auth_manager.dart';
import 'package:patpat_game/billing/billing_manager.dart';
import 'package:patpat_game/ads/ad_manager.dart';
import 'package:patpat_game/router.dart';
import 'package:patpat_game/providers/game_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Try to initialize Firebase, but don't crash if config is missing
  try {
    await Firebase.initializeApp();
    AuthManager.instance.firebaseReady = true;
  } catch (_) {
    // Firebase not configured yet — auth features will be disabled
    AuthManager.instance.firebaseReady = false;
  }

  runApp(const ProviderScope(child: PatPatApp()));
}

class PatPatApp extends ConsumerStatefulWidget {
  const PatPatApp({super.key});

  @override
  ConsumerState<PatPatApp> createState() => _PatPatAppState();
}

class _PatPatAppState extends ConsumerState<PatPatApp> {
  @override
  void initState() {
    super.initState();
    ref.read(playerProgressProvider.notifier).load();
    _initAudio();
    _initBilling();
    _initAds();
  }

  Future<void> _initAudio() async {
    await SoundManager.instance.init();
    await MusicManager.instance.init();
    await HapticManager.instance.init();
  }

  Future<void> _initAds() async {
    final progress = ref.read(playerProgressProvider);
    AdManager.instance.adsDisabled =
        progress.removeAdsPurchased || progress.vipActive;
    await AdManager.instance.init();
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
      title: 'PatPat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0235),
      ),
      routerConfig: AppRouter.router,
    );
  }
}

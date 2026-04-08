import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patpat_game/router.dart';
import 'package:patpat_game/providers/game_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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

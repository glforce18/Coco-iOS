import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:patpat_game/screens/achievement_screen.dart';
import 'package:patpat_game/screens/event_screen.dart';
import 'package:patpat_game/screens/game_screen.dart';
import 'package:patpat_game/screens/main_menu_screen.dart';
import 'package:patpat_game/models/level_config.dart';
import 'package:patpat_game/screens/adalar_screen.dart';
import 'package:patpat_game/screens/map_screen.dart';
import 'package:patpat_game/screens/mascot_home_screen.dart';
import 'package:patpat_game/screens/nest_screen.dart';
import 'package:patpat_game/screens/notifications_settings_screen.dart';
import 'package:patpat_game/screens/profile_screen.dart';
import 'package:patpat_game/screens/shop_screen.dart';
import 'package:patpat_game/screens/spin_wheel_screen.dart';
import 'package:patpat_game/screens/splash_screen.dart';

/// Premium fade + slight scale transition — used for all standard routes.
Widget _premiumTransition(
    BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
  return FadeTransition(
    opacity: animation,
    child: ScaleTransition(
      scale: Tween<double>(begin: 0.96, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      ),
      child: child,
    ),
  );
}

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: '/menu',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const MainMenuScreen(),
          transitionsBuilder: _premiumTransition,
          transitionDuration: const Duration(milliseconds: 350),
        ),
      ),
      GoRoute(
        path: '/map',
        pageBuilder: (context, state) {
          final region = state.extra is GameRegion ? state.extra as GameRegion : null;
          // ValueKey forces a fresh MapScreen state when navigating with a
          // different region — otherwise go_router reuses the existing state
          // and `initialRegion` never takes effect (every tap lands on the
          // same old region).
          return CustomTransitionPage(
            key: ValueKey('map-${region?.name ?? 'default'}'),
            child: MapScreen(
              key: ValueKey('mapscreen-${region?.name ?? 'default'}'),
              initialRegion: region,
            ),
            transitionsBuilder: _premiumTransition,
            transitionDuration: const Duration(milliseconds: 350),
          );
        },
      ),
      GoRoute(
        path: '/adalar',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const AdalarScreen(),
          transitionsBuilder: _premiumTransition,
          transitionDuration: const Duration(milliseconds: 350),
        ),
      ),
      GoRoute(
        path: '/shop',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const ShopScreen(),
          transitionsBuilder: _premiumTransition,
          transitionDuration: const Duration(milliseconds: 350),
        ),
      ),
      GoRoute(
        path: '/spin',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const SpinWheelScreen(),
          transitionsBuilder: _premiumTransition,
          transitionDuration: const Duration(milliseconds: 350),
        ),
      ),
      GoRoute(
        path: '/achievements',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const AchievementScreen(),
          transitionsBuilder: _premiumTransition,
          transitionDuration: const Duration(milliseconds: 350),
        ),
      ),
      GoRoute(
        path: '/events',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const EventScreen(),
          transitionsBuilder: _premiumTransition,
          transitionDuration: const Duration(milliseconds: 350),
        ),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const ProfileScreen(),
          transitionsBuilder: _premiumTransition,
          transitionDuration: const Duration(milliseconds: 350),
        ),
      ),
      GoRoute(
        path: '/mascot-home',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const MascotHomeScreen(),
          transitionsBuilder: _premiumTransition,
          transitionDuration: const Duration(milliseconds: 350),
        ),
      ),
      GoRoute(
        path: '/nest',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const NestScreen(),
          transitionsBuilder: _premiumTransition,
          transitionDuration: const Duration(milliseconds: 350),
        ),
      ),
      GoRoute(
        path: '/notifications-settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const NotificationsSettingsScreen(),
          transitionsBuilder: _premiumTransition,
          transitionDuration: const Duration(milliseconds: 350),
        ),
      ),
      GoRoute(
        path: '/game/:level',
        pageBuilder: (context, state) {
          final level = int.parse(state.pathParameters['level'] ?? '1');
          return CustomTransitionPage(
            child: GameScreen(level: level),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                  CurvedAnimation(
                      parent: animation, curve: Curves.easeOutBack),
                ),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            transitionDuration: const Duration(milliseconds: 450),
          );
        },
      ),
    ],
  );
}

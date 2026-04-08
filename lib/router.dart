import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:patpat_game/screens/game_screen.dart';
import 'package:patpat_game/screens/main_menu_screen.dart';
import 'package:patpat_game/screens/map_screen.dart';
import 'package:patpat_game/screens/shop_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/menu',
    routes: [
      GoRoute(
        path: '/menu',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const MainMenuScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: '/map',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const MapScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: '/shop',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const ShopScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 300),
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:patpat_game/screens/game_screen.dart';
// MainMenuScreen and MapScreen will be added in next tasks — for now use placeholder

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/menu',
    routes: [
      GoRoute(
        path: '/menu',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const _PlaceholderScreen(title: 'MENU'),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: '/map',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const _PlaceholderScreen(title: 'MAP'),
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

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 32, color: Colors.white),
        ),
      ),
    );
  }
}

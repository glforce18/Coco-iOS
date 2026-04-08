// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const ProviderScope(child: PatPatApp()));
}

class PatPatApp extends StatelessWidget {
  const PatPatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PatPat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0235),
      ),
      home: const Scaffold(
        body: Center(child: Text('PatPat - Loading...')),
      ),
    );
  }
}

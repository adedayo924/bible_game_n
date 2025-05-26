// lib/main.dart
import 'package:flutter/material.dart';
import 'package:new_game/screens/home_screen.dart';
import 'package:new_game/models/game.dart'; // Import Game class

void main() async { // main needs to be async
  WidgetsFlutterBinding.ensureInitialized(); // Required for async operations before runApp
  await Game.loadSettings(); // Load all settings (including timed mode)
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bible Knowledge Game',
      theme: ThemeData(
        useMaterial3: true, // Enable Material 3
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}
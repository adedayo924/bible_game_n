// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // Import your new HomeScreen

void main() {
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
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(), // Set HomeScreen as the initial screen
    );
  }
}
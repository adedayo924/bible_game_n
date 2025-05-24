// lib/home_screen.dart
import 'package:flutter/material.dart';
import 'screens/player_name_input_screen.dart'; // We'll make this a separate file for modularity
import 'high_score_screen.dart'; // Will create this next

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4B0082), // Deep Indigo
              Color(0xFF9370DB), // Medium Purple/Lavender
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Game Title
              const Text(
                'Bible Knowledge Game',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black54,
                      offset: Offset(3.0, 3.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),

              // Start New Game Button
              _buildMenuButton(
                context,
                text: 'Start New Game',
                onPressed: () {
                  // Navigate to the PlayerNameInputScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PlayerNameInputScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // High Scores Button
              _buildMenuButton(
                context,
                text: 'High Scores',
                onPressed: () {
                  // Navigate to the HighScoreScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HighScoreScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Settings Button (Placeholder)
              _buildMenuButton(
                context,
                text: 'Settings',
                onPressed: () {
                  // TODO: Implement Settings screen later
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings screen coming soon!')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, {required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: 250, // Fixed width for buttons
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.deepPurple,
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 5,
        ),
        child: Text(text),
      ),
    );
  }
}
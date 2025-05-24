// game_over_screen.dart
import 'package:flutter/material.dart';

class GameOverScreen extends StatelessWidget {
  final String playerName;
  final int levelReached;
  final int score;
  final int highScore; // <--- New parameter for high score

  const GameOverScreen({
    super.key,
    required this.playerName,
    required this.levelReached,
    required this.score,
    required this.highScore, // <--- Require high score in constructor
  });

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
            children: [
              const Text(
                "Game Over!",
                style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                "Player: $playerName",
                style: const TextStyle(fontSize: 24, color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Text(
                "Level Reached: $levelReached",
                style: const TextStyle(fontSize: 24, color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Text(
                "Your Score: $score",
                style: const TextStyle(fontSize: 28, color: Colors.yellowAccent, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text( // <--- Display High Score
                "High Score: $highScore",
                style: const TextStyle(fontSize: 28, color: Colors.amber, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // This assumes you have a way to go back to the start screen
                  // or trigger a new game directly from main.
                  // For now, let's go back to the initial route (likely splash screen)
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  backgroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Play Again"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
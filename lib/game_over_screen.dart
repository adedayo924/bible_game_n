// game_over_screen.dart
import 'package:flutter/material.dart';
import 'game_screen.dart';

class GameOverScreen extends StatelessWidget {
  final String playerName;
  final int levelReached;
  final int score;

  const GameOverScreen({
    super.key,
    required this.playerName,
    required this.levelReached,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Game Over"),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
      ),
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
              Text(
                "Game Over, $playerName!",
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                "Levels Completed: $levelReached",
                style: const TextStyle(fontSize: 20, color: Colors.white70),
              ),
              Text(
                "Final Score: $score",
                style: const TextStyle(fontSize: 20, color: Colors.white70),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GameScreen(playerName: playerName),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.purple,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
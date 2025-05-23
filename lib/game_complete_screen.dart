import 'package:flutter/material.dart';

class GameCompleteScreen extends StatelessWidget {
  final String playerName;
  final int score;
  final VoidCallback onPlayAgain; // Store the callback

  const GameCompleteScreen(
      {super.key,
        required this.playerName,
        required this.score,
        required this.onPlayAgain});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[300], // Example background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Congratulations!",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "You've completed all levels, $playerName!",
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              "Final Score: $score",
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onPlayAgain,
              child: const Text("Play Again"),
            ),
          ],
        ),
      ),
    );
  }
}
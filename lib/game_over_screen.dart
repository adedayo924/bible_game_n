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
      appBar: AppBar(title: const Text("Game Over")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("Game Over, $playerName!",
                style: const TextStyle(fontSize: 24)),
            Text("Levels Completed: $levelReached",
                style: const TextStyle(fontSize: 18)),
            Text("Final Score: $score", style: const TextStyle(fontSize: 18)),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(playerName: playerName),
                  ),
                );
              },
              child: const Text("Play Again"),
            ),
          ],
        ),
      ),
    );
  }
}

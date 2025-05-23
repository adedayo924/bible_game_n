import 'package:flutter/material.dart';
import 'game.dart';
import 'package:audioplayers/audioplayers.dart';
import 'game_complete_screen.dart';
import 'game_over_screen.dart';

class GameScreen extends StatefulWidget {
  final String playerName;

  const GameScreen({super.key, required this.playerName});

  @override
  GameState createState() => GameState();
}

class GameState extends State<GameScreen> {
  late Game game;
  bool isLoading = true;
  Map<int, int> audienceVotes = {}; // Initialize audienceVotes
  String friendHint = ""; // Initialize friendHint
  final AudioPlayer _audioPlayer =
      AudioPlayer(); // Create an AudioPlayer instance

  @override
  void initState() {
    super.initState();
    initializeGame();
  }

  Future<void> initializeGame() async {
    setState(() => isLoading = true);
    game = Game();
    await game.initializeGame(widget.playerName);
    setState(() => isLoading = false);
  }

  void _playSound(String soundFileName) async {
    await _audioPlayer.play(AssetSource('sounds/$soundFileName'));
  }

  void _handleAnswer(int answerIndex) async {
    bool isCorrect = await game.checkAnswer(answerIndex);
    if (isCorrect) {
      _playSound('correct_answer.mp3'); // Play correct answer sound
    } else {
      _playSound('incorrect_answer.mp3'); // Play incorrect answer sound
    }
    setState(() {
      if (game.gameOver) {
        if (game.allQuestionsCompletedSuccessfully) { // Check if all questions were answered correctly
          _playSound('game_complete.mp3');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GameCompleteScreen(
                playerName: game.playerName,
                score: game.score,
                // The onPlayAgain function is now passed and used directly within GameCompleteScreen
                // It's good practice to pass this callback
                onPlayAgain: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          GameScreen(playerName: game.playerName),
                    ),
                  );
                },
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GameOverScreen(
                playerName: game.playerName,
                levelReached: game.currentLevel - 1,
                score: game.score,
              ),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (game.currentQuestion == null && !game.gameOver) {
      return const Scaffold(
        body: Center(child: Text("No Questions Available. Check 'assets/questions.json'")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Level ${game.currentLevel}"), backgroundColor: Colors.deepPurpleAccent),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(game.currentQuestion!.question,
                style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ...game.currentQuestion!.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: option.isEmpty ? null : () => _handleAnswer(index),
                  child: Text(option),
                ),
              );
            }),
            Wrap(
              spacing: 8.0, // Horizontal spacing between buttons
              runSpacing: 8.0, // Vertical spacing between lines
              alignment: WrapAlignment.center, // Center the buttons
              children: [
                ElevatedButton(
                  onPressed: game.fiftyFiftyUsed
                      ? null
                      : () {
                          game.use5050();
                          _playSound('50_50.mp3'); // Play 50/50 sound
                          setState(() {});
                        },
                  child: const Text("50/50"),
                ),
                ElevatedButton(
                  onPressed: game.askAudienceUsed
                      ? null
                      : () {
                          audienceVotes = game.askTheAudience();
                          _playSound(
                              'ask_audience.mp3'); // Play ask the audience sound
                          setState(() {});
                        },
                  child: const Text("Ask Audience"),
                ),
                ElevatedButton(
                  onPressed: game.phoneAFriendUsed
                      ? null
                      : () {
                          friendHint = game.phoneAFriend();
                          _playSound(
                              'phone_a_friend.mp3'); // Play phone a friend sound
                          setState(() {});
                        },
                  child: const Text("Phone Friend"),
                ),
              ],
            ),
            if (audienceVotes.isNotEmpty) // Display votes if available
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  children: audienceVotes.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text("Option ${entry.key + 1}: ${entry.value}%"),
                    );
                  }).toList(),
                ),
              ),
            if (friendHint.isNotEmpty) // Display hint if available
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text("Friend's Hint: $friendHint"),
              ),
          ],
        ),
      ),
    );
  }
}

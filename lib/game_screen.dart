// game_screen.dart
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
  Map<int, int> audienceVotes = {};
  String friendHint = "";
  final AudioPlayer _audioPlayer = AudioPlayer();

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
      _playSound('correct_answer.mp3');
    } else {
      _playSound('incorrect_answer.mp3');
    }

    setState(() {
      if (game.gameOver) {
        if (game.allQuestionsCompletedSuccessfully) {
          _playSound('game_complete.mp3');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GameCompleteScreen(
                playerName: game.playerName,
                score: game.score,
                onPlayAgain: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GameScreen(playerName: game.playerName),
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
        body: Center(child: Text("No Questions Available. Check 'assets/bible_questions.json'")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Level ${game.currentLevel}"),
        backgroundColor: Colors.deepPurpleAccent, // Still keep app bar distinct
        elevation: 0, // Remove shadow for seamless gradient
      ),
      // Apply gradient to the entire body
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ... (rest of your existing UI elements)
              Text(game.currentQuestion!.question,
                  textAlign: TextAlign.center, // Center the question
                  style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)), // Added styling
              const SizedBox(height: 20),
              ...game.currentQuestion!.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  // We'll apply custom button styling here in the next step
                  child: ElevatedButton(
                    onPressed: option.isEmpty ? null : () => _handleAnswer(index),
                    style: ElevatedButton.styleFrom( // Start adding styles
                      foregroundColor: Colors.black, // Text color
                      backgroundColor: Colors.white, // Button background
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Slightly rounded corners
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    child: Text(option),
                  ),
                );
              }),
              const Spacer(), // Pushes lifelines to the bottom
              Wrap(
                spacing: 10.0, // Horizontal spacing between buttons
                runSpacing: 10.0, // Vertical spacing between lines
                alignment: WrapAlignment.center, // Center the buttons
                children: [
                  ElevatedButton(
                    onPressed: game.fiftyFiftyUsed
                        ? null
                        : () {
                      game.use5050();
                      _playSound('50_50.mp3');
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.purple, // Different color for lifelines
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text("50/50"),
                  ),
                  ElevatedButton(
                    onPressed: game.askAudienceUsed
                        ? null
                        : () {
                      audienceVotes = game.askTheAudience();
                      _playSound('ask_audience.mp3');
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text("Ask Audience"),
                  ),
                  ElevatedButton(
                    onPressed: game.phoneAFriendUsed
                        ? null
                        : () {
                      friendHint = game.phoneAFriend();
                      _playSound('phone_a_friend.mp3');
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text("Phone Friend"),
                  ),
                ],
              ),
              if (audienceVotes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    children: audienceVotes.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text("Option ${entry.key + 1}: ${entry.value}%", style: const TextStyle(color: Colors.white70)),
                      );
                    }).toList(),
                  ),
                ),
              if (friendHint.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text("Friend's Hint: $friendHint", style: const TextStyle(color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
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

  // New state variables for answer feedback
  int? _selectedAnswerIndex;
  bool _answerSubmitted = false;

  @override
  void initState() {
    super.initState();
    initializeGame();
  }

  Future<void> initializeGame() async {
    setState(() => isLoading = true);
    game = Game();
    await game.initializeGame(widget.playerName);
    // Reset feedback state for new question/game
    _selectedAnswerIndex = null;
    _answerSubmitted = false;
    setState(() => isLoading = false);
  }

  void _playSound(String soundFileName) async {
    // Ensure you have sound files in assets/sounds/ and pubspec.yaml configured
    await _audioPlayer.play(AssetSource('sounds/$soundFileName'));
  }

  // Helper function to determine button color based on state
  Color _getButtonColor(int optionIndex) {
    if (!_answerSubmitted) {
      return Colors.white; // Default color before answer is submitted
    }

    // After answer is submitted
    if (optionIndex == game.currentQuestion!.correctAnswer) {
      return Colors.green; // Correct answer
    } else if (optionIndex == _selectedAnswerIndex) {
      return Colors.red; // User's incorrect answer
    }
    return Colors.white; // Other incorrect answers remain default
  }

  // Helper function to determine text color for options
  Color _getButtonTextColor(int optionIndex) {
    if (!_answerSubmitted) {
      return Colors.black; // Default text color
    }
    // After answer is submitted, if it's the selected or correct answer, make text white for contrast
    if (optionIndex == game.currentQuestion!.correctAnswer || optionIndex == _selectedAnswerIndex) {
      return Colors.white;
    }
    return Colors.black; // Other answers remain black
  }


  void _handleAnswer(int answerIndex) async {
    if (_answerSubmitted) return; // Prevent multiple taps

    setState(() {
      _selectedAnswerIndex = answerIndex;
      _answerSubmitted = true; // Mark that an answer has been submitted
    });

    bool isCorrect = await game.checkAnswer(answerIndex);

    if (isCorrect) {
      _playSound('correct_answer.mp3');
      // If correct, no delay, just move to the next question
      // or game complete if all questions are done
      setState(() {
        if (game.gameOver) { // This means all questions were correctly exhausted
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
          // Reset feedback state for the next question
          _selectedAnswerIndex = null;
          _answerSubmitted = false;
        }
      });
    } else {
      _playSound('incorrect_answer.mp3');

      // If incorrect, show feedback colors, then delay, then navigate to Game Over
      await Future.delayed(const Duration(seconds: 5)); // <-- 5-second delay here

      if (!mounted) return; // Check if the widget is still in the tree

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
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
        foregroundColor: Colors.white, // Ensure app bar text is visible
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(game.currentQuestion!.question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              // Dynamically styled answer buttons
              ...game.currentQuestion!.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: (_answerSubmitted || option.isEmpty) ? null : () => _handleAnswer(index), // Disable if already submitted or empty
                    style: ElevatedButton.styleFrom(
                      foregroundColor: _getButtonTextColor(index), // Text color based on state
                      backgroundColor: _getButtonColor(index), // Button background based on state
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      disabledForegroundColor: Colors.grey, // Text color for disabled buttons
                      disabledBackgroundColor: Colors.grey[200], // Background for disabled (empty) options
                    ),
                    child: Text(option),
                  ),
                );
              }),
              const Spacer(),
              Wrap(
                spacing: 10.0,
                runSpacing: 10.0,
                alignment: WrapAlignment.center,
                children: [
                  // Lifeline buttons - also disabled if answer submitted
                  ElevatedButton(
                    onPressed: (game.fiftyFiftyUsed || _answerSubmitted)
                        ? null
                        : () {
                      game.use5050();
                      _playSound('50_50.mp3');
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      disabledForegroundColor: Colors.white54, // Dim text when disabled
                      disabledBackgroundColor: Colors.purple[200], // Dim background when disabled
                    ),
                    child: const Text("50/50"),
                  ),
                  ElevatedButton(
                    onPressed: (game.askAudienceUsed || _answerSubmitted)
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
                      disabledForegroundColor: Colors.white54,
                      disabledBackgroundColor: Colors.purple[200],
                    ),
                    child: const Text("Ask Audience"),
                  ),
                  ElevatedButton(
                    onPressed: (game.phoneAFriendUsed || _answerSubmitted)
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
                      disabledForegroundColor: Colors.white54,
                      disabledBackgroundColor: Colors.purple[200],
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
                      // Ensure 'option' is not empty before displaying
                      String optionText = game.currentQuestion!.options[entry.key];
                      if (optionText.isEmpty) {
                        return const SizedBox.shrink(); // Hide if option was removed by 50/50
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text("$optionText: ${entry.value}%", style: const TextStyle(color: Colors.white70)),
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
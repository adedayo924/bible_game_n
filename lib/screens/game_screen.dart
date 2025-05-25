// game_screen.dart
import 'package:flutter/material.dart';
import '../models/game.dart';
import 'package:audioplayers/audioplayers.dart';
import 'game_over_screen.dart';
import 'game_complete_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameScreen extends StatefulWidget {
  final String playerName;

  const GameScreen({super.key, required this.playerName});

  @override
  GameState createState() => GameState();
}

class GameState extends State<GameScreen> with TickerProviderStateMixin {
  late Game game;
  bool isLoading = true;
  Map<int, int> audienceVotes = {};
  String friendHint = "";
  // Removed final AudioPlayer _audioPlayer = AudioPlayer();
  // As it was declared but not used for playing, and we'll create new players for each sound.

  int? _selectedAnswerIndex;
  bool _answerSubmitted = false;

  bool _showCorrectAnimation = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  late AnimationController _correctAnswerAnimationController;
  late Animation<double> _checkmarkAnimation;
  bool _isSoundMuted = false;


  @override
  void initState() {
    super.initState();
    _loadSoundSetting();
    initializeGame();

    _correctAnswerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _checkmarkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _correctAnswerAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );

    _animationController.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        if (!mounted) return;

        final int capturedAnswerIndex = _selectedAnswerIndex!;

        await game.checkAnswer(capturedAnswerIndex);

        if (!mounted) return;

        setState(() {
          _showCorrectAnimation = false;
          _selectedAnswerIndex = null;
          _answerSubmitted = false;
        });

        // Check for game over (all questions completed successfully)
        if (game.gameOver) {
          _playSound('game_complete.mp3');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GameCompleteScreen( // <--- CORRECTED TO GameCompleteScreen
                playerName: game.playerName, // GameCompleteScreen needs playerName
                score: game.score,           // GameCompleteScreen needs score
                onPlayAgain: () {            // GameCompleteScreen needs onPlayAgain callback
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
        }
      }
    });
  }

  Future<void> _loadSoundSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSoundMuted = prefs.getBool(Game.soundMutedKey) ?? false;
    });
  }

  Future<void> initializeGame() async {
    setState(() => isLoading = true);
    game = Game();
    await game.initializeGame(widget.playerName);
    _selectedAnswerIndex = null;
    _answerSubmitted = false;
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    // _audioPlayer.dispose(); // Removed as _audioPlayer member is no longer used
    _animationController.dispose();
    _correctAnswerAnimationController.dispose();
    super.dispose();
  }

  // --- START FIX 1: Dispose player after sound completion ---
  void _playSound(String soundFileName) {
    if (_isSoundMuted) {
      return;
    }
    final player = AudioPlayer(); // Create a new instance for each sound
    player.play(AssetSource('sounds/$soundFileName'));

    // Listen for completion and dispose the player
    player.onPlayerComplete.listen((event) {
      player.dispose();
    });
  }
  // --- END FIX 1 ---

  Color _getButtonColor(int optionIndex) {
    if (!_answerSubmitted) {
      return Colors.white;
    }
    if (optionIndex == game.currentQuestion!.correctAnswer) {
      return Colors.green;
    } else if (optionIndex == _selectedAnswerIndex) {
      return Colors.red;
    }
    return Colors.white;
  }

  Color _getButtonTextColor(int optionIndex) {
    if (!_answerSubmitted) {
      return Colors.black;
    }
    if (optionIndex == game.currentQuestion!.correctAnswer || optionIndex == _selectedAnswerIndex) {
      return Colors.white;
    }
    return Colors.black;
  }

  void _handleAnswer(int answerIndex) async {
    if (_answerSubmitted) return;

    setState(() {
      _selectedAnswerIndex = answerIndex;
      _answerSubmitted = true;
    });

    bool isCorrect = (game.currentQuestion!.correctAnswer == answerIndex);

    if (isCorrect) {
      _playSound('correct_answer.mp3');
      setState(() {
        _showCorrectAnimation = true;
      });
      _animationController.forward(from: 0.0);
    } else {
      _playSound('incorrect_answer.mp3');

      await Future.delayed(const Duration(seconds: 5));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameOverScreen(
            playerName: game.playerName,
            levelReached: game.currentLevel - 1,
            score: game.score,
            highScore: game.highScore,
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
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4B0082),
              Color(0xFF9370DB),
            ],
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(game.currentQuestion!.question,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ...game.currentQuestion!.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;

                    final Color buttonBackgroundColor = _getButtonColor(index);
                    final Color buttonTextColor = _getButtonTextColor(index);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton(
                        onPressed: (_answerSubmitted || option.isEmpty) ? null : () => _handleAnswer(index),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                              if (states.contains(MaterialState.disabled)) {
                                if (_answerSubmitted && index == game.currentQuestion!.correctAnswer) {
                                  return Colors.green;
                                }
                                return Colors.grey[200]!;
                              }
                              return buttonBackgroundColor;
                            },
                          ),
                          foregroundColor: MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                              if (states.contains(MaterialState.disabled)) {
                                if (_answerSubmitted && index == game.currentQuestion!.correctAnswer) {
                                  return Colors.white;
                                }
                                return Colors.black;
                              }
                              return buttonTextColor;
                            },
                          ),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                            const EdgeInsets.symmetric(vertical: 15),
                          ),
                          textStyle: MaterialStateProperty.all<TextStyle>(
                            const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ),
                        child: Text(option),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: (game.fiftyFiftyUsed || _answerSubmitted)
                            ? null
                            : () {
                          game.use5050();
                          _playSound('50_50.mp3');
                          setState(() {});
                          // No need to clear 50/50, as it modifies options permanently
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.purple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          disabledForegroundColor: Colors.white54,
                          disabledBackgroundColor: Colors.purple[200],
                        ),
                        child: const Text("50/50"),
                      ),
                      ElevatedButton(
                        onPressed: (game.askAudienceUsed || _answerSubmitted)
                            ? null
                            : () {
                          audienceVotes = game.askTheAudience();
                          _playSound('ask_audience.mp3');
                          setState(() {}); // Update UI to show votes

                          // --- START FIX 2: Clear audience votes after a delay ---
                          Future.delayed(const Duration(seconds: 7), () { // Adjust duration as needed
                            if (mounted) { // Check if the widget is still active
                              setState(() {
                                audienceVotes = {}; // Clear votes
                              });
                            }
                          });
                          // --- END FIX 2 ---
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
                          setState(() {}); // Update UI to show hint

                          // --- START FIX 2: Clear friend hint after a delay ---
                          Future.delayed(const Duration(seconds: 7), () { // Adjust duration as needed
                            if (mounted) { // Check if the widget is still active
                              setState(() {
                                friendHint = ""; // Clear hint
                              });
                            }
                          });
                          // --- END FIX 2 ---
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
                          String optionText = game.currentQuestion!.options[entry.key];
                          if (optionText.isEmpty) {
                            return const SizedBox.shrink();
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
            if (_showCorrectAnimation)
              Positioned.fill(
                child: Center(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: FadeTransition(
                      opacity: _opacityAnimation,
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.greenAccent,
                        size: 150.0,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
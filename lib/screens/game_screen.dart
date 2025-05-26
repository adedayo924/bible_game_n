// lib/screens/game_screen.dart
import 'package:flutter/material.dart';
import '../models/game.dart';
import 'package:audioplayers/audioplayers.dart';
import 'game_complete_screen.dart';
import 'game_over_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Import for Timer

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
  bool _showHint = false;
  String? _currentHintText;

  int? _selectedAnswerIndex;
  bool _answerSubmitted = false;

  bool _showCorrectAnimation = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  late AnimationController _correctAnswerAnimationController;
  late Animation<double> _checkmarkAnimation;
  bool _isSoundMuted = false;

  Timer? _timer;
  int _timeRemaining = 50;
  final int _maxTime = 50;

  @override
  void initState() {
    super.initState();
    _loadSoundSetting();
    initializeGameSession().then((_) {
      if (mounted && Game.isTimedModeEnabled) {
        _startTimer();
      }
    });

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

        bool isCorrect = await game.checkAnswer(capturedAnswerIndex);

        if (!mounted) return;

        // Hint display logic
        if (isCorrect && game.currentQuestion?.hint != null) {
          setState(() {
            _currentHintText = game.currentQuestion!.hint;
            _showHint = true;
            _showCorrectAnimation = false;
            _selectedAnswerIndex = null; // Ensure no highlighting under hint
            _answerSubmitted = false;    // Ensure no highlighting under hint
          });
          _playSound('hint_reveal.mp3');
          await Future.delayed(const Duration(seconds: 4));
          if (!mounted) return;
          setState(() {
            _showHint = false;
            _currentHintText = null;
          });
        }

        if (!mounted) return;

        // This block now only runs if there was no hint, or after the hint has disappeared
        setState(() {
          _showCorrectAnimation = false;
          // Ensure state is reset if no hint was shown, or as a final cleanup
          if (_selectedAnswerIndex != null || _answerSubmitted) {
            _selectedAnswerIndex = null;
            _answerSubmitted = false;
          }
        });


        if (game.gameOver) {
          await game.saveActivePlayerHighScore();
          if (!mounted) return;

          if (game.currentQuestion == null) {
            _playSound('game_complete.mp3');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => GameCompleteScreen(
                  playerName: game.activePlayerProfile!.name,
                  score: game.score,
                  onPlayAgain: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GameScreen(playerName: game.activePlayerProfile!.name),
                      ),
                    );
                  },
                ),
              ),
            );
          } else {
            _playSound('incorrect_answer.mp3');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => GameOverScreen(
                  playerName: game.activePlayerProfile!.name,
                  levelReached: game.currentLevel,
                  score: game.score,
                  highScore: game.activePlayerProfile!.highScore,
                ),
              ),
            );
          }
        } else {
          if (Game.isTimedModeEnabled) {
            _startTimer();
          }
        }
      }
    });
  }

  Future<void> _loadSoundSetting() async {
    setState(() {
      _isSoundMuted = Game.isSoundMuted;
    });
  }

  Future<void> initializeGameSession() async {
    setState(() => isLoading = true);
    List<PlayerProfile> allProfiles = await Game.loadAllPlayerProfiles();
    PlayerProfile? selectedProfile;
    if (allProfiles.isNotEmpty) {
      selectedProfile = allProfiles.firstWhere((p) => p.name == widget.playerName);
    }

    if (selectedProfile != null) {
      game = Game();
      await game.initializeGame(selectedProfile);
      _selectedAnswerIndex = null;
      _answerSubmitted = false;
    } else {
      print("Error: Player profile not found for ${widget.playerName}. Creating new dummy profile.");
      game = Game();
      await game.initializeGame(PlayerProfile(name: widget.playerName, highScore: 0));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading profile. A new one was created.')),
        );
      }
    }
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _correctAnswerAnimationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _playSound(String soundFileName) {
    if (_isSoundMuted) {
      return;
    }
    final player = AudioPlayer();
    player.play(AssetSource('sounds/$soundFileName'));
    player.onPlayerComplete.listen((event) {
      player.dispose();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timeRemaining = _maxTime;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          timer.cancel();
          _handleTimeout();
        }
      });
    });
  }

  void _handleTimeout() {
    if (!mounted) return;
    _timer?.cancel();
    _handleAnswer(-1);
  }

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
    if (_answerSubmitted && answerIndex != -1) return;

    _timer?.cancel();

    setState(() {
      _selectedAnswerIndex = answerIndex;
      _answerSubmitted = true;
    });

    bool isCorrect = false;
    if (answerIndex == -1) {
      isCorrect = false;
      _playSound('incorrect_answer.mp3');
      await game.saveActivePlayerHighScore();
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameOverScreen(
            playerName: game.activePlayerProfile!.name,
            levelReached: game.currentLevel,
            score: game.score,
            highScore: game.activePlayerProfile!.highScore,
          ),
        ),
      );
    } else {
      isCorrect = (game.currentQuestion!.correctAnswer == answerIndex);

      if (!isCorrect) {
        _playSound('incorrect_answer.mp3');
        await game.saveActivePlayerHighScore();
        await Future.delayed(const Duration(seconds: 3));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameOverScreen(
              playerName: game.activePlayerProfile!.name,
              levelReached: game.currentLevel,
              score: game.score,
              highScore: game.activePlayerProfile!.highScore,
            ),
          ),
        );
      } else {
        _playSound('correct_answer.mp3');
        // NEW: Add a delay here to let the correct answer sound play before animation/hint
        await Future.delayed(const Duration(seconds: 2)); // Adjust duration as needed (e.g., 1-2 seconds)

        setState(() {
          _showCorrectAnimation = true;
        });
        _animationController.forward(from: 0.5);
      }
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
      extendBodyBehindAppBar: true, // NEW: Extend body behind app bar
      extendBody: true,             // NEW: Extend body behind bottom system nav bar
      appBar: AppBar(
        title: Text("Level ${game.currentLevel} | Score: ${game.score}"),
        backgroundColor: Colors.deepPurpleAccent.withOpacity(0.7), // Adjusted opacity for background to show
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        // This Container now ensures the gradient covers the entire screen, including safe areas
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
            // Ensure padding for SingleChildScrollView respects safe areas and Appbar height
            SafeArea( // Add SafeArea for the main content
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (Game.isTimedModeEnabled)
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: _timeRemaining / _maxTime,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _timeRemaining > _maxTime / 3 ? Colors.greenAccent : Colors.redAccent,
                              ),
                              minHeight: 15,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Time Left: $_timeRemaining seconds',
                            style: const TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          const SizedBox(height: 15),
                        ],
                      ),
                    Text(game.currentQuestion!.question,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    // Answer Options
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
                    // Lifeline buttons
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
                              : () async {
                            final Map<int, int> newAudienceVotes = game.askTheAudience();

                            _playSound('audience_murmur.mp3');

                            await Future.delayed(const Duration(seconds: 3));

                            if (!mounted) return;

                            _playSound('audience_reveal.mp3');

                            setState(() {
                              audienceVotes = newAudienceVotes;
                            });

                            await Future.delayed(const Duration(seconds: 7));
                            if (mounted) {
                              setState(() {
                                audienceVotes = {};
                              });
                            }
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
                              : () async {
                            final String newFriendHint = game.phoneAFriend();

                            _playSound('phone_ring.mp3');

                            await Future.delayed(const Duration(seconds: 3));

                            if (!mounted) return;

                            _playSound('phone_friend_speaks.mp3');

                            setState(() {
                              friendHint = newFriendHint;
                            });

                            await Future.delayed(const Duration(seconds: 7));
                            if (mounted) {
                              setState(() {
                                friendHint = "";
                              });
                            }
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
                    // Audience votes and friend hint display
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
            ),
            // Correct answer animation overlay
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
            // Hint text overlay
            if (_showHint && _currentHintText != null)
              Positioned.fill(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Card(
                      color: Colors.purple[100]?.withOpacity(0.95),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Did You Know?',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 15),
                            Text(
                              _currentHintText!,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.deepPurple[800],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
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
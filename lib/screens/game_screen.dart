// lib/screens/game_screen.dart
import 'package:flutter/material.dart';
import '../models/game.dart';
import 'package:audioplayers/audioplayers.dart';
import 'game_complete_screen.dart';
import 'game_over_screen.dart';
import 'dart:async'; // Import for Timer
import 'dart:math'; // Import for min function

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

  int? _selectedAnswerIndex; // This is the DISPLAYED index
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
    game = Game();
    game.addListener(_onGameModelChange); // Listen for changes in game state
    _loadSoundSetting(); // Load settings early
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
        setState(() {
          _showCorrectAnimation = false;
        });
      }
    });
  }

  // Listener for changes in the Game model
  void _onGameModelChange() {
    setState(() {
      // Clear lifeline UI display whenever game state changes (e.g., new question)
      // This is crucial because lifelines are question-specific.
      audienceVotes = {};
      friendHint = "";
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

    selectedProfile = allProfiles.firstWhere(
          (p) => p.name == widget.playerName,
      orElse: () => PlayerProfile(name: widget.playerName, highScore: 0),
    );

    await game.initializeGame(selectedProfile);

    // Ensure state is clean when a new game session starts for UI-specific variables
    _selectedAnswerIndex = null;
    _answerSubmitted = false;
    audienceVotes = {};
    friendHint = "";
    _showHint = false;
    _currentHintText = null;

    // After initialization, if there's a question, start its hint display process.
    if (game.currentQuestion?.hint != null) {
      _currentHintText = game.currentQuestion!.hint;
      _showHint = true;
      _playSound('hint_reveal.mp3');
      Future.delayed(const Duration(seconds: 4)).then((_) {
        if (mounted) {
          setState(() {
            _showHint = false;
            _currentHintText = null;
          });
        }
      });
    }

    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _correctAnswerAnimationController.dispose();
    _timer?.cancel();
    game.removeListener(_onGameModelChange); // IMPORTANT: Remove listener
    super.dispose();
  }

  void _playSound(String soundFileName) {
    if (Game.isSoundMuted) {
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
    _handleAnswer(-1); // Use -1 to indicate a timeout
  }

  Color _getButtonColor(int optionIndex) {
    if (!_answerSubmitted) {
      return Colors.white;
    }

    // This method now correctly retrieves the displayed index of the correct option
    int currentCorrectAnswerDisplayIndex = game.currentQuestion!.getCorrectOptionDisplayIndex();

    if (optionIndex == currentCorrectAnswerDisplayIndex) {
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
    int currentCorrectAnswerDisplayIndex = game.currentQuestion!.getCorrectOptionDisplayIndex();

    if (optionIndex == currentCorrectAnswerDisplayIndex || optionIndex == _selectedAnswerIndex) {
      return Colors.white;
    }
    return Colors.black;
  }

  void _handleAnswer(int answerIndex) async {
    if (_answerSubmitted && answerIndex != -1) return;

    _timer?.cancel(); // Stop the timer immediately

    setState(() {
      _selectedAnswerIndex = answerIndex;
      _answerSubmitted = true;
    });

    bool isCorrect;
    if (answerIndex == -1) { // Timeout case
      isCorrect = false;
    } else {
      isCorrect = game.checkAnswer(answerIndex); // This is now synchronous (returns bool)
    }

    if (!mounted) return;

    if (!isCorrect) {
      _playSound('incorrect_answer.mp3');
      await game.saveActivePlayerHighScore();

      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      setState(() {
        _selectedAnswerIndex = null;
        _answerSubmitted = false;
      });

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
    } else { // Answer is correct
      _playSound('correct_answer.mp3');

      setState(() {
        _showCorrectAnimation = true;
      });
      final TickerFuture animationFuture = _animationController.forward(from: 0.25);
      await animationFuture;

      if (!mounted) return;

      setState(() {
        _selectedAnswerIndex = null;
        _answerSubmitted = false;
        _showCorrectAnimation = false;
      });

      // Introduce delay BEFORE advancing to the next question
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // Now, advance to the next question in the Game model
      game.advanceToNextQuestion();

      if (game.gameOver) {
        await game.saveActivePlayerHighScore();
        if (!mounted) return;
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
      } else { // Game is not over, new question is loaded.
        // Show hint for the NEW question if it exists.
        if (game.currentQuestion?.hint != null) {
          setState(() {
            _currentHintText = game.currentQuestion!.hint;
            _showHint = true;
          });
          _playSound('hint_reveal.mp3');
          await Future.delayed(const Duration(seconds: 4));
          if (!mounted) return;
          setState(() {
            _showHint = false;
            _currentHintText = null;
          });
        }
        if (Game.isTimedModeEnabled) {
          _startTimer();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const double maxContentPadding = 24.0;
    const double maxTimerFontSize = 20.0;
    const double maxTimerHeight = 20.0;
    const double maxQuestionFontSize = 28.0;
    const double maxOptionVerticalPadding = 20.0;
    const double maxOptionFontSize = 20.0;
    const double maxLifelineButtonPaddingHorizontal = 25.0;
    const double maxLifelineButtonPaddingVertical = 12.0;
    const double maxLifelineButtonFontSize = 16.0;
    const double maxHintCardPadding = 24.0;
    const double maxHintTitleFontSize = 28.0;
    const double maxHintTextFontSize = 20.0;
    const double maxIconSize = 200.0;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (game.gameOver && game.currentQuestion == null) {
      return const Scaffold(
        body: Center(child: Text("Game Over or No Questions Available.")),
      );
    }
    if (game.currentQuestion == null) {
      return const Scaffold(
        body: Center(child: Text("Loading questions...")),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: Text("Level ${game.currentLevel} | Score: ${game.score}"),
        backgroundColor: Colors.deepPurpleAccent.withOpacity(0.7),
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
            Positioned.fill(
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(min(screenWidth * 0.04, maxContentPadding)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Timer
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
                                minHeight: min(screenHeight * 0.02, maxTimerHeight),
                              ),
                            ),
                            SizedBox(height: min(screenHeight * 0.01, 5)),
                            Text(
                              'Time Left: $_timeRemaining seconds',
                              style: TextStyle(fontSize: min(screenWidth * 0.05, maxTimerFontSize), color: Colors.white),
                            ),
                            SizedBox(height: min(screenHeight * 0.02, 15)),
                          ],
                        ),
                      // Question text
                      Text(game.currentQuestion!.question,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: min(screenWidth * 0.07, maxQuestionFontSize), color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(height: min(screenHeight * 0.03, 20)),
                      // Answer Options
                      ...game.currentQuestion!.options.asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;

                        final Color buttonBackgroundColor = _getButtonColor(index);
                        final Color buttonTextColor = _getButtonTextColor(index);

                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: min(screenHeight * 0.015, 8.0)),
                          child: ElevatedButton(
                            onPressed: (_answerSubmitted || option.isEmpty) ? null : () => _handleAnswer(index),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                    (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.disabled)) {
                                    int currentCorrectAnswerDisplayIndex = game.currentQuestion!.getCorrectOptionDisplayIndex();
                                    if (_answerSubmitted && index == currentCorrectAnswerDisplayIndex) {
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
                                    int currentCorrectAnswerDisplayIndex = game.currentQuestion!.getCorrectOptionDisplayIndex();
                                    if (_answerSubmitted && index == currentCorrectAnswerDisplayIndex) {
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
                                EdgeInsets.symmetric(vertical: min(screenHeight * 0.025, maxOptionVerticalPadding)),
                              ),
                              textStyle: MaterialStateProperty.all<TextStyle>(
                                TextStyle(fontSize: min(screenWidth * 0.05, maxOptionFontSize), fontWeight: FontWeight.w600),
                              ),
                            ),
                            child: Text(option),
                          ),
                        );
                      }),
                      SizedBox(height: min(screenHeight * 0.03, 20)),
                      // Lifeline buttons
                      Wrap(
                        spacing: min(screenWidth * 0.03, 10.0),
                        runSpacing: min(screenHeight * 0.015, 10.0),
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: (game.fiftyFiftyUsed || _answerSubmitted)
                                ? null
                                : () {
                              game.use5050();
                              _playSound('50_50.mp3');
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.purple,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: EdgeInsets.symmetric(
                                horizontal: min(screenWidth * 0.06, maxLifelineButtonPaddingHorizontal),
                                vertical: min(screenHeight * 0.015, maxLifelineButtonPaddingVertical),
                              ),
                              textStyle: TextStyle(fontSize: min(screenWidth * 0.04, maxLifelineButtonFontSize)),
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
                              padding: EdgeInsets.symmetric(
                                horizontal: min(screenWidth * 0.06, maxLifelineButtonPaddingHorizontal),
                                vertical: min(screenHeight * 0.015, maxLifelineButtonPaddingVertical),
                              ),
                              textStyle: TextStyle(fontSize: min(screenWidth * 0.04, maxLifelineButtonFontSize)),
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
                              padding: EdgeInsets.symmetric(
                                horizontal: min(screenWidth * 0.06, maxLifelineButtonPaddingHorizontal),
                                vertical: min(screenHeight * 0.015, maxLifelineButtonPaddingVertical),
                              ),
                              textStyle: TextStyle(fontSize: min(screenWidth * 0.04, maxLifelineButtonFontSize)),
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
                          padding: EdgeInsets.only(top: min(screenHeight * 0.025, 16.0)),
                          child: Column(
                            children: audienceVotes.entries.map((entry) {
                              String optionText = game.currentQuestion!.options[entry.key];
                              if (optionText.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: min(screenHeight * 0.01, 4.0)),
                                child: Text("$optionText: ${entry.value}%", style: TextStyle(color: Colors.white70, fontSize: min(screenWidth * 0.045, 16.0))),
                              );
                            }).toList(),
                          ),
                        ),
                      if (friendHint.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: min(screenHeight * 0.025, 16.0)),
                          child: Text("Friend's Hint: $friendHint", style: TextStyle(color: Colors.white, fontSize: min(screenWidth * 0.045, 16.0))),
                        ),
                      SizedBox(height: min(screenHeight * 0.03, 20)),
                    ],
                  ),
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
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.greenAccent,
                        size: min(screenWidth * 0.4, maxIconSize),
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
                    padding: EdgeInsets.all(min(screenWidth * 0.06, maxHintCardPadding)),
                    child: Card(
                      color: Colors.purple[100]?.withOpacity(0.95),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 8,
                      child: Padding(
                        padding: EdgeInsets.all(min(screenWidth * 0.05, 20.0)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Did You Know?',
                              style: TextStyle(
                                fontSize: min(screenWidth * 0.07, maxHintTitleFontSize),
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: min(screenHeight * 0.025, 15)),
                            Text(
                              _currentHintText!,
                              style: TextStyle(
                                fontSize: min(screenWidth * 0.05, maxHintTextFontSize),
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
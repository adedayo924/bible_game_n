// lib/models/game.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

// PlayerProfile class
class PlayerProfile {
  String name;
  int highScore;

  PlayerProfile({required this.name, this.highScore = 0});

  // Convert PlayerProfile to JSON
  Map<String, dynamic> toJson() => {
    'name': name,
    'highScore': highScore,
  };

  // Create PlayerProfile from JSON
  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      name: json['name'],
      highScore: json['highScore'] ?? 0,
    );
  }
}

// Game class - Now extends ChangeNotifier
class Game extends ChangeNotifier {
  List<Question> _allQuestions = [];
  List<Question> _currentDifficultyQuestions = [];
  Question? _currentQuestion;
  int currentLevel = 1;
  int score = 0;
  bool gameOver = false;

  bool fiftyFiftyUsed = false;
  bool askAudienceUsed = false;
  bool phoneAFriendUsed = false;

  // Static keys for SharedPreferences
  static const String _allPlayerProfilesKey = 'allPlayerProfiles';
  static const String lastPlayerNameKey = 'lastPlayerName';
  static const String soundMutedKey = 'isSoundMuted';
  static const String _timedModeEnabledKey = 'isTimedModeEnabled';

  // Static variables for settings
  static bool isSoundMuted = false;
  static bool isTimedModeEnabled = false;

  PlayerProfile? activePlayerProfile;

  // Public getter for currentQuestion
  Question? get currentQuestion => _currentQuestion;

  Game({this.activePlayerProfile});

  Future<void> initializeGame(PlayerProfile playerProfile) async {
    activePlayerProfile = playerProfile;
    await _loadQuestions();
    _resetGame();
    // After reset, make sure the first question is loaded if not game over
    if (!gameOver && _currentQuestion == null) {
      _nextQuestionInternal();
    }
    notifyListeners(); // Notify after initial game setup
  }

  // --- Static Methods for Global Settings and Player Names ---

  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isSoundMuted = prefs.getBool(soundMutedKey) ?? false;
    isTimedModeEnabled = prefs.getBool(_timedModeEnabledKey) ?? false;
  }

  static Future<void> saveSoundSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(soundMutedKey, value);
    isSoundMuted = value;
    // No notifyListeners here for static properties, settings screen handles its own state
  }

  static Future<void> saveTimedModeSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_timedModeEnabledKey, value);
    isTimedModeEnabled = value;
    // No notifyListeners here for static properties, settings screen handles its own state
  }

  static Future<String?> loadLastPlayerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(lastPlayerNameKey);
  }

  static Future<void> saveLastPlayerName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastPlayerNameKey, name);
  }

  // --- Question and Game Logic ---

  Future<void> _loadQuestions() async {
    try {
      final String response = await rootBundle.loadString('assets/bible_questions.json');
      final List<dynamic> data = json.decode(response);
      _allQuestions = data.map((json) => Question.fromJson(json)).toList();
    } catch (e) {
      // Consider logging this error using a proper logging package if desired
      _allQuestions = []; // Ensure it's empty on error
    }
  }

  void _resetGame() {
    score = 0;
    currentLevel = 1;
    gameOver = false;
    fiftyFiftyUsed = false;
    askAudienceUsed = false;
    phoneAFriendUsed = false;
    _prepareQuestionsForCurrentLevel();
  }

  void _prepareQuestionsForCurrentLevel() {
    _currentDifficultyQuestions = _allQuestions
        .where((q) => q.difficulty == currentLevel)
        .map((q) => q.copy())
        .toList();
    _currentDifficultyQuestions.shuffle(Random());
  }

  // Internal method to advance to the next question
  void _nextQuestionInternal() {
    if (_currentDifficultyQuestions.isEmpty) {
      currentLevel++;
      _prepareQuestionsForCurrentLevel();
      if (_currentDifficultyQuestions.isEmpty) {
        _currentQuestion = null;
        gameOver = true;
        return;
      }
    }
    _currentQuestion = _currentDifficultyQuestions.removeAt(0);
    _currentQuestion!.shuffleOptions(); // Shuffle options for the new question
    // Reset lifelines for the new question
    fiftyFiftyUsed = false;
    askAudienceUsed = false;
    phoneAFriendUsed = false;
  }

  // Public method to advance to the next question, called by GameScreen
  void advanceToNextQuestion() {
    _nextQuestionInternal();
    notifyListeners(); // Notify listeners that the question has changed
  }

  // checkAnswer now returns bool synchronously and DOES NOT advance the question
  bool checkAnswer(int selectedAnswerDisplayIndex) {
    if (_currentQuestion == null) return false;

    int originalIndexSelected = _currentQuestion!.originalOptionOrder[selectedAnswerDisplayIndex];

    if (originalIndexSelected == _currentQuestion!.correctAnswer) {
      score += currentLevel * 100;
      // Do NOT call _nextQuestion() here. GameScreen will call advanceToNextQuestion().
      notifyListeners(); // Notify listeners about score change
      return true;
    } else {
      gameOver = true; // Game is over on incorrect answer
      notifyListeners(); // Notify listeners about game over
      return false;
    }
  }

  // --- Profile Management (static methods) ---

  static Future<void> savePlayerProfile(PlayerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    List<PlayerProfile> allProfiles = await loadAllPlayerProfiles();

    int existingIndex = allProfiles.indexWhere((p) => p.name == profile.name);
    if (existingIndex != -1) {
      if (profile.highScore > allProfiles[existingIndex].highScore) {
        allProfiles[existingIndex].highScore = profile.highScore;
      }
    } else {
      allProfiles.add(profile);
    }
    final String jsonString = json.encode(allProfiles.map((p) => p.toJson()).toList());
    await prefs.setString(_allPlayerProfilesKey, jsonString);
  }

  static Future<List<PlayerProfile>> loadAllPlayerProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_allPlayerProfilesKey);
    if (jsonString == null) {
      return [];
    }
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => PlayerProfile.fromJson(json)).toList();
  }

  static Future<void> saveAllPlayerProfiles(List<PlayerProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = json.encode(profiles.map((p) => p.toJson()).toList());
    await prefs.setString(_allPlayerProfilesKey, jsonString);
  }

  Future<void> saveActivePlayerHighScore() async {
    if (activePlayerProfile != null) {
      if (score > activePlayerProfile!.highScore) {
        activePlayerProfile!.highScore = score;
      }
      await savePlayerProfile(activePlayerProfile!);
      notifyListeners(); // Notify listeners if high score is updated (e.g., for UI updates)
    }
  }

  // --- Lifeline Methods ---
  void use5050() {
    if (fiftyFiftyUsed || _currentQuestion == null) return;

    List<int> incorrectOptionsDisplayIndices = [];
    for (int i = 0; i < _currentQuestion!.options.length; i++) {
      if (_currentQuestion!.originalOptionOrder[i] != _currentQuestion!.correctAnswer) {
        incorrectOptionsDisplayIndices.add(i);
      }
    }

    incorrectOptionsDisplayIndices.shuffle(Random());
    if (incorrectOptionsDisplayIndices.length >= 2) {
      _currentQuestion!.options[incorrectOptionsDisplayIndices[0]] = "";
      _currentQuestion!.options[incorrectOptionsDisplayIndices[1]] = "";
    }
    fiftyFiftyUsed = true;
    notifyListeners();
  }

  Map<int, int> askTheAudience() {
    if (askAudienceUsed || _currentQuestion == null) return {};

    Map<int, int> votes = {0: 0, 1: 0, 2: 0, 3: 0};
    int totalVotes = 100;
    Random random = Random();

    int currentCorrectAnswerDisplayIndex = _currentQuestion!.originalOptionOrder.indexOf(_currentQuestion!.correctAnswer);

    int correctVote = 60 + random.nextInt(21);
    votes[currentCorrectAnswerDisplayIndex] = correctVote;
    totalVotes -= correctVote;

    List<int> incorrectOptionsDisplayIndices = [];
    for (int i = 0; i < _currentQuestion!.options.length; i++) {
      if (i != currentCorrectAnswerDisplayIndex && _currentQuestion!.options[i].isNotEmpty) {
        incorrectOptionsDisplayIndices.add(i);
      }
    }

    if (incorrectOptionsDisplayIndices.isNotEmpty) {
      while (totalVotes > 0) {
        for (int optionIndex in incorrectOptionsDisplayIndices) {
          if (totalVotes == 0) break;
          int vote = random.nextInt(min(totalVotes + 1, 20));
          votes[optionIndex] = (votes[optionIndex] ?? 0) + vote;
          totalVotes -= vote;
        }
      }
    }
    int currentSum = votes.values.reduce((sum, element) => sum + element);
    if (currentSum != 100) {
      votes[currentCorrectAnswerDisplayIndex] = votes[currentCorrectAnswerDisplayIndex]! + (100 - currentSum);
    }

    Map<int, int> finalVotes = {};
    votes.forEach((key, value) {
      if (_currentQuestion!.options[key].isNotEmpty) {
        finalVotes[key] = value;
      }
    });

    askAudienceUsed = true;
    notifyListeners();
    return finalVotes;
  }

  String phoneAFriend() {
    if (phoneAFriendUsed || _currentQuestion == null) return "No hint available.";

    Random random = Random();
    String hint = "";

    int currentCorrectAnswerDisplayIndex = _currentQuestion!.originalOptionOrder.indexOf(_currentQuestion!.correctAnswer);

    if (random.nextDouble() < 0.8) {
      hint = "I'm fairly sure the answer is '${_currentQuestion!.options[currentCorrectAnswerDisplayIndex]}'.";
    } else {
      List<int> availableIncorrectOptionsDisplayIndices = [];
      for (int i = 0; i < _currentQuestion!.options.length; i++) {
        if (i != currentCorrectAnswerDisplayIndex && _currentQuestion!.options[i].isNotEmpty) {
          availableIncorrectOptionsDisplayIndices.add(i);
        }
      }
      if (availableIncorrectOptionsDisplayIndices.isNotEmpty) {
        int randomIncorrectDisplayIndex = availableIncorrectOptionsDisplayIndices[random.nextInt(availableIncorrectOptionsDisplayIndices.length)];
        hint = "I think it might be '${_currentQuestion!.options[randomIncorrectDisplayIndex]}', but I'm not 100% sure.";
      } else {
        hint = "Hmm, this is a tough one, I'm not sure!";
      }
    }
    phoneAFriendUsed = true;
    notifyListeners();
    return hint;
  }
}

// Question class
class Question {
  String question;
  List<String> _originalOptions;
  int correctAnswer;
  int difficulty;
  String? hint;

  List<int> originalOptionOrder;
  List<String> _shuffledOptions = [];

  Question({
    required this.question,
    required List<String> options,
    required this.correctAnswer,
    required this.difficulty,
    this.hint,
  }) : _originalOptions = options,
        originalOptionOrder = List.generate(options.length, (index) => index) {
    _shuffledOptions = List.from(_originalOptions);
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    List<String> opts = List<String>.from(json['options']);
    return Question(
      question: json['question'],
      options: opts,
      correctAnswer: json['correctAnswer'],
      difficulty: json['difficulty'] ?? 1,
      hint: json['hint'],
    );
  }

  List<String> get options {
    return _shuffledOptions;
  }

  void shuffleOptions() {
    final Random random = Random();
    List<MapEntry<String, int>> pairedOptions = [];
    for (int i = 0; i < _originalOptions.length; i++) {
      pairedOptions.add(MapEntry(_originalOptions[i], i));
    }

    pairedOptions.shuffle(random);

    _shuffledOptions = pairedOptions.map((entry) => entry.key).toList();
    originalOptionOrder = pairedOptions.map((entry) => entry.value).toList();
  }

  Question copy() {
    return Question(
      question: this.question,
      options: List.from(this._originalOptions),
      correctAnswer: this.correctAnswer,
      difficulty: this.difficulty,
      hint: this.hint,
    );
  }

  // NEW METHOD: Get the CURRENT displayed index of the correct option
  int getCorrectOptionDisplayIndex() {
    // Find the current display index that maps back to the original correct answer index
    return originalOptionOrder.indexOf(correctAnswer);
  }
}
// lib/models/game.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

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

// Game class (Complete and Corrected with missing static methods)
class Game {
  List<Question> _allQuestions = [];
  List<Question> _currentDifficultyQuestions = [];
  Question? currentQuestion;
  int currentLevel = 1;
  int score = 0;
  bool gameOver = false;

  bool fiftyFiftyUsed = false;
  bool askAudienceUsed = false;
  bool phoneAFriendUsed = false;

  // Static keys for SharedPreferences
  static const String _allPlayerProfilesKey = 'allPlayerProfiles';
  static const String lastPlayerNameKey = 'lastPlayerName'; // This was already there
  static const String soundMutedKey = 'isSoundMuted';
  static const String _timedModeEnabledKey = 'isTimedModeEnabled';

  // Static variables for settings
  static bool isSoundMuted = false;
  static bool isTimedModeEnabled = false;

  PlayerProfile? activePlayerProfile;

  Game({this.activePlayerProfile});

  // --- NEW: Method to initialize the game with a specific player profile ---
  Future<void> initializeGame(PlayerProfile playerProfile) async {
    activePlayerProfile = playerProfile;
    await _loadQuestions();
    _resetGame();
  }

  // --- Static Methods for Global Settings and Player Names ---

  // Load all global settings (called once at app start)
  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isSoundMuted = prefs.getBool(soundMutedKey) ?? false;
    isTimedModeEnabled = prefs.getBool(_timedModeEnabledKey) ?? false;
  }

  // Save sound setting
  static Future<void> saveSoundSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(soundMutedKey, value);
    isSoundMuted = value;
  }

  // Save timed mode setting
  static Future<void> saveTimedModeSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_timedModeEnabledKey, value);
    isTimedModeEnabled = value;
  }

  // NEW: Load last played player name
  static Future<String?> loadLastPlayerName() async { // <--- Added this method
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(lastPlayerNameKey);
  }

  // NEW: Save last played player name
  static Future<void> saveLastPlayerName(String name) async { // <--- Added this method
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastPlayerNameKey, name);
  }

  // --- Question and Game Logic ---

  Future<void> _loadQuestions() async {
    final String response = await rootBundle.loadString('assets/bible_questions.json');
    final List<dynamic> data = json.decode(response);
    _allQuestions = data.map((json) => Question.fromJson(json)).toList();
  }

  void _resetGame() {
    score = 0;
    currentLevel = 1;
    gameOver = false;
    fiftyFiftyUsed = false;
    askAudienceUsed = false;
    phoneAFriendUsed = false;
    _prepareQuestionsForCurrentLevel();
    _nextQuestion();
  }

  void _prepareQuestionsForCurrentLevel() {
    _currentDifficultyQuestions = _allQuestions
        .where((q) => q.difficulty == currentLevel)
        .toList();
    _currentDifficultyQuestions.shuffle(Random());
  }

  void _nextQuestion() {
    if (_currentDifficultyQuestions.isEmpty) {
      currentLevel++;
      _prepareQuestionsForCurrentLevel();
      if (_currentDifficultyQuestions.isEmpty) {
        currentQuestion = null;
        gameOver = true;
        return;
      }
    }
    currentQuestion = _currentDifficultyQuestions.removeAt(0);
  }

  Future<bool> checkAnswer(int selectedAnswer) async {
    if (currentQuestion != null && selectedAnswer == currentQuestion!.correctAnswer) {
      score += currentLevel * 100;
      currentLevel++;
      _nextQuestion();
      return true;
    } else {
      gameOver = true;
      return false;
    }
  }

  // --- Profile Management (static methods) ---

  // Save a single player profile (adds/updates in the list)
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
    // Now save the entire updated list
    final String jsonString = json.encode(allProfiles.map((p) => p.toJson()).toList());
    await prefs.setString(_allPlayerProfilesKey, jsonString);
  }

  // Load all player profiles
  static Future<List<PlayerProfile>> loadAllPlayerProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_allPlayerProfilesKey);
    if (jsonString == null) {
      return [];
    }
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => PlayerProfile.fromJson(json)).toList();
  }

  // Save an entire list of player profiles (used after deletions)
  static Future<void> saveAllPlayerProfiles(List<PlayerProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = json.encode(profiles.map((p) => p.toJson()).toList());
    await prefs.setString(_allPlayerProfilesKey, jsonString);
  }

  // Call this method from GameCompleteScreen and GameOverScreen
  Future<void> saveActivePlayerHighScore() async {
    if (activePlayerProfile != null) {
      if (score > activePlayerProfile!.highScore) {
        activePlayerProfile!.highScore = score;
      }
      await savePlayerProfile(activePlayerProfile!);
    }
  }

  // --- Lifeline Methods ---
  void use5050() {
    if (fiftyFiftyUsed || currentQuestion == null) return;

    List<int> incorrectOptions = [];
    for (int i = 0; i < currentQuestion!.options.length; i++) {
      if (i != currentQuestion!.correctAnswer) {
        incorrectOptions.add(i);
      }
    }
    incorrectOptions.shuffle(Random());
    currentQuestion!.options[incorrectOptions[0]] = "";
    currentQuestion!.options[incorrectOptions[1]] = "";
    fiftyFiftyUsed = true;
  }

  Map<int, int> askTheAudience() {
    if (askAudienceUsed || currentQuestion == null) return {};

    Map<int, int> votes = {0: 0, 1: 0, 2: 0, 3: 0};
    int totalVotes = 100;
    Random random = Random();

    int correctVote = 60 + random.nextInt(21);
    votes[currentQuestion!.correctAnswer] = correctVote;
    totalVotes -= correctVote;

    List<int> incorrectOptions = [];
    for (int i = 0; i < currentQuestion!.options.length; i++) {
      if (i != currentQuestion!.correctAnswer && currentQuestion!.options[i].isNotEmpty) {
        incorrectOptions.add(i);
      }
    }

    if (incorrectOptions.isNotEmpty) {
      while (totalVotes > 0) {
        for (int optionIndex in incorrectOptions) {
          if (totalVotes == 0) break;
          int vote = random.nextInt(min(totalVotes + 1, 20));
          votes[optionIndex] = (votes[optionIndex] ?? 0) + vote;
          totalVotes -= vote;
        }
      }
    }
    int currentSum = votes.values.reduce((sum, element) => sum + element);
    if (currentSum != 100) {
      votes[currentQuestion!.correctAnswer] = votes[currentQuestion!.correctAnswer]! + (100 - currentSum);
    }

    Map<int, int> finalVotes = {};
    votes.forEach((key, value) {
      if (currentQuestion!.options[key].isNotEmpty && value > 0) {
        finalVotes[key] = value;
      } else if (currentQuestion!.options[key].isNotEmpty && value == 0) {
        finalVotes[key] = 0;
      }
    });

    askAudienceUsed = true;
    return finalVotes;
  }

  String phoneAFriend() {
    if (phoneAFriendUsed || currentQuestion == null) return "No hint available.";

    Random random = Random();
    String hint = "";
    if (random.nextDouble() < 0.8) {
      hint = "I'm fairly sure the answer is '${currentQuestion!.options[currentQuestion!.correctAnswer]}'.";
    } else {
      List<int> incorrectOptions = [];
      for (int i = 0; i < currentQuestion!.options.length; i++) {
        if (i != currentQuestion!.correctAnswer && currentQuestion!.options[i].isNotEmpty) {
          incorrectOptions.add(i);
        }
      }
      if (incorrectOptions.isNotEmpty) {
        int randomIncorrectIndex = incorrectOptions[random.nextInt(incorrectOptions.length)];
        hint = "I think it might be '${currentQuestion!.options[randomIncorrectIndex]}', but I'm not 100% sure.";
      } else {
        hint = "Hmm, this is a tough one, I'm not sure!";
      }
    }
    phoneAFriendUsed = true;
    return hint;
  }
}

// Question class
class Question {
  String question;
  List<String> options;
  int correctAnswer;
  int difficulty;
  String? hint;

  Question({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.difficulty,
    this.hint,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'],
      options: List<String>.from(json['options']),
      correctAnswer: json['correctAnswer'],
      difficulty: json['difficulty'] ?? 1,
      hint: json['hint'],
    );
  }
}
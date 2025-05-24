// game.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Required for json.decode
import 'package:flutter/services.dart' show rootBundle; // Required for rootBundle

class Game {
  String playerName;
  int score = 0; // Current game score
  int currentLevel = 1;
  List<Question> questions = [];
  Question? currentQuestion;
  bool gameOver = false;
  bool fiftyFiftyUsed = false;
  bool askAudienceUsed = false;
  bool phoneAFriendUsed = false;
  int highScore = 0; // Dedicated variable for the global high score

  Game({this.playerName = 'Player'}) {
    // Moved initialization to initializeGame
  }

  Future<void> initializeGame(String playerName) async {
    this.playerName = playerName;
    score = 0; // Reset current score for a new game
    currentLevel = 1;
    questions = await _loadQuestions(); // Load actual questions from JSON
    await _loadHighScore(); // Load the actual high score into `this.highScore`
    _nextQuestion();
    fiftyFiftyUsed = false;
    askAudienceUsed = false;
    phoneAFriendUsed = false;
    gameOver = false;
  }

  // --- START OF JSON LOADING FIX ---
  Future<List<Question>> _loadQuestions() async {
    try {
      final String response = await rootBundle.loadString('assets/bible_questions.json');
      final List<dynamic> data = json.decode(response);
      return data.map((questionData) => Question.fromJson(questionData)).toList();
    } catch (e) {
      print("Error loading questions: $e");
      // Fallback to a default or empty list if loading fails
      return [
        Question(
            question: "Failed to load questions. Is 'assets/bible_questions.json' correct?",
            options: ["Yes", "No", "Maybe", "Check Console"],
            correctAnswer: 3),
      ];
    }
  }
  // --- END OF JSON LOADING FIX ---

  void _nextQuestion() {
    if (questions.isNotEmpty) {
      currentQuestion = questions.removeAt(0);
    } else {
      currentQuestion = null;
      gameOver = true; // No more questions
    }
  }

  Future<bool> checkAnswer(int selectedAnswer) async {
    if (currentQuestion != null &&
        selectedAnswer == currentQuestion!.correctAnswer) {
      score += currentLevel * 100; // Increase score based on level
      currentLevel++; // Increase level
      _nextQuestion(); // Load the next question
      await _saveHighScore(); // Save the new high score if it's higher
      return true;
    } else {
      return false;
    }
  }

  void use5050() {
    if (currentQuestion != null) {
      fiftyFiftyUsed = true;
      // Remove two incorrect answers
      final correctAnswer = currentQuestion!.correctAnswer;
      final incorrectAnswers = <int>[];
      for (int i = 0; i < currentQuestion!.options.length; i++) {
        if (i != correctAnswer) {
          incorrectAnswers.add(i);
        }
      }
      incorrectAnswers.shuffle();
      final answersToRemove = incorrectAnswers.take(2).toList();
      for (final index in answersToRemove) {
        currentQuestion!.options[index] = ""; // Mark as empty
      }
    }
  }

  Map<int, int> askTheAudience() {
    askAudienceUsed = true;
    final votes = <int, int>{};
    if (currentQuestion != null) {
      final correctAnswer = currentQuestion!.correctAnswer;
      int remainingPercentage = 100;
      for (int i = 0; i < currentQuestion!.options.length; i++) {
        if (currentQuestion!.options[i].isNotEmpty) {
          if (i == correctAnswer) {
            votes[i] = remainingPercentage > 50 ? 50 + (remainingPercentage - 50) % 51 : remainingPercentage;
          } else {
            votes[i] = (remainingPercentage / (currentQuestion!.options.where((option) => option.isNotEmpty).length - 1)).round();
          }
          remainingPercentage -= votes[i]!;
        } else {
          votes[i] = 0; // No votes for removed options
        }
      }
    }
    return votes;
  }

  String phoneAFriend() {
    phoneAFriendUsed = true;
    if (currentQuestion != null) {
      // Replace with more sophisticated logic (e.g., probability-based hints)
      return "I think the answer is ${currentQuestion!.options[currentQuestion!.correctAnswer]}";
    }
    return "I'm not sure.";
  }

  // Shared Preferences for High Score
  static const String highScoreKey = 'high_score'; // <--- REMOVED THE UNDERSCORE

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt(highScoreKey) ?? 0;
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (score > highScore) {
      await prefs.setInt(highScoreKey, score);
      highScore = score;
    }
  }
}

class Question {
  String question;
  List<String> options;
  int correctAnswer;

  Question(
      {required this.question,
        required this.options,
        required this.correctAnswer});

  // --- START OF JSON FACTORY CONSTRUCTOR ---
  // Factory constructor for creating a Question from a JSON map
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'],
      options: List<String>.from(json['options']),
      correctAnswer: json['correctAnswer'],
    );
  }
// --- END OF JSON FACTORY CONSTRUCTOR ---
}
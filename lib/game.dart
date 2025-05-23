import 'question.dart';
import 'dart:math';

class Game {
  int currentLevel = 1;
  int score = 0;
  String playerName = "";
  List<Question> _allQuestions = []; // Store all questions loaded from JSON
  List<Question> _availableQuestionsForCurrentGame = []; // Questions for the current play through
  Question? currentQuestion;
  bool fiftyFiftyUsed = false;
  bool askAudienceUsed = false;
  bool phoneAFriendUsed = false;
  bool gameOver = false;

  bool get allQuestionsCompletedSuccessfully {
    // Check if all questions have been answered correctly
    return gameOver && currentQuestion == null && score == _allQuestions.length;
  }


  Map<int, int>? audienceVotes;
  String? friendHint;

  Future<void> initializeGame(String playerName) async {
    this.playerName = playerName;
    // Load all questions only once, if not already loaded
    if (_allQuestions.isEmpty) {
      _allQuestions = await loadQuestions();
    }
    // Reset available questions for a new game
    _availableQuestionsForCurrentGame = List.from(_allQuestions);
    currentLevel = 1; // Reset level
    score = 0; // Reset score
    fiftyFiftyUsed = false; // Reset 50/50
    askAudienceUsed = false; // Reset Ask the Audience
    phoneAFriendUsed = false; // Reset Phone a Friend
    gameOver = false; // Reset game over state

    await _selectQuestion();
  }

  Future<void> _selectQuestion() async {
    // If no more questions are available for the current game, set game over
    if (_availableQuestionsForCurrentGame.isEmpty) {
      gameOver = true;
      currentQuestion = null; // No more questions to display
      return;
    }

    final level = _getLevelForCurrentLevel();
    List<Question> filteredQuestions = _getFilteredQuestions(level);

    if (filteredQuestions.isEmpty) {
      // If no questions are available for the current exact level, try fallback to next difficulty
      filteredQuestions = _getFallbackQuestions(level);

      if (filteredQuestions.isEmpty) {
        // If still no questions are available. It means we've exhausted all questions in general
        gameOver = true;
        currentQuestion = null; // No more questions to display
        return;
      }
    }

    currentQuestion = _selectRandomQuestion(filteredQuestions);
    // Remove the selected question from available list for the current game
    _availableQuestionsForCurrentGame.remove(currentQuestion);
  }

  List<Question> _getFilteredQuestions(String level) {
    return _availableQuestionsForCurrentGame.where((q) => q.level == level).toList();
  }

  String _getNextLevel(String level) {
    return switch (level) {
      "Basic" => "Intermediate",
      "Intermediate" => "Advanced",
      _ => "", // No next level available
    };
  }

  // Modified to handle cases where there might be no questions available in the current level
  List<Question> _getFallbackQuestions(String currentDifficultyLevel) {
    String nextLevel = currentDifficultyLevel;
    List<Question> questionsInNextLevel = [];

    // Keep trying subsequent levels until questions are found or no more levels are available
    while (questionsInNextLevel.isEmpty && nextLevel.isNotEmpty) {
      nextLevel = _getNextLevel(nextLevel);
      if (nextLevel.isNotEmpty) {
        questionsInNextLevel = _getFilteredQuestions(nextLevel);
      }
    }
    return questionsInNextLevel;
  }

  Question _selectRandomQuestion(List<Question> questionList) {
    questionList.shuffle();
    return questionList.first;
  }

  String _getLevelForCurrentLevel() {
    // You can adjust these thresholds based on your desired game design length and difficulty progression
    if (currentLevel <= 30) {
      return "Basic";
    } else if (currentLevel <= 70) {
      return "Intermediate";
    } else {
      return "Advanced";
    }
  }

  Future<bool> checkAnswer(int selectedAnswerIndex) async {
    if (currentQuestion == null) {
      return false; // Should not happen if _selectQuestion is called correctly
    }

    if (selectedAnswerIndex == currentQuestion!.correctAnswer) {
      score++;
      currentLevel++; // Increment level even if no more questions are available, for accurate "level reached" tracking
      await _selectQuestion(); // Try to get the next question
      return true;
    } else {
      gameOver = true;
      return false;
    }
  }

  void use5050() {
    if (currentQuestion == null || fiftyFiftyUsed) return;
    fiftyFiftyUsed = true;
    final incorrectIndices = currentQuestion!.options
        .asMap()
        .entries
        .where((entry) => entry.key != currentQuestion!.correctAnswer && entry.value.isNotEmpty) // Ensure it's not already empty
        .map((entry) => entry.key)
        .toList();
    incorrectIndices.shuffle();
    // Only remove if there are at least 2 incorrect options
    final numToRemove = min(2, incorrectIndices.length);
    final indicesToRemove = incorrectIndices.sublist(0, numToRemove);

    for (final index in indicesToRemove) {
      currentQuestion!.options[index] = "";
    }
  }

  Map<int, int> askTheAudience() {
    if (currentQuestion == null || askAudienceUsed) return {};
    askAudienceUsed = true;
    audienceVotes = <int, int>{};
    const totalVotes = 100;
    // Base confidence for correct answer
    double correctAnswerConfidence = 0.6;
    //Increase confidence slightly with higher levels (up to 0.4 * level/total_max_level)
    // Assuming max level is around 100 to make this scale
    correctAnswerConfidence += (0.4 * (currentLevel / 100.0));
    correctAnswerConfidence = correctAnswerConfidence.clamp(0.6, 1.0); // keep it within a reasonable range

    final correctAnswerVotes =
        (totalVotes * correctAnswerConfidence).round();
    audienceVotes![currentQuestion!.correctAnswer] = correctAnswerVotes;
    var remainingVotes = totalVotes - correctAnswerVotes;

    // Distribute remaining votes to incorrect answers with slight preference for closer answers
    List<int> incorrectAvailableOptions = currentQuestion!.options.asMap().entries
        .where((entry) => entry.key != currentQuestion!.correctAnswer && entry.value.isNotEmpty)
        .map((entry) => entry.key)
        .toList()
    ..shuffle(); // Randomize the order of incorrect options

    for (int i = 0; i < incorrectAvailableOptions.length; i++) {
      final index = incorrectAvailableOptions[i];
      // Distribute remaining votes to incorrect answers
      int vote = (remainingVotes * (1.0 / (incorrectAvailableOptions.length - i))).round();
      if (remainingVotes - vote < 0) {
        vote = remainingVotes; // Ensure we don't go negative
      }
      audienceVotes![index] = vote;
      remainingVotes -= vote;
      if (remainingVotes <= 0) break; // No more votes to distribute
    }

    // Ensure all options have some vote, even if 0, for consistent display in UI
    for (int i = 0; i < currentQuestion!.options.length; i++) {
      if (!audienceVotes!.containsKey(i)) {
        audienceVotes![i] = 0;
      }
    }

    return audienceVotes!;
  }


  String phoneAFriend() {
    if (currentQuestion == null || phoneAFriendUsed) return "";
    phoneAFriendUsed = true;

    final random = Random();
    final options = currentQuestion!.options;
    final correctIndex = currentQuestion!.correctAnswer;

    // 70% chance to give the correct answer or a related clue
    if (random.nextInt(10) < 7) {
      return "I think the answer is ${options[correctIndex]}";
    } else {
      // 30% chance to give a wrong answer or a misleading clue
      final incorrectIndices = <int>[];
      for (var i = 0; i < options.length; i++) {
        if (i != correctIndex && options[i] != "") {
          incorrectIndices.add(i);
        }
      }

      if (incorrectIndices.isNotEmpty) {
        final randomIndex = random.nextInt(incorrectIndices.length);
        return "Hmm, maybe it's ${options[incorrectIndices[randomIndex]]}?";
      } else {
        return "Sorry, I'm not sure about this one.";
      }
    }
  }
}

import 'question.dart';
import 'dart:math';

class Game {
  int currentLevel = 1;
  int score = 0;
  String playerName = "";
  List<Question> questions = [];
  Question? currentQuestion;
  bool fiftyFiftyUsed = false;
  bool askAudienceUsed = false;
  bool phoneAFriendUsed = false;
  bool gameOver = false;

  Map<int, int>? audienceVotes;

  String? friendHint;

  Future<void> initializeGame(String playerName) async {
    this.playerName = playerName;
    questions = await loadQuestions();
    await _selectQuestion();
  }

  Future<void> _selectQuestion() async {
    if (questions.isEmpty) {
      gameOver = true;
      return;
    }

    final level = _getLevelForCurrentLevel();
    List<Question> filteredQuestions = _getFilteredQuestions(level);

    if (filteredQuestions.isEmpty) {
      filteredQuestions = _getFallbackQuestions(level);
      if (filteredQuestions.isEmpty) {
        // Check if all levels are completed
        if (currentLevel > 100) {
          // Assuming 100 levels
          gameOver = true;
          return;
        } else {
          gameOver = true;
          return;
        }
      }
    }

    currentQuestion = _selectRandomQuestion(filteredQuestions);
    questions.remove(currentQuestion);
  }

  List<Question> _getFilteredQuestions(String level) {
    return questions.where((q) => q.level == level).toList();
  }

  List<Question> _getFallbackQuestions(String level) {
    final nextLevel = _getNextLevel(level);
    if (nextLevel.isNotEmpty) {
      return _getFilteredQuestions(nextLevel);
    }
    return [];
  }

  String _getNextLevel(String level) {
    return switch (level) {
      "Basic" => "Intermediate",
      "Intermediate" => "Advanced",
      _ => "",
    };
  }

  Question _selectRandomQuestion(List<Question> questionList) {
    questionList.shuffle();
    return questionList.first;
  }

  String _getLevelForCurrentLevel() {
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
      return false;
    }

    if (selectedAnswerIndex == currentQuestion!.correctAnswer) {
      currentLevel++;
      score++;
      await _selectQuestion();
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
        .where((entry) => entry.key != currentQuestion!.correctAnswer)
        .map((entry) => entry.key)
        .toList();
    incorrectIndices.shuffle();
    final indicesToRemove = incorrectIndices.sublist(0, 2);

    for (final index in indicesToRemove) {
      currentQuestion!.options[index] = "";
    }
  }

  Map<int, int> askTheAudience() {
    if (currentQuestion == null || askAudienceUsed) return {};
    askAudienceUsed = true;
    audienceVotes = <int, int>{};
    const totalVotes = 100;
    final correctAnswerVotes =
        (totalVotes * 0.6 + (totalVotes * 0.4 * (currentLevel / 100.0)))
            .round();
    audienceVotes![currentQuestion!.correctAnswer] = correctAnswerVotes;
    var remainingVotes = totalVotes - correctAnswerVotes;

    currentQuestion!.options.asMap().forEach((index, option) {
      if (index != currentQuestion!.correctAnswer && option.isNotEmpty) {
        var vote = (remainingVotes * 0.3).round();
        if (remainingVotes - vote < 0) {
          vote = remainingVotes;
        }
        audienceVotes![index] = vote;
        remainingVotes -= vote;
      }
    });

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

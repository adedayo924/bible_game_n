import 'dart:convert';
import 'package:flutter/services.dart';

class Question {
  final String level;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String topic;

  const Question({
    required this.level,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.topic,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      level: json['level'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctAnswer: json['correctAnswer'] as int,
      topic: json['topic'] as String,
    );
  }
}

Future<List<Question>> loadQuestions() async {
  try {
    final jsonString =
        await rootBundle.loadString('assets/bible_questions.json');
    final jsonList = json.decode(jsonString) as List;

    return jsonList
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    print('Error loading questions: $e');
    return [];
  }
}

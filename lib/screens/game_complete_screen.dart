// lib/screens/game_complete_screen.dart
import 'package:flutter/material.dart';
import 'dart:math'; // Import for min function
import 'home_screen.dart';

class GameCompleteScreen extends StatelessWidget {
  final String playerName;
  final int score;
  final VoidCallback onPlayAgain;

  const GameCompleteScreen({
    super.key,
    required this.playerName,
    required this.score,
    required this.onPlayAgain,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Define maximum sizes to cap growth on large screens
    const double maxCongratulationFontSize = 50.0;
    const double maxPlayerMessageFontSize = 28.0;
    const double maxScoreFontSize = 40.0;
    const double maxButtonVerticalPadding = 25.0;
    const double maxButtonHorizontalPadding = 70.0;
    const double maxButtonFontSize = 24.0;
    const double maxVerticalSpacing = 50.0;
    const double maxButtonSpacing = 20.0;

    return Scaffold(
      extendBodyBehindAppBar: true, // Extends body behind app bar
      extendBody: true,             // Extends body behind bottom system nav bar
      appBar: AppBar(
        title: const Text('Game Complete!'),
        backgroundColor: Colors.deepPurpleAccent.withOpacity(0.7),
        foregroundColor: Colors.white,
        elevation: 0,
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
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              double minLayoutHeight = constraints.maxHeight > 0
                  ? constraints.maxHeight
                  : screenHeight - AppBar().preferredSize.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom;

              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minLayoutHeight),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(height: min(screenHeight * 0.05, maxVerticalSpacing)), // Dynamic padding from top, capped

                        // Congratulations Text
                        Text(
                          'Congratulations!',
                          style: TextStyle(
                            fontSize: min(screenWidth * 0.1, maxCongratulationFontSize),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: min(screenHeight * 0.02, maxButtonSpacing)), // Smaller spacing

                        // Player message
                        Text(
                          '$playerName, you completed all levels!',
                          style: TextStyle(fontSize: min(screenWidth * 0.06, maxPlayerMessageFontSize), color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: min(screenHeight * 0.02, maxButtonSpacing)), // Smaller spacing

                        // Final Score
                        Text(
                          'Final Score: $score',
                          style: TextStyle(
                            fontSize: min(screenWidth * 0.08, maxScoreFontSize),
                            fontWeight: FontWeight.bold,
                            color: Colors.amberAccent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: min(screenHeight * 0.05, maxVerticalSpacing)), // Larger spacing before buttons

                        // Play Again Button
                        ElevatedButton(
                          onPressed: onPlayAgain,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.deepPurple,
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                vertical: min(screenHeight * 0.02, maxButtonVerticalPadding),
                                horizontal: min(screenWidth * 0.1, maxButtonHorizontalPadding)
                            ),
                            textStyle: TextStyle(fontSize: min(screenWidth * 0.05, maxButtonFontSize), fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 5,
                          ),
                          child: const Text('Play Again'),
                        ),
                        SizedBox(height: min(screenHeight * 0.02, maxButtonSpacing)), // Fixed space between buttons, capped

                        // Back to Home Button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const HomeScreen()),
                                  (Route<dynamic> route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.deepPurple,
                            padding: EdgeInsets.symmetric(
                                vertical: min(screenHeight * 0.02, maxButtonVerticalPadding),
                                horizontal: min(screenWidth * 0.1, maxButtonHorizontalPadding)
                            ),
                            textStyle: TextStyle(fontSize: min(screenWidth * 0.05, maxButtonFontSize)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 5,
                          ),
                          child: const Text('Back to Home'),
                        ),
                        SizedBox(height: min(screenHeight * 0.05, maxVerticalSpacing)), // Dynamic padding at the bottom, capped
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'dart:math'; // Import for min function
import '../settings_screen.dart';
import 'high_score_screen.dart';
import 'profile_selection_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for adaptive sizing
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Define maximum sizes to cap growth on large screens
    const double maxLogoSize = 200.0; // Max width/height for logo
    const double maxTitleFontSize = 48.0; // Max font size for game title
    const double maxButtonVerticalPadding = 25.0; // Max vertical padding for buttons
    const double maxButtonHorizontalPadding = 70.0; // Max horizontal padding for buttons
    const double maxButtonFontSize = 24.0; // Max font size for button text
    const double maxVerticalSpacing = 50.0; // Max height for main SizedBox spacing
    const double maxButtonSpacing = 20.0; // Max height for spacing between buttons

    return Scaffold(
      extendBodyBehindAppBar: true, // Extends body behind app bar
      extendBody: true,             // Extends body behind bottom system nav bar
      appBar: AppBar(
        title: const Text('Bible Knowledge Game'),
        backgroundColor: Colors.deepPurpleAccent.withOpacity(0.7), // Slightly transparent for gradient
        foregroundColor: Colors.white,
        elevation: 0, // Remove shadow under app bar
      ),
      body: Container(
        // Ensures the gradient covers the entire screen, including safe areas
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4B0082), // Deep Indigo
              Color(0xFF9370DB), // Medium Purple/Lavender
            ],
          ),
        ),
        child: SafeArea( // Ensures content within the column respects safe areas
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

                        // Adaptive Logo Icon Image with cap
                        ConstrainedBox( // Use ConstrainedBox to cap the image's effective size
                          constraints: BoxConstraints(
                            maxWidth: maxLogoSize,
                            maxHeight: maxLogoSize,
                          ),
                          child: FractionallySizedBox(
                            widthFactor: 0.5, // Still scales with screenWidth, but is capped by ConstrainedBox
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20), // Fixed space after logo

                        // Game Title with capped font size
                        Text(
                          'Bible Knowledge Game',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: min(screenWidth * 0.08, maxTitleFontSize), // Capped font size
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: const [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black45,
                                offset: Offset(3.0, 3.0),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: min(screenHeight * 0.05, maxVerticalSpacing)), // Dynamic space after title, capped

                        // Start Game Button with capped padding and font size
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProfileSelectionScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.deepPurple,
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                vertical: min(screenHeight * 0.02, maxButtonVerticalPadding), // Capped vertical padding
                                horizontal: min(screenWidth * 0.1, maxButtonHorizontalPadding) // Capped horizontal padding
                            ),
                            textStyle: TextStyle(
                                fontSize: min(screenWidth * 0.05, maxButtonFontSize), // Capped font size
                                fontWeight: FontWeight.bold
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 5,
                          ),
                          child: const Text('Start Game'),
                        ),
                        SizedBox(height: min(screenHeight * 0.02, maxButtonSpacing)), // Fixed space between buttons, capped

                        // High Scores Button with capped padding and font size
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HighScoreScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.deepPurple,
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                vertical: min(screenHeight * 0.02, maxButtonVerticalPadding),
                                horizontal: min(screenWidth * 0.1, maxButtonHorizontalPadding)
                            ),
                            textStyle: TextStyle(
                                fontSize: min(screenWidth * 0.05, maxButtonFontSize),
                                fontWeight: FontWeight.bold
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 5,
                          ),
                          child: const Text('High Scores'),
                        ),
                        SizedBox(height: min(screenHeight * 0.02, maxButtonSpacing)), // Fixed space between buttons, capped

                        // Settings Button with capped padding and font size
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SettingsScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.deepPurple,
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                vertical: min(screenHeight * 0.02, maxButtonVerticalPadding),
                                horizontal: min(screenWidth * 0.1, maxButtonHorizontalPadding)
                            ),
                            textStyle: TextStyle(
                                fontSize: min(screenWidth * 0.05, maxButtonFontSize),
                                fontWeight: FontWeight.bold
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 5,
                          ),
                          child: const Text('Settings'),
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
// lib/screens/high_score_screen.dart
import 'package:flutter/material.dart';
import 'dart:math'; // Import for min function
import '../models/game.dart';

class HighScoreScreen extends StatefulWidget {
  const HighScoreScreen({super.key});

  @override
  State<HighScoreScreen> createState() => _HighScoreScreenState();
}

class _HighScoreScreenState extends State<HighScoreScreen> {
  List<PlayerProfile> _playerProfiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
    });
    _playerProfiles = await Game.loadAllPlayerProfiles();
    _playerProfiles.sort((a, b) => b.highScore.compareTo(a.highScore));
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Define maximum sizes to cap growth on large screens
    const double maxEmptyMessageFontSize = 22.0;
    const double maxListPadding = 24.0;
    const double maxCardVerticalMargin = 12.0;
    const double maxCardHorizontalPadding = 20.0;
    const double maxRankContainerWidth = 60.0;
    const double maxRankFontSize = 24.0;
    const double maxPlayerNameFontSize = 26.0;
    const double maxScoreValueFontSize = 26.0;
    const double maxSpacingBetweenRankAndName = 20.0;


    return Scaffold(
      extendBodyBehindAppBar: true, // Extends body behind app bar
      extendBody: true,             // Extends body behind bottom system nav bar
      appBar: AppBar(
        title: const Text('Global Leaderboard'),
        backgroundColor: Colors.deepPurpleAccent.withOpacity(0.7), // Slightly transparent
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
        child: SafeArea( // Ensures content respects safe areas
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _playerProfiles.isEmpty
              ? Center( // Center the empty message
            child: Padding(
              padding: const EdgeInsets.all(20.0), // Consistent padding
              child: Text(
                'No scores yet. Start a game!',
                style: TextStyle(
                  fontSize: min(screenWidth * 0.05, maxEmptyMessageFontSize),
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
              : ListView.builder(
            padding: EdgeInsets.all(min(screenWidth * 0.04, maxListPadding)), // Adaptive padding
            itemCount: _playerProfiles.length,
            itemBuilder: (context, index) {
              final profile = _playerProfiles[index];
              final int rank = index + 1;
              Color rankColor = Colors.white;
              if (rank == 1) {
                rankColor = Colors.amberAccent; // Gold for 1st
              } else if (rank == 2) {
                rankColor = Colors.grey[400]!; // Silver for 2nd
              } else if (rank == 3) {
                rankColor = Colors.brown[300]!; // Bronze for 3rd
              }

              return Card(
                margin: EdgeInsets.symmetric(vertical: min(screenHeight * 0.015, maxCardVerticalMargin)), // Adaptive vertical margin
                color: Colors.deepPurple[100]?.withOpacity(0.9), // Lighter purple card, slightly transparent
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: min(screenHeight * 0.02, maxCardHorizontalPadding),
                    horizontal: min(screenWidth * 0.04, maxCardHorizontalPadding),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: min(screenWidth * 0.1, maxRankContainerWidth), // Adaptive width for rank
                        alignment: Alignment.center,
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            fontSize: min(screenWidth * 0.055, maxRankFontSize), // Adaptive rank font size
                            fontWeight: FontWeight.bold,
                            color: rankColor,
                          ),
                        ),
                      ),
                      SizedBox(width: min(screenWidth * 0.04, maxSpacingBetweenRankAndName)), // Adaptive spacing
                      Expanded(
                        child: Text(
                          profile.name,
                          style: TextStyle(
                              fontSize: min(screenWidth * 0.06, maxPlayerNameFontSize), // Adaptive player name font size
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple),
                        ),
                      ),
                      Text(
                        '${profile.highScore}',
                        style: TextStyle(
                            fontSize: min(screenWidth * 0.06, maxScoreValueFontSize), // Adaptive score font size
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple),
                      ),
                    ],
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
// lib/screens/high_score_screen.dart
import 'package:flutter/material.dart';
import '../models/game.dart'; // Import the Game class to access PlayerProfile and loadAllPlayerProfiles

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
    // Load all player profiles
    _playerProfiles = await Game.loadAllPlayerProfiles();
    // Sort profiles by high score in descending order
    _playerProfiles.sort((a, b) => b.highScore.compareTo(a.highScore));
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Leaderboard'), // Changed title for clarity
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
      ),
      body: Container(
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _playerProfiles.isEmpty
            ? const Center(
          child: Text(
            'No scores yet. Start a game!',
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: _playerProfiles.length,
          itemBuilder: (context, index) {
            final profile = _playerProfiles[index];
            // Determine rank for styling
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
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              color: Colors.deepPurple[100], // Lighter purple card
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        '#$rank',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: rankColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        profile.name,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple),
                      ),
                    ),
                    Text(
                      '${profile.highScore}',
                      style: const TextStyle(
                          fontSize: 22,
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
    );
  }
}
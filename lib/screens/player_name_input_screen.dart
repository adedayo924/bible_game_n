// lib/screens/player_name_input_screen.dart
import 'package:flutter/material.dart';
import 'game_screen.dart'; // Import GameScreen
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import '../models/game.dart'; // Import Game to access the key

class PlayerNameInputScreen extends StatefulWidget {
  const PlayerNameInputScreen({super.key});

  @override
  State<PlayerNameInputScreen> createState() => _PlayerNameInputScreenState();
}

class _PlayerNameInputScreenState extends State<PlayerNameInputScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLastPlayerName(); // <--- Load the last player name when the screen initializes
  }

  // Method to load the last saved player name
  Future<void> _loadLastPlayerName() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPlayerName = prefs.getString(Game.lastPlayerNameKey);
    if (lastPlayerName != null && lastPlayerName.isNotEmpty) {
      _nameController.text = lastPlayerName; // Pre-fill the text field
    }
  }

  // Method to save the current player name
  Future<void> _savePlayerName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Game.lastPlayerNameKey, name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Your Name'),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white, // Ensures title and back button are white
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                key: const ValueKey("playerNameTextField"),
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Player Name',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: const TextStyle(color: Colors.white), // Text color inside the input
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async { // Make onPressed async to await _savePlayerName
                  final playerName = _nameController.text.trim(); // Trim whitespace
                  if (playerName.isNotEmpty) {
                    await _savePlayerName(playerName); // <--- Save the name here
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            GameScreen(playerName: playerName),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter your name')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
                child: const Text('Start Game'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
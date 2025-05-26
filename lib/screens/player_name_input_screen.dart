// lib/screens/player_name_input_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game.dart';

class PlayerNameInputScreen extends StatefulWidget {
  final bool isCreatingNew; // <--- NEW: Flag to indicate if creating a new profile

  // <--- MODIFIED Constructor: Accepts isCreatingNew
  const PlayerNameInputScreen({super.key, this.isCreatingNew = false});

  @override
  State<PlayerNameInputScreen> createState() => _PlayerNameInputScreenState();
}

class _PlayerNameInputScreenState extends State<PlayerNameInputScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Only load last player name if not creating a new profile
    if (!widget.isCreatingNew) { // <--- MODIFIED: Only load if not specifically creating new
      _loadLastPlayerName();
    }
  }

  Future<void> _loadLastPlayerName() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPlayerName = prefs.getString(Game.lastPlayerNameKey);
    if (lastPlayerName != null && lastPlayerName.isNotEmpty) {
      _nameController.text = lastPlayerName;
    }
  }

  Future<void> _saveLastPlayerName(String name) async { // Renamed for clarity
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
        // <--- MODIFIED AppBar title
        title: Text(widget.isCreatingNew ? 'Create New Profile' : 'Enter Your Name'),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                key: const ValueKey("playerNameTextField"),
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: widget.isCreatingNew ? 'New Player Name' : 'Player Name', // <--- MODIFIED label
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final playerName = _nameController.text.trim();
                  if (playerName.isNotEmpty) {
                    await _saveLastPlayerName(playerName); // Still save for convenience
                    if (widget.isCreatingNew) {
                      // <--- MODIFIED: Pop with the name if creating new
                      Navigator.pop(context, playerName);
                    } else {
                      // <--- This path is now deprecated as we go through ProfileSelectionScreen
                      // But kept as a fallback if you still call it directly without isCreatingNew = true
                      // You might consider removing this else block entirely later if always using ProfileSelectionScreen
                      // Navigator.pushReplacement(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) =>
                      //         GameScreen(playerName: playerName), // This needs to pass PlayerProfile now
                      //   ),
                      // );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a profile from the main menu.')),
                      );
                    }
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
                child: Text(widget.isCreatingNew ? 'Create Profile' : 'Start Game'), // <--- MODIFIED button text
              ),
            ],
          ),
        ),
      ),
    );
  }
}
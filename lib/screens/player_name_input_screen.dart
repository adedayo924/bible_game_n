// lib/screens/player_name_input_screen.dart
import 'package:flutter/material.dart';
import 'dart:math'; // Import for min function
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game.dart';

class PlayerNameInputScreen extends StatefulWidget {
  final bool isCreatingNew;

  const PlayerNameInputScreen({super.key, this.isCreatingNew = false});

  @override
  State<PlayerNameInputScreen> createState() => _PlayerNameInputScreenState();
}

class _PlayerNameInputScreenState extends State<PlayerNameInputScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!widget.isCreatingNew) {
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

  Future<void> _saveLastPlayerName(String name) async {
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Define maximum sizes to cap growth on large screens
    const double maxContentPadding = 24.0;
    const double maxTextFieldFontSize = 22.0;
    const double maxButtonVerticalPadding = 25.0;
    const double maxButtonHorizontalPadding = 70.0;
    const double maxButtonFontSize = 24.0;
    const double maxSpacing = 40.0;


    return Scaffold(
      extendBodyBehindAppBar: true, // Extends body behind app bar
      extendBody: true,             // Extends body behind bottom system nav bar
      appBar: AppBar(
        title: Text(widget.isCreatingNew ? 'Create New Profile' : 'Enter Your Name'),
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
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              double minLayoutHeight = constraints.maxHeight > 0
                  ? constraints.maxHeight
                  : screenHeight - AppBar().preferredSize.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom;

              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minLayoutHeight),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(min(screenWidth * 0.05, maxContentPadding)), // Adaptive padding
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min, // Essential for column within scroll view
                        children: <Widget>[
                          // Optional top spacing if needed, but Center and mainAxisAlignment.center handle it
                          // SizedBox(height: min(screenHeight * 0.1, maxSpacing)),

                          TextField(
                            key: const ValueKey("playerNameTextField"),
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: widget.isCreatingNew ? 'New Player Name' : 'Player Name',
                              labelStyle: TextStyle(color: Colors.white70, fontSize: min(screenWidth * 0.045, maxTextFieldFontSize - 4)), // Adaptive label font size
                              filled: true,
                              fillColor: Colors.deepPurple[100]?.withOpacity(0.2), // Subtle fill for visibility
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.white54),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: min(screenHeight * 0.02, 18.0), // Adaptive vertical padding
                                horizontal: min(screenWidth * 0.05, 20.0), // Adaptive horizontal padding
                              ),
                            ),
                            style: TextStyle(color: Colors.white, fontSize: min(screenWidth * 0.05, maxTextFieldFontSize)), // Adaptive input text font size
                          ),
                          SizedBox(height: min(screenHeight * 0.05, maxSpacing)), // Adaptive spacing

                          ElevatedButton(
                            onPressed: () async {
                              final playerName = _nameController.text.trim();
                              if (playerName.isNotEmpty) {
                                await _saveLastPlayerName(playerName);
                                if (widget.isCreatingNew) {
                                  Navigator.pop(context, playerName);
                                } else {
                                  // This path is deprecated, as noted in your original code.
                                  // Consider removing this else block if this screen is only for new profile creation.
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
                            child: Text(widget.isCreatingNew ? 'Create Profile' : 'Start Game'),
                          ),
                          // Optional bottom spacing
                          // SizedBox(height: min(screenHeight * 0.1, maxSpacing)),
                        ],
                      ),
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
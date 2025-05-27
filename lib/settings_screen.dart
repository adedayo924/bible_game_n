// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'dart:math'; // Import for min function
import 'package:new_game/models/game.dart'; // Import Game class

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSoundMuted = Game.isSoundMuted;
  bool _isTimedModeEnabled = Game.isTimedModeEnabled;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Define maximum sizes to cap growth on large screens
    const double maxListPadding = 24.0;
    const double maxCardVerticalMargin = 16.0;
    const double maxSwitchListTileTitleFontSize = 22.0;
    const double maxSwitchListTileIconSize = 30.0;
    const double maxSwitchListTileContentPaddingHorizontal = 20.0;
    const double maxSwitchListTileContentPaddingVertical = 12.0;


    return Scaffold(
      extendBodyBehindAppBar: true, // Extends body behind app bar
      extendBody: true,             // Extends body behind bottom system nav bar
      appBar: AppBar(
        title: const Text('Settings'),
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
          child: ListView(
            padding: EdgeInsets.all(min(screenWidth * 0.04, maxListPadding)), // Adaptive padding
            children: [
              Card(
                color: Colors.deepPurple[100]?.withOpacity(0.9),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: EdgeInsets.only(bottom: min(screenHeight * 0.02, maxCardVerticalMargin)), // Adaptive vertical margin
                child: SwitchListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: min(screenWidth * 0.05, maxSwitchListTileContentPaddingHorizontal),
                    vertical: min(screenHeight * 0.015, maxSwitchListTileContentPaddingVertical),
                  ),
                  title: Text(
                    'Mute Sound',
                    style: TextStyle(
                      fontSize: min(screenWidth * 0.05, maxSwitchListTileTitleFontSize), // Adaptive font size
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  value: _isSoundMuted,
                  onChanged: (bool value) async {
                    setState(() {
                      _isSoundMuted = value;
                    });
                    await Game.saveSoundSetting(value);
                  },
                  activeColor: Colors.deepPurpleAccent,
                  inactiveTrackColor: Colors.deepPurple[200],
                  secondary: Icon(Icons.volume_up, color: Colors.deepPurple, size: min(screenWidth * 0.07, maxSwitchListTileIconSize)), // Adaptive icon size
                ),
              ),
              Card(
                color: Colors.deepPurple[100]?.withOpacity(0.9),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: EdgeInsets.only(bottom: min(screenHeight * 0.02, maxCardVerticalMargin)), // Adaptive vertical margin
                child: SwitchListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: min(screenWidth * 0.05, maxSwitchListTileContentPaddingHorizontal),
                    vertical: min(screenHeight * 0.015, maxSwitchListTileContentPaddingVertical),
                  ),
                  title: Text(
                    'Enable Timed Mode',
                    style: TextStyle(
                      fontSize: min(screenWidth * 0.05, maxSwitchListTileTitleFontSize), // Adaptive font size
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  value: _isTimedModeEnabled,
                  onChanged: (bool value) async {
                    setState(() {
                      _isTimedModeEnabled = value;
                    });
                    await Game.saveTimedModeSetting(value);
                  },
                  activeColor: Colors.deepPurpleAccent,
                  inactiveTrackColor: Colors.deepPurple[200],
                  secondary: Icon(Icons.timer, color: Colors.deepPurple, size: min(screenWidth * 0.07, maxSwitchListTileIconSize)), // Adaptive icon size
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:new_game/models/game.dart'; // Import Game class

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Use the static variable from the Game class directly
  bool _isSoundMuted = Game.isSoundMuted;
  bool _isTimedModeEnabled = Game.isTimedModeEnabled; // <--- NEW: State for timed mode

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              color: Colors.deepPurple[100]?.withOpacity(0.9),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 16),
              child: SwitchListTile(
                title: const Text(
                  'Mute Sound',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                value: _isSoundMuted,
                onChanged: (bool value) async {
                  setState(() {
                    _isSoundMuted = value;
                  });
                  await Game.saveSoundSetting(value); // Save setting via Game class
                },
                activeColor: Colors.deepPurpleAccent,
                inactiveTrackColor: Colors.deepPurple[200],
                secondary: const Icon(Icons.volume_up, color: Colors.deepPurple),
              ),
            ),
            // --- NEW: Timed Mode Setting ---
            Card(
              color: Colors.deepPurple[100]?.withOpacity(0.9),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 16),
              child: SwitchListTile(
                title: const Text(
                  'Enable Timed Mode',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                value: _isTimedModeEnabled,
                onChanged: (bool value) async {
                  setState(() {
                    _isTimedModeEnabled = value;
                  });
                  await Game.saveTimedModeSetting(value); // Save setting via Game class
                },
                activeColor: Colors.deepPurpleAccent,
                inactiveTrackColor: Colors.deepPurple[200],
                secondary: const Icon(Icons.timer, color: Colors.deepPurple),
              ),
            ),
            // --- END NEW ---
          ],
        ),
      ),
    );
  }
}
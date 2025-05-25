// lib/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/game.dart'; // To access Game.soundMutedKey

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSoundMuted = false;

  @override
  void initState() {
    super.initState();
    _loadSoundSetting();
  }

  Future<void> _loadSoundSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSoundMuted = prefs.getBool(Game.soundMutedKey) ?? false; // Default to not muted
    });
  }

  Future<void> _saveSoundSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Game.soundMutedKey, value);
    setState(() {
      _isSoundMuted = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4B0082), // Deep Indigo
        iconTheme: const IconThemeData(color: Colors.white), // For back button color
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SwitchListTile(
                title: const Text(
                  'Mute Sound Effects',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                value: _isSoundMuted,
                onChanged: (bool value) {
                  _saveSoundSetting(value);
                  // No need to explicitly reload GameScreen here,
                  // as GameScreen will load the setting in its initState
                  // or if you re-navigate to it.
                },
                activeColor: Colors.amber,
                tileColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
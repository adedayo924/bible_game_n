// lib/player_name_input_screen.dart
import 'package:flutter/material.dart';
import 'game_screen.dart'; // Important for navigation to GameScreen

// Paste the PlayerNameInputScreen class content here
class PlayerNameInputScreen extends StatefulWidget {
  const PlayerNameInputScreen({super.key});

  @override
  State<PlayerNameInputScreen> createState() => _PlayerNameInputScreenState();
}

class _PlayerNameInputScreenState extends State<PlayerNameInputScreen> {
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Your Name'), backgroundColor: Colors.deepPurpleAccent,),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FocusScope(
              child: TextField(
                key: const ValueKey("playerNameTextField"),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Player Name'),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          GameScreen(playerName: _nameController.text),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your name')),
                  );
                }
              },
              child: const Text('Start Game'),
            ),
          ],
        ),
      ),
    );
  }
}
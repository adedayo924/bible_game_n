// lib/screens/profile_selection_screen.dart
import 'package:flutter/material.dart';
import '../models/game.dart';
import 'game_screen.dart';

class ProfileSelectionScreen extends StatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  List<PlayerProfile> _playerProfiles = [];
  bool _isLoading = true;
  String _newProfileName = '';
  final TextEditingController _newProfileController = TextEditingController();
  String? _lastPlayedPlayerName;

  @override
  void initState() {
    super.initState();
    _loadProfilesAndLastPlayer();
  }

  Future<void> _loadProfilesAndLastPlayer() async {
    setState(() {
      _isLoading = true;
    });
    _playerProfiles = await Game.loadAllPlayerProfiles();
    _lastPlayedPlayerName = await Game.loadLastPlayerName();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _createNewProfile() async {
    if (_newProfileName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile name cannot be empty!')),
      );
      return;
    }
    if (_playerProfiles.any((p) => p.name == _newProfileName.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile with this name already exists!')),
      );
      return;
    }

    final newProfile = PlayerProfile(name: _newProfileName.trim());
    _playerProfiles.add(newProfile); // Add to the local list

    // Use the new saveAllPlayerProfiles to save the entire list
    await Game.saveAllPlayerProfiles(_playerProfiles); // FIX: Use the new method

    setState(() {
      _newProfileName = '';
      _newProfileController.clear();
    });
    Navigator.of(context).pop(); // Close the dialog
  }

  Future<void> _deleteProfile(PlayerProfile profileToDelete) async {
    setState(() {
      _playerProfiles.removeWhere((profile) => profile.name == profileToDelete.name);
    });
    // Use the new saveAllPlayerProfiles to save the modified list
    await Game.saveAllPlayerProfiles(_playerProfiles); // FIX: Use the new method

    if (_lastPlayedPlayerName == profileToDelete.name) {
      await Game.saveLastPlayerName(''); // Clear last played if deleted
      setState(() {
        _lastPlayedPlayerName = '';
      });
    }
  }

  void _showCreateProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Profile'),
          content: TextField(
            controller: _newProfileController,
            decoration: const InputDecoration(hintText: 'Enter profile name'),
            onChanged: (value) {
              _newProfileName = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                _newProfileController.clear(); // Clear input on cancel
              },
            ),
            ElevatedButton(
              child: const Text('Create'),
              onPressed: _createNewProfile,
            ),
          ],
        );
      },
    );
  }

  void _startGame(String playerName) async {
    await Game.saveLastPlayerName(playerName); // Save as last played
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(playerName: playerName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Profile'),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Column(
          children: [
            Expanded(
              child: _playerProfiles.isEmpty
                  ? const Center(
                child: Text(
                  'No profiles created yet. Create one to start!',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _playerProfiles.length,
                itemBuilder: (context, index) {
                  final profile = _playerProfiles[index];
                  final isLastPlayed = profile.name == _lastPlayedPlayerName;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    color: isLastPlayed ? Colors.deepPurple[200] : Colors.deepPurple[100]?.withOpacity(0.9),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isLastPlayed ? Colors.deepPurpleAccent : Colors.deepPurple[400],
                        child: Text(
                          profile.name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        profile.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isLastPlayed ? Colors.deepPurple[800] : Colors.deepPurple,
                        ),
                      ),
                      subtitle: Text(
                        'High Score: ${profile.highScore}',
                        style: TextStyle(
                          fontSize: 16,
                          color: isLastPlayed ? Colors.deepPurple[600] : Colors.deepPurple[400],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _deleteProfile(profile),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.deepPurple),
                        ],
                      ),
                      onTap: () => _startGame(profile.name),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _showCreateProfileDialog,
                icon: const Icon(Icons.person_add, size: 28),
                label: const Text('Create New Profile'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
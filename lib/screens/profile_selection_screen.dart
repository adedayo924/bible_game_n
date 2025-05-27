// lib/screens/profile_selection_screen.dart
import 'package:flutter/material.dart';
import 'dart:math'; // Import for min function
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
    if (_playerProfiles.any((p) => p.name.toLowerCase() == _newProfileName.trim().toLowerCase())) { // Case-insensitive check
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile with this name already exists!')),
      );
      return;
    }

    final newProfile = PlayerProfile(name: _newProfileName.trim());
    _playerProfiles.add(newProfile);

    await Game.saveAllPlayerProfiles(_playerProfiles);

    setState(() {
      _newProfileName = '';
      _newProfileController.clear();
    });
    if (mounted) Navigator.of(context).pop(); // Close the dialog
  }

  Future<void> _deleteProfile(PlayerProfile profileToDelete) async {
    // Show a confirmation dialog before deleting
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete profile "${profileToDelete.name}"? This cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      setState(() {
        _playerProfiles.removeWhere((profile) => profile.name == profileToDelete.name);
      });
      await Game.saveAllPlayerProfiles(_playerProfiles);

      if (_lastPlayedPlayerName == profileToDelete.name) {
        await Game.saveLastPlayerName('');
        setState(() {
          _lastPlayedPlayerName = '';
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile "${profileToDelete.name}" deleted.')),
        );
      }
    }
  }


  void _showCreateProfileDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double maxDialogWidth = 400.0;
    const double maxTextFieldFontSize = 18.0;
    const double maxDialogButtonFontSize = 16.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // Constrain AlertDialog width for larger screens
          alignment: Alignment.center,
          backgroundColor: Colors.deepPurple[50], // Lighter background for dialog
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Create New Profile', textAlign: TextAlign.center, style: TextStyle(color: Colors.deepPurple)),
          content: TextField(
            controller: _newProfileController,
            decoration: InputDecoration(
              hintText: 'Enter profile name',
              hintStyle: TextStyle(fontSize: min(screenWidth * 0.04, maxTextFieldFontSize - 2)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(fontSize: min(screenWidth * 0.045, maxTextFieldFontSize)),
            onChanged: (value) {
              _newProfileName = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(fontSize: min(screenWidth * 0.04, maxDialogButtonFontSize), color: Colors.grey[700])),
              onPressed: () {
                Navigator.of(context).pop();
                _newProfileController.clear();
              },
            ),
            ElevatedButton(
              onPressed: _createNewProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Create', style: TextStyle(fontSize: min(screenWidth * 0.04, maxDialogButtonFontSize), color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _startGame(String playerName) async {
    await Game.saveLastPlayerName(playerName);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(playerName: playerName),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Define maximum sizes for list items and button
    const double maxProfileNameFontSize = 24.0;
    const double maxHighScoreFontSize = 18.0;
    const double maxListTilePadding = 20.0;
    const double maxAvatarRadius = 30.0;
    const double maxCreateButtonFontSize = 22.0;
    const double maxCreateButtonVerticalPadding = 18.0;
    const double maxCreateButtonHorizontalPadding = 40.0;
    const double maxEmptyMessageFontSize = 22.0;


    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: const Text('Select Profile'),
        backgroundColor: Colors.deepPurpleAccent.withOpacity(0.7),
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
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(
            children: [
              Expanded(
                child: _playerProfiles.isEmpty
                    ? Center( // Ensure Center takes available space
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'No profiles created yet. Create one to start!',
                      style: TextStyle(
                        fontSize: min(screenWidth * 0.05, maxEmptyMessageFontSize),
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
                    : ListView.builder(
                  padding: EdgeInsets.all(min(screenWidth * 0.04, maxListTilePadding)),
                  itemCount: _playerProfiles.length,
                  itemBuilder: (context, index) {
                    final profile = _playerProfiles[index];
                    final isLastPlayed = profile.name == _lastPlayedPlayerName;
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: min(screenHeight * 0.015, 12.0)),
                      color: isLastPlayed ? Colors.deepPurple[200] : Colors.deepPurple[100]?.withOpacity(0.9),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: min(screenHeight * 0.015, 10.0),
                          horizontal: min(screenWidth * 0.04, 20.0),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: isLastPlayed ? Colors.deepPurpleAccent : Colors.deepPurple[400],
                          radius: min(screenWidth * 0.06, maxAvatarRadius), // Adaptive radius
                          child: Text(
                            profile.name[0].toUpperCase(),
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: min(screenWidth * 0.04, maxAvatarRadius * 0.8) // Adaptive text size in avatar
                            ),
                          ),
                        ),
                        title: Text(
                          profile.name,
                          style: TextStyle(
                            fontSize: min(screenWidth * 0.05, maxProfileNameFontSize), // Adaptive font size
                            fontWeight: FontWeight.bold,
                            color: isLastPlayed ? Colors.deepPurple[800] : Colors.deepPurple,
                          ),
                        ),
                        subtitle: Text(
                          'High Score: ${profile.highScore}',
                          style: TextStyle(
                            fontSize: min(screenWidth * 0.04, maxHighScoreFontSize), // Adaptive font size
                            color: isLastPlayed ? Colors.deepPurple[600] : Colors.deepPurple[400],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              iconSize: min(screenWidth * 0.07, 30.0), // Adaptive icon size
                              onPressed: () => _deleteProfile(profile),
                            ),
                            Icon(Icons.arrow_forward_ios, color: Colors.deepPurple, size: min(screenWidth * 0.06, 28.0)), // Adaptive icon size
                          ],
                        ),
                        onTap: () => _startGame(profile.name),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.all(min(screenWidth * 0.04, 20.0)), // Adaptive padding for the button
                child: ElevatedButton.icon(
                  onPressed: _showCreateProfileDialog,
                  icon: Icon(Icons.person_add, size: min(screenWidth * 0.07, 28.0)), // Adaptive icon size
                  label: Text('Create New Profile', style: TextStyle(fontSize: min(screenWidth * 0.05, maxCreateButtonFontSize))), // Adaptive label font size
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.deepPurpleAccent,
                    padding: EdgeInsets.symmetric(
                        vertical: min(screenHeight * 0.02, maxCreateButtonVerticalPadding),
                        horizontal: min(screenWidth * 0.08, maxCreateButtonHorizontalPadding)
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold), // Font size set in label
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                    minimumSize: Size(screenWidth * 0.6, 0), // Ensure button is at least 60% of screen width
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
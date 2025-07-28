import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class GameOnlineMultiplayerScreen extends StatefulWidget {
  const GameOnlineMultiplayerScreen({super.key});

  @override
  State<GameOnlineMultiplayerScreen> createState() => _GameOnlineMultiplayerScreenState();
}

class _GameOnlineMultiplayerScreenState extends State<GameOnlineMultiplayerScreen> 
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  AnimationController? _glowController;
  AnimationController? _pulseController;
  AnimationController? _scaleController;
  
  String? _gameRoomId;
  String? _playerId;
  String? _opponentId;
  String? _opponentName;
  String? _playerChoice;
  String? _opponentChoice;
  String? _gameResult;
  bool _isHost = false;
  bool _isSearching = false;
  bool _gameStarted = false;
  bool _showResult = false;
  int _countdown = 0;
  
  final List<String> _choices = ['rock', 'paper', 'scissors'];
  final Map<String, String> _choiceEmojis = {
    'rock': '🪨',
    'paper': '📄',
    'scissors': '✂️',
  };

  @override
  void initState() {
    super.initState();
    _playerId = _auth.currentUser?.uid;
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _glowController?.dispose();
    _pulseController?.dispose();
    _scaleController?.dispose();
    if (_gameRoomId != null) {
      _leaveGame();
    }
    super.dispose();
  }

  Future<void> _createRoom() async {
    setState(() {
      _isSearching = true;
    });

    try {
      final roomRef = _firestore.collection('game_rooms').doc();
      _gameRoomId = roomRef.id;
      _isHost = true;

      await roomRef.set({
        'host_id': _playerId,
        'host_name': _auth.currentUser?.email?.split('@')[0] ?? 'Player 1',
        'guest_id': null,
        'guest_name': null,
        'host_choice': null,
        'guest_choice': null,
        'game_state': 'waiting', // waiting, playing, finished
        'winner': null,
        'created_at': FieldValue.serverTimestamp(),
        'round': 1,
      });

      _listenToGameRoom();
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      _showError('Failed to create room: $e');
    }
  }

  Future<void> _joinRandomRoom() async {
    setState(() {
      _isSearching = true;
    });

    try {
      final availableRooms = await _firestore
          .collection('game_rooms')
          .where('guest_id', isEqualTo: null)
          .where('game_state', isEqualTo: 'waiting')
          .limit(1)
          .get();

      if (availableRooms.docs.isNotEmpty) {
        final roomDoc = availableRooms.docs.first;
        _gameRoomId = roomDoc.id;
        _isHost = false;

        await roomDoc.reference.update({
          'guest_id': _playerId,
          'guest_name': _auth.currentUser?.email?.split('@')[0] ?? 'Player 2',
          'game_state': 'playing',
        });

        _listenToGameRoom();
      } else {
        // No available rooms, create one
        await _createRoom();
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      _showError('Failed to join room: $e');
    }
  }

  void _listenToGameRoom() {
    if (_gameRoomId == null) return;

    _firestore.collection('game_rooms').doc(_gameRoomId).snapshots().listen(
      (snapshot) {
        if (!snapshot.exists) return;

        final data = snapshot.data()!;
        
        setState(() {
          if (_isHost) {
            _opponentId = data['guest_id'];
            _opponentName = data['guest_name'];
            _opponentChoice = data['guest_choice'];
            _playerChoice = data['host_choice'];
          } else {
            _opponentId = data['host_id'];
            _opponentName = data['host_name'];
            _opponentChoice = data['host_choice'];
            _playerChoice = data['guest_choice'];
          }

          _gameStarted = data['game_state'] == 'playing' && _opponentId != null;
          _isSearching = data['game_state'] == 'waiting';

          // Check if both players made their choices
          if (data['host_choice'] != null && data['guest_choice'] != null) {
            _calculateResult(data['host_choice'], data['guest_choice']);
          }
        });
      },
      onError: (error) {
        _showError('Connection error: $error');
      },
    );
  }

  void _calculateResult(String hostChoice, String guestChoice) {
    String result;
    
    if (hostChoice == guestChoice) {
      result = 'tie';
    } else if ((hostChoice == 'rock' && guestChoice == 'scissors') ||
               (hostChoice == 'paper' && guestChoice == 'rock') ||
               (hostChoice == 'scissors' && guestChoice == 'paper')) {
      result = _isHost ? 'win' : 'lose';
    } else {
      result = _isHost ? 'lose' : 'win';
    }

    setState(() {
      _gameResult = result;
      _showResult = true;
    });

    // Auto reset after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _resetRound();
    });
  }

  Future<void> _makeChoice(String choice) async {
    if (_gameRoomId == null || _playerChoice != null) return;

    try {
      await _firestore.collection('game_rooms').doc(_gameRoomId).update({
        _isHost ? 'host_choice' : 'guest_choice': choice,
      });

      _scaleController?.forward().then((_) {
        _scaleController?.reverse();
      });
    } catch (e) {
      _showError('Failed to make choice: $e');
    }
  }

  Future<void> _resetRound() async {
    if (_gameRoomId == null) return;

    setState(() {
      _playerChoice = null;
      _opponentChoice = null;
      _gameResult = null;
      _showResult = false;
    });

    try {
      await _firestore.collection('game_rooms').doc(_gameRoomId).update({
        'host_choice': null,
        'guest_choice': null,
        'winner': null,
      });
    } catch (e) {
      _showError('Failed to reset round: $e');
    }
  }

  Future<void> _leaveGame() async {
    if (_gameRoomId == null) return;

    try {
      await _firestore.collection('game_rooms').doc(_gameRoomId).delete();
    } catch (e) {
      print('Error leaving game: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController!,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.3 + _pulseController!.value * 0.3),
                      Colors.purple.withOpacity(0.3 + _pulseController!.value * 0.3),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 20 + _pulseController!.value * 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.wifi_find,
                  size: 80,
                  color: Colors.white,
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          const Text(
            'Searching for opponent...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isHost ? 'Room created! Waiting for player to join...' : 'Looking for available rooms...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              if (_gameRoomId != null) {
                _leaveGame();
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameScreen() {
    return Column(
      children: [
        // Player info bar
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.person, color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'You',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _auth.currentUser?.email?.split('@')[0] ?? 'Player',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.person_outline, color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      _opponentName ?? 'Opponent',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Online',
                      style: TextStyle(color: Colors.green.withOpacity(0.8), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Game choices display
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Show choices if made
              if (_playerChoice != null || _opponentChoice != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildChoiceDisplay('Your Choice', _playerChoice),
                    _buildChoiceDisplay('Opponent', _opponentChoice),
                  ],
                ),
                const SizedBox(height: 40),
              ],

              // Result display
              if (_showResult) ...[
                _buildResultDisplay(),
                const SizedBox(height: 30),
              ],

              // Choice buttons (only show if player hasn't chosen)
              if (_playerChoice == null && !_showResult) ...[
                const Text(
                  'Make your choice!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _choices.map((choice) => _buildChoiceButton(choice)).toList(),
                ),
              ],

              // Waiting for opponent
              if (_playerChoice != null && _opponentChoice == null && !_showResult) ...[
                AnimatedBuilder(
                  animation: _pulseController!,
                  builder: (context, child) {
                    return Column(
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          size: 60,
                          color: Colors.white.withOpacity(0.7 + _pulseController!.value * 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Waiting for opponent...',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),

        // Leave game button
        Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: () {
              _leaveGame();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: const Text(
              'Leave Game',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceButton(String choice) {
    return AnimatedBuilder(
      animation: _glowController!,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => _makeChoice(choice),
          child: AnimatedScale(
            scale: _playerChoice == choice ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2 + _glowController!.value * 0.2),
                    blurRadius: 15 + _glowController!.value * 5,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _choiceEmojis[choice]!,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChoiceDisplay(String label, String? choice) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
          ),
          child: Center(
            child: Text(
              choice != null ? _choiceEmojis[choice]! : '?',
              style: const TextStyle(fontSize: 35),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultDisplay() {
    Color resultColor;
    String resultText;
    IconData resultIcon;

    switch (_gameResult) {
      case 'win':
        resultColor = Colors.green;
        resultText = '🎉 You Win!';
        resultIcon = Icons.emoji_events;
        break;
      case 'lose':
        resultColor = Colors.red;
        resultText = '😔 You Lose!';
        resultIcon = Icons.sentiment_dissatisfied;
        break;
      case 'tie':
        resultColor = Colors.orange;
        resultText = '🤝 It\'s a Tie!';
        resultIcon = Icons.handshake;
        break;
      default:
        resultColor = Colors.grey;
        resultText = '';
        resultIcon = Icons.help;
    }

    return AnimatedScale(
      scale: _showResult ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              resultColor.withOpacity(0.3),
              resultColor.withOpacity(0.1),
            ],
          ),
          border: Border.all(color: resultColor.withOpacity(0.5), width: 2),
        ),
        child: Column(
          children: [
            Icon(resultIcon, color: Colors.white, size: 50),
            const SizedBox(height: 10),
            Text(
              resultText,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '🌐 Online Multiplayer',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_gameRoomId != null) {
              _leaveGame();
            }
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade900,
              Colors.teal.shade800,
              Colors.cyan.shade700,
              Colors.blue.shade600,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _isSearching && !_gameStarted
              ? _buildWaitingScreen()
              : _gameStarted
                  ? _buildGameScreen()
                  : Center(
                      child: ElevatedButton(
                        onPressed: _joinRandomRoom,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: const Text(
                          'Find Game',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}
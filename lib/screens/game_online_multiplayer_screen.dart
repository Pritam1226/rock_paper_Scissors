import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

// State Ground Model
class StateGround {
  final String name;
  final String stateName;
  final int entryFee;
  final int prizePool;
  final Color primaryColor;
  final Color secondaryColor;
  final String emoji;
  final String heritage;
  final List<Color> gradientColors;

  StateGround({
    required this.name,
    required this.stateName,
    required this.entryFee,
    required this.prizePool,
    required this.primaryColor,
    required this.secondaryColor,
    required this.emoji,
    required this.heritage,
    required this.gradientColors,
  });
}

class GameOnlineMultiplayerScreen extends StatefulWidget {
  const GameOnlineMultiplayerScreen({super.key});

  @override
  State<GameOnlineMultiplayerScreen> createState() =>
      _GameOnlineMultiplayerScreenState();
}

class _GameOnlineMultiplayerScreenState
    extends State<GameOnlineMultiplayerScreen>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AnimationController? _glowController;
  AnimationController? _pulseController;
  AnimationController? _scaleController;
  AnimationController? _cardController;

  String? _gameRoomId;
  String? _playerId;
  String? _opponentId;
  String? _opponentName;
  String? _playerChoice;
  String? _opponentChoice;
  String? _gameResult;
  StateGround? _selectedGround;
  bool _isHost = false;
  bool _isSearching = false;
  bool _gameStarted = false;
  bool _showResult = false;
  bool _showGroundSelection = true;
  int _countdown = 0;

  final List<String> _choices = ['rock', 'paper', 'scissors'];
  final Map<String, String> _choiceEmojis = {
    'rock': '🪨',
    'paper': '📄',
    'scissors': '✂️',
  };

  // State-based grounds with ascending order of prize pools
  final List<StateGround> _stateGrounds = [
    // Small states - Lower entry fee and prize
    StateGround(
      name: "Sikkim Summit Arena",
      stateName: "Sikkim",
      entryFee: 10,
      prizePool: 100,
      primaryColor: Colors.green,
      secondaryColor: Colors.teal,
      emoji: "🏔️",
      heritage: "Land of Monasteries",
      gradientColors: [Colors.green.shade900, Colors.teal.shade600],
    ),
    StateGround(
      name: "Mizoram Hills Battleground",
      stateName: "Mizoram",
      entryFee: 15,
      prizePool: 150,
      primaryColor: Colors.orange,
      secondaryColor: Colors.deepOrange,
      emoji: "🌄",
      heritage: "Blue Mountain Heritage",
      gradientColors: [Colors.orange.shade800, Colors.deepOrange.shade600],
    ),
    StateGround(
      name: "Arunachal Dawn Arena",
      stateName: "Arunachal Pradesh",
      entryFee: 20,
      prizePool: 200,
      primaryColor: Colors.amber,
      secondaryColor: Colors.orange,
      emoji: "🌅",
      heritage: "Land of Rising Sun",
      gradientColors: [Colors.amber.shade800, Colors.orange.shade600],
    ),
    StateGround(
      name: "Nagaland Warriors Ground",
      stateName: "Nagaland",
      entryFee: 25,
      prizePool: 250,
      primaryColor: Colors.red,
      secondaryColor: Colors.deepOrange,
      emoji: "⚔️",
      heritage: "Festival of Tribes",
      gradientColors: [Colors.red.shade800, Colors.deepOrange.shade600],
    ),
    StateGround(
      name: "Manipur Dance Arena",
      stateName: "Manipur",
      entryFee: 30,
      prizePool: 300,
      primaryColor: Colors.pink,
      secondaryColor: Colors.purple,
      emoji: "💃",
      heritage: "Classical Dance Heritage",
      gradientColors: [Colors.pink.shade800, Colors.purple.shade600],
    ),
    StateGround(
      name: "Tripura Palace Grounds",
      stateName: "Tripura",
      entryFee: 35,
      prizePool: 350,
      primaryColor: Colors.indigo,
      secondaryColor: Colors.blue,
      emoji: "🏰",
      heritage: "Royal Palace Heritage",
      gradientColors: [Colors.indigo.shade800, Colors.blue.shade600],
    ),
    StateGround(
      name: "Meghalaya Cloud Arena",
      stateName: "Meghalaya",
      entryFee: 40,
      prizePool: 400,
      primaryColor: Colors.cyan,
      secondaryColor: Colors.teal,
      emoji: "☁️",
      heritage: "Abode of Clouds",
      gradientColors: [Colors.cyan.shade800, Colors.teal.shade600],
    ),
    StateGround(
      name: "Goa Beach Battleground",
      stateName: "Goa",
      entryFee: 50,
      prizePool: 500,
      primaryColor: Colors.lightBlue,
      secondaryColor: Colors.cyan,
      emoji: "🏖️",
      heritage: "Portuguese Colonial Heritage",
      gradientColors: [Colors.lightBlue.shade800, Colors.cyan.shade600],
    ),
    StateGround(
      name: "Himachal Valley Arena",
      stateName: "Himachal Pradesh",
      entryFee: 60,
      prizePool: 600,
      primaryColor: Colors.blue,
      secondaryColor: Colors.indigo,
      emoji: "🏔️",
      heritage: "Hill Station Paradise",
      gradientColors: [Colors.blue.shade900, Colors.indigo.shade700],
    ),
    StateGround(
      name: "Uttarakhand Peaks Ground",
      stateName: "Uttarakhand",
      entryFee: 70,
      prizePool: 700,
      primaryColor: Colors.teal,
      secondaryColor: Colors.green,
      emoji: "⛰️",
      heritage: "Devbhoomi Sacred Land",
      gradientColors: [Colors.teal.shade900, Colors.green.shade700],
    ),
    StateGround(
      name: "Kerala Backwater Arena",
      stateName: "Kerala",
      entryFee: 80,
      prizePool: 800,
      primaryColor: Colors.green,
      secondaryColor: Colors.teal,
      emoji: "🌴",
      heritage: "God's Own Country",
      gradientColors: [Colors.green.shade900, Colors.teal.shade700],
    ),
    StateGround(
      name: "Punjab Fields Battleground",
      stateName: "Punjab",
      entryFee: 90,
      prizePool: 900,
      primaryColor: Colors.amber,
      secondaryColor: Colors.orange,
      emoji: "🌾",
      heritage: "Land of Five Rivers",
      gradientColors: [Colors.amber.shade800, Colors.orange.shade600],
    ),
    StateGround(
      name: "Haryana Warriors Arena",
      stateName: "Haryana",
      entryFee: 100,
      prizePool: 1000,
      primaryColor: Colors.red,
      secondaryColor: Colors.orange,
      emoji: "🤼",
      heritage: "Wrestling Champions",
      gradientColors: [Colors.red.shade800, Colors.orange.shade600],
    ),
    StateGround(
      name: "Jharkhand Tribal Ground",
      stateName: "Jharkhand",
      entryFee: 110,
      prizePool: 1100,
      primaryColor: Colors.brown,
      secondaryColor: Colors.orange,
      emoji: "🪶",
      heritage: "Tribal Culture Heritage",
      gradientColors: [Colors.brown.shade800, Colors.orange.shade600],
    ),
    StateGround(
      name: "Chhattisgarh Forest Arena",
      stateName: "Chhattisgarh",
      entryFee: 120,
      prizePool: 1200,
      primaryColor: Colors.green,
      secondaryColor: Colors.brown,
      emoji: "🌳",
      heritage: "Rice Bowl of India",
      gradientColors: [Colors.green.shade800, Colors.brown.shade600],
    ),
    StateGround(
      name: "Odisha Temple Grounds",
      stateName: "Odisha",
      entryFee: 130,
      prizePool: 1300,
      primaryColor: Colors.orange,
      secondaryColor: Colors.red,
      emoji: "🛕",
      heritage: "Temple Architecture",
      gradientColors: [Colors.orange.shade800, Colors.red.shade600],
    ),
    StateGround(
      name: "Assam Tea Garden Arena",
      stateName: "Assam",
      entryFee: 140,
      prizePool: 1400,
      primaryColor: Colors.green,
      secondaryColor: Colors.teal,
      emoji: "🍃",
      heritage: "Tea Garden Heritage",
      gradientColors: [Colors.green.shade800, Colors.teal.shade600],
    ),
    StateGround(
      name: "West Bengal Cultural Ground",
      stateName: "West Bengal",
      entryFee: 150,
      prizePool: 1500,
      primaryColor: Colors.red,
      secondaryColor: Colors.orange,
      emoji: "🎭",
      heritage: "Cultural Renaissance",
      gradientColors: [Colors.red.shade800, Colors.orange.shade600],
    ),
    StateGround(
      name: "Bihar Ancient Arena",
      stateName: "Bihar",
      entryFee: 160,
      prizePool: 1600,
      primaryColor: Colors.orange,
      secondaryColor: Colors.red,
      emoji: "📚",
      heritage: "Ancient Learning Center",
      gradientColors: [Colors.orange.shade800, Colors.red.shade600],
    ),
    StateGround(
      name: "Telangana Tech Battleground",
      stateName: "Telangana",
      entryFee: 170,
      prizePool: 1700,
      primaryColor: Colors.blue,
      secondaryColor: Colors.purple,
      emoji: "💻",
      heritage: "IT Hub Heritage",
      gradientColors: [Colors.blue.shade800, Colors.purple.shade600],
    ),
    StateGround(
      name: "Karnataka Silicon Arena",
      stateName: "Karnataka",
      entryFee: 180,
      prizePool: 1800,
      primaryColor: Colors.red,
      secondaryColor: Colors.amber,
      emoji: "🏛️",
      heritage: "Garden City Heritage",
      gradientColors: [Colors.red.shade800, Colors.amber.shade600],
    ),
    StateGround(
      name: "Andhra Spice Ground",
      stateName: "Andhra Pradesh",
      entryFee: 190,
      prizePool: 1900,
      primaryColor: Colors.red,
      secondaryColor: Colors.orange,
      emoji: "🌶️",
      heritage: "Spice Heritage",
      gradientColors: [Colors.red.shade800, Colors.orange.shade600],
    ),
    StateGround(
      name: "Tamil Nadu Temple Arena",
      stateName: "Tamil Nadu",
      entryFee: 200,
      prizePool: 2000,
      primaryColor: Colors.red,
      secondaryColor: Colors.orange,
      emoji: "🕉️",
      heritage: "Dravidian Architecture",
      gradientColors: [Colors.red.shade800, Colors.orange.shade600],
    ),
    StateGround(
      name: "Gujarat Business Ground",
      stateName: "Gujarat",
      entryFee: 220,
      prizePool: 2200,
      primaryColor: Colors.orange,
      secondaryColor: Colors.red,
      emoji: "💼",
      heritage: "Business Hub Heritage",
      gradientColors: [Colors.orange.shade800, Colors.red.shade600],
    ),
    StateGround(
      name: "Rajasthan Royal Arena",
      stateName: "Rajasthan",
      entryFee: 250,
      prizePool: 2500,
      primaryColor: Colors.red,
      secondaryColor: Colors.orange,
      emoji: "👑",
      heritage: "Royal Rajput Heritage",
      gradientColors: [Colors.red.shade900, Colors.orange.shade700],
    ),
    StateGround(
      name: "Madhya Pradesh Heart Ground",
      stateName: "Madhya Pradesh",
      entryFee: 280,
      prizePool: 2800,
      primaryColor: Colors.green,
      secondaryColor: Colors.orange,
      emoji: "❤️",
      heritage: "Heart of India",
      gradientColors: [Colors.green.shade800, Colors.orange.shade600],
    ),
    StateGround(
      name: "Maharashtra Commercial Arena",
      stateName: "Maharashtra",
      entryFee: 300,
      prizePool: 3000,
      primaryColor: Colors.orange,
      secondaryColor: Colors.red,
      emoji: "🏢",
      heritage: "Commercial Capital",
      gradientColors: [Colors.orange.shade800, Colors.red.shade600],
    ),
    StateGround(
      name: "Uttar Pradesh Heritage Ground",
      stateName: "Uttar Pradesh",
      entryFee: 350,
      prizePool: 3500,
      primaryColor: Colors.blue,
      secondaryColor: Colors.orange,
      emoji: "🕌",
      heritage: "Taj Mahal Heritage",
      gradientColors: [Colors.blue.shade800, Colors.orange.shade600],
    ),
  ];

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

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _glowController?.dispose();
    _pulseController?.dispose();
    _scaleController?.dispose();
    _cardController?.dispose();
    if (_gameRoomId != null) {
      _leaveGame();
    }
    super.dispose();
  }

  Future<void> _createRoom(StateGround ground) async {
    setState(() {
      _isSearching = true;
      _showGroundSelection = false;
      _selectedGround = ground;
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
        'game_state': 'waiting',
        'winner': null,
        'created_at': FieldValue.serverTimestamp(),
        'round': 1,
        'ground_name': ground.name,
        'entry_fee': ground.entryFee,
        'prize_pool': ground.prizePool,
        'state_name': ground.stateName,
        'heritage': ground.heritage,
      });

      _listenToGameRoom();
    } catch (e) {
      setState(() {
        _isSearching = false;
        _showGroundSelection = true;
      });
      _showError('Failed to create room: $e');
    }
  }

  Future<void> _joinRandomRoom(StateGround ground) async {
    setState(() {
      _isSearching = true;
      _showGroundSelection = false;
      _selectedGround = ground;
    });

    try {
      final availableRooms = await _firestore
          .collection('game_rooms')
          .where('guest_id', isEqualTo: null)
          .where('game_state', isEqualTo: 'waiting')
          .where('ground_name', isEqualTo: ground.name)
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
        await _createRoom(ground);
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
        _showGroundSelection = true;
      });
      _showError('Failed to join room: $e');
    }
  }

  void _listenToGameRoom() {
    if (_gameRoomId == null) return;

    _firestore
        .collection('game_rooms')
        .doc(_gameRoomId)
        .snapshots()
        .listen(
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

              _gameStarted =
                  data['game_state'] == 'playing' && _opponentId != null;
              _isSearching = data['game_state'] == 'waiting';

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

  Widget _buildGroundSelectionScreen() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            '🇮🇳 Choose Your Battleground',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Select a state arena to battle with players across India!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _stateGrounds.length,
              itemBuilder: (context, index) {
                final ground = _stateGrounds[index];
                return _buildGroundCard(ground);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroundCard(StateGround ground) {
    return GestureDetector(
      onTap: () => _joinRandomRoom(ground),
      child: AnimatedBuilder(
        animation: _cardController!,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: ground.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: ground.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(ground.emoji, style: const TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      Text(
                        ground.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ground.heritage,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Entry: ₹${ground.entryFee}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Prize: ₹${ground.prizePool}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              _selectedGround?.gradientColors ?? [Colors.blue, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.1),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _selectedGround?.emoji ?? '🎮',
                    style: const TextStyle(fontSize: 60),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedGround?.name ?? 'Game Arena',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedGround?.heritage ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _pulseController!,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(
                          0.3 + _pulseController!.value * 0.3,
                        ),
                        Colors.white.withOpacity(
                          0.1 + _pulseController!.value * 0.2,
                        ),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
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
              _isHost
                  ? 'Room created! Waiting for player to join...'
                  : 'Looking for available rooms...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Entry Fee: ₹${_selectedGround?.entryFee} | Prize: ₹${_selectedGround?.prizePool}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                if (_gameRoomId != null) {
                  _leaveGame();
                }
                setState(() {
                  _showGroundSelection = true;
                  _isSearching = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              _selectedGround?.gradientColors ?? [Colors.blue, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Ground info header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedGround?.emoji ?? '🎮',
                      style: const TextStyle(fontSize: 30),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            _selectedGround?.name ?? 'Game Arena',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            _selectedGround?.heritage ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        'Entry: ₹${_selectedGround?.entryFee}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        'Prize: ₹${_selectedGround?.prizePool}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Player info bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.person, color: Colors.white, size: 32),
                      const SizedBox(height: 8),
                      const Text(
                        'You',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _auth.currentUser?.email?.split('@')[0] ?? 'Player',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'VS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _opponentName ?? 'Opponent',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Online',
                        style: TextStyle(
                          color: Colors.green.withOpacity(0.8),
                          fontSize: 14,
                        ),
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
                    children: _choices
                        .map((choice) => _buildChoiceButton(choice))
                        .toList(),
                  ),
                ],

                // Waiting for opponent
                if (_playerChoice != null &&
                    _opponentChoice == null &&
                    !_showResult) ...[
                  AnimatedBuilder(
                    animation: _pulseController!,
                    builder: (context, child) {
                      return Column(
                        children: [
                          Icon(
                            Icons.hourglass_empty,
                            size: 60,
                            color: Colors.white.withOpacity(
                              0.7 + _pulseController!.value * 0.3,
                            ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Leave Game',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
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
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(
                      0.2 + _glowController!.value * 0.2,
                    ),
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
            if (_gameResult == 'win') ...[
              const SizedBox(height: 8),
              Text(
                'You won ₹${_selectedGround?.prizePool}!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade300,
                ),
              ),
            ],
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
        title: Text(
          _showGroundSelection
              ? '🇮🇳 Indian Battlegrounds'
              : '🌐 ${_selectedGround?.stateName ?? "Online Multiplayer"}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_gameRoomId != null) {
              _leaveGame();
            }
            if (!_showGroundSelection) {
              setState(() {
                _showGroundSelection = true;
                _isSearching = false;
                _gameStarted = false;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _showGroundSelection
                ? [
                    Colors.deepPurple.shade900,
                    Colors.indigo.shade800,
                    Colors.blue.shade700,
                    Colors.cyan.shade600,
                  ]
                : _selectedGround?.gradientColors ??
                      [Colors.blue, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _showGroundSelection
              ? _buildGroundSelectionScreen()
              : _isSearching && !_gameStarted
              ? _buildWaitingScreen()
              : _gameStarted
              ? _buildGameScreen()
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
        ),
      ),
    );
  }
}

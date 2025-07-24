import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:math';

class GameMultiplayerScreen extends StatefulWidget {
  const GameMultiplayerScreen({super.key});

  @override
  State<GameMultiplayerScreen> createState() => _GameMultiplayerScreenState();
}

class _GameMultiplayerScreenState extends State<GameMultiplayerScreen>
    with TickerProviderStateMixin {
  final List<String> choices = ['Rock', 'Paper', 'Scissors'];
  String? player1Choice;
  String? player2Choice;
  String result = '';
  int player1Score = 0;
  int player2Score = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  AnimationController? _controller;
  AnimationController? _timerController;

  // Turn-based logic variables
  int currentPlayer = 1; // 1 for Player 1, 2 for Player 2
  Timer? _turnTimer;
  Timer? _resultTimer;
  int timeLeft = 10; // 10 seconds per turn
  bool gameActive = false;
  String? lastWinner;
  bool showingResult = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    startNewRound();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _timerController?.dispose();
    _turnTimer?.cancel();
    _resultTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void startNewRound() {
    _resultTimer?.cancel();
    setState(() {
      player1Choice = null;
      player2Choice = null;
      result = '';
      gameActive = true;
      showingResult = false;
      timeLeft = 10;

      // Winner gets next turn first, otherwise Player 1 starts
      if (lastWinner == 'Player 1') {
        currentPlayer = 1;
      } else if (lastWinner == 'Player 2') {
        currentPlayer = 2;
      } else {
        currentPlayer = 1; // Default start
      }
    });
    startTurnTimer();
  }

  void startTurnTimer() {
    _turnTimer?.cancel();
    _timerController?.reset();
    _timerController?.forward();

    setState(() {
      timeLeft = 10;
    });

    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        timeLeft--;
      });

      if (timeLeft <= 0) {
        timer.cancel();
        _timerController?.stop();
        onTimeUp();
      }
    });
  }

  void onTimeUp() {
    if (!gameActive) return;

    // Auto-select random choice for current player
    final randomChoice = choices[Random().nextInt(choices.length)];

    setState(() {
      if (currentPlayer == 1) {
        player1Choice = randomChoice;
      } else {
        player2Choice = randomChoice;
      }
    });

    switchTurn();
  }

  void onPlayerChoice(String choice) {
    if (!gameActive) return;

    _turnTimer?.cancel();
    _timerController?.stop();

    setState(() {
      if (currentPlayer == 1) {
        player1Choice = choice;
      } else {
        player2Choice = choice;
      }
    });

    switchTurn();
  }

  void switchTurn() {
    if (player1Choice != null && player2Choice != null) {
      // Both players have chosen, determine winner
      playRound();
    } else {
      // Switch to other player
      setState(() {
        currentPlayer = currentPlayer == 1 ? 2 : 1;
      });
      startTurnTimer();
    }
  }

  String getChoiceEmoji(String choice) {
    switch (choice) {
      case 'Rock':
        return '🪨';
      case 'Paper':
        return '📄';
      case 'Scissors':
        return '✂️';
      default:
        return '❓';
    }
  }

  void playRound() async {
    setState(() {
      gameActive = false;
      showingResult = true;
    });

    if (player1Choice != null && player2Choice != null) {
      String res;
      String? roundWinner;

      if (player1Choice == player2Choice) {
        res = "It's a Draw!";
        roundWinner = null;
        try {
          await _audioPlayer.play(AssetSource('draw.mp3'));
        } catch (e) {
          print('Audio file not found: draw.mp3');
        }
      } else if ((player1Choice == 'Rock' && player2Choice == 'Scissors') ||
          (player1Choice == 'Paper' && player2Choice == 'Rock') ||
          (player1Choice == 'Scissors' && player2Choice == 'Paper')) {
        res = "Player 1 Wins!";
        roundWinner = 'Player 1';
        player1Score++;
        try {
          await _audioPlayer.play(AssetSource('win.mp3'));
        } catch (e) {
          print('Audio file not found: win.mp3');
        }
      } else {
        res = "Player 2 Wins!";
        roundWinner = 'Player 2';
        player2Score++;
        try {
          await _audioPlayer.play(AssetSource('lose.mp3'));
        } catch (e) {
          print('Audio file not found: lose.mp3');
        }
      }

      setState(() {
        result = res;
        lastWinner = roundWinner;
      });

      // Auto-start next round after 3 seconds
      _resultTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          startNewRound();
        }
      });
    }
  }

  void resetGame() {
    _turnTimer?.cancel();
    _resultTimer?.cancel();
    _timerController?.stop();
    setState(() {
      player1Choice = null;
      player2Choice = null;
      result = '';
      player1Score = 0;
      player2Score = 0;
      gameActive = false;
      showingResult = false;
      currentPlayer = 1;
      lastWinner = null;
      timeLeft = 10;
    });
  }

  Widget buildTurnIndicator() {
    if (!gameActive) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      color: currentPlayer == 1 ? Colors.blue.shade100 : Colors.red.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  currentPlayer == 1 ? Icons.person : Icons.person_outline,
                  color: currentPlayer == 1 ? Colors.blue : Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  "Player ${currentPlayer}'s Turn",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: currentPlayer == 1
                        ? Colors.blue.shade800
                        : Colors.red.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: timeLeft <= 3
                    ? Colors.red.shade100
                    : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: timeLeft <= 3 ? Colors.red : Colors.orange,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer,
                    color: timeLeft <= 3 ? Colors.red : Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$timeLeft seconds left',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: timeLeft <= 3
                          ? Colors.red.shade800
                          : Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: timeLeft / 10,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  timeLeft <= 3
                      ? Colors.red
                      : timeLeft <= 5
                      ? Colors.orange
                      : Colors.green,
                ),
              ),
            ),
            if (timeLeft <= 3)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Hurry up! Time is running out!',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildChoiceButton(String choice, int player) {
    bool isPlayerTurn = gameActive && currentPlayer == player;
    bool hasChosen =
        (player == 1 && player1Choice != null) ||
        (player == 2 && player2Choice != null);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isPlayerTurn && !hasChosen
                ? () => onPlayerChoice(choice)
                : null,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPlayerTurn && !hasChosen
                      ? Colors.blue
                      : Colors.grey.shade300,
                  width: isPlayerTurn && !hasChosen ? 2 : 1,
                ),
                color: hasChosen
                    ? Colors.green.shade100
                    : isPlayerTurn
                    ? Colors.blue.shade50
                    : Colors.grey.shade100,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _controller!,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: isPlayerTurn && !hasChosen
                            ? 1.0 + (_controller!.value * 0.1)
                            : 1.0,
                        child: Text(
                          getChoiceEmoji(choice),
                          style: TextStyle(
                            fontSize: 40,
                            color: isPlayerTurn && !hasChosen
                                ? Colors.black
                                : Colors.grey.shade600,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    choice,
                    style: TextStyle(
                      fontSize: 12,
                      color: isPlayerTurn && !hasChosen
                          ? Colors.black
                          : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPlayerSection(int player) {
    bool isPlayerTurn = gameActive && currentPlayer == player;
    bool hasChosen =
        (player == 1 && player1Choice != null) ||
        (player == 2 && player2Choice != null);
    String playerName = 'Player $player';

    String statusText;
    Color statusColor;

    if (showingResult) {
      statusText = 'Round Complete';
      statusColor = Colors.purple;
    } else if (!gameActive) {
      statusText = 'Game Paused';
      statusColor = Colors.grey;
    } else if (hasChosen) {
      statusText = 'Choice Made! ✓';
      statusColor = Colors.green;
    } else if (isPlayerTurn) {
      statusText = 'Your Turn! Make a choice';
      statusColor = Colors.blue;
    } else {
      // Show specific waiting message
      int otherPlayer = player == 1 ? 2 : 1;
      statusText = 'Wait for Player $otherPlayer...';
      statusColor = Colors.orange;
    }

    return Card(
      elevation: isPlayerTurn ? 6 : 2,
      color: isPlayerTurn ? Colors.blue.shade50 : Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  playerName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isPlayerTurn ? Colors.blue : Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Show choices or waiting message
            if (isPlayerTurn && !hasChosen) ...[
              // Show active choices for current player
              Row(
                children: choices
                    .map((choice) => buildChoiceButton(choice, player))
                    .toList(),
              ),
            ] else if (hasChosen && !showingResult) ...[
              // Show secret choice indicator (don't reveal the actual choice)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Column(
                  children: [
                    Icon(Icons.lock, size: 40, color: Colors.green.shade700),
                    const SizedBox(height: 8),
                    Text(
                      'Choice Locked In',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Secret until reveal',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (showingResult && hasChosen) ...[
              // Show revealed choice during result phase
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      getChoiceEmoji(
                        player == 1 ? player1Choice! : player2Choice!,
                      ),
                      style: const TextStyle(fontSize: 50),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${player == 1 ? player1Choice! : player2Choice!}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Show waiting state with disabled choices
              Container(
                height: 100,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        size: 30,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        showingResult
                            ? 'Next round starting...'
                            : 'Waiting for Player ${currentPlayer}...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
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
      appBar: AppBar(
        title: const Text('Turn-Based Multiplayer'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Turn Indicator
            buildTurnIndicator(),

            const SizedBox(height: 20),

            // Player 1 Section
            buildPlayerSection(1),

            const SizedBox(height: 20),

            // VS Divider
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'VS',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 20),

            // Player 2 Section
            buildPlayerSection(2),

            const SizedBox(height: 30),

            // Result Section - Only show during result phase
            if (showingResult && result.isNotEmpty)
              Card(
                color: result.contains('Draw')
                    ? Colors.orange.shade100
                    : result.contains('Player 1')
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        result,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              const Text(
                                'Player 1',
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                getChoiceEmoji(player1Choice ?? ''),
                                style: const TextStyle(fontSize: 30),
                              ),
                              Text(
                                player1Choice ?? '',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                          const SizedBox(width: 40),
                          const Text(
                            'VS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 40),
                          Column(
                            children: [
                              const Text(
                                'Player 2',
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                getChoiceEmoji(player2Choice ?? ''),
                                style: const TextStyle(fontSize: 30),
                              ),
                              Text(
                                player2Choice ?? '',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade200,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Text(
                          'Next round starts automatically in 3 seconds...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (lastWinner != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.blue.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.emoji_events,
                                  color: Colors.blue.shade700,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$lastWinner goes first next round!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Score Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Player 1',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$player1Score',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Player 2',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$player2Score',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Action Buttons - Only show reset game button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: resetGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Reset Game', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

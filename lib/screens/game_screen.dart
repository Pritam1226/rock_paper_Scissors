import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../models/move.dart';
import '../widgets/move_buttons.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Move? playerMove;
  Move? computerMove;
  int playerScore = 0;
  int computerScore = 0;
  String result = '';
  final AudioPlayer _player = AudioPlayer();

  void playGame(Move selectedMove) {
    final random = Random();
    final computer = Move.values[random.nextInt(Move.values.length)];
    String outcome;

    if (selectedMove == computer) {
      outcome = 'It\'s a Draw!';
    } else if ((selectedMove == Move.rock && computer == Move.scissors) ||
        (selectedMove == Move.paper && computer == Move.rock) ||
        (selectedMove == Move.scissors && computer == Move.paper)) {
      outcome = 'You Win!';
      playerScore++;
    } else {
      outcome = 'You Lose!';
      computerScore++;
    }

    _playSound(outcome);

    setState(() {
      playerMove = selectedMove;
      computerMove = computer;
      result = outcome;
    });
  }

  void _playSound(String result) async {
    String asset = '';
    if (result.contains('Win')) {
      asset = 'assets/win.mp3';
    } else if (result.contains('Lose')) {
      asset = 'assets/lose.mp3';
    } else {
      asset = 'assets/draw.mp3';
    }
    await _player.play(AssetSource(asset));
  }

  void resetGame() {
    setState(() {
      playerMove = null;
      computerMove = null;
      playerScore = 0;
      computerScore = 0;
      result = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Play vs Computer'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: resetGame),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'You: $playerScore | Computer: $computerScore',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose your move:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            MoveButtons(onMoveSelected: playGame),
            const SizedBox(height: 30),
            if (playerMove != null && computerMove != null)
              Column(
                children: [
                  Text(
                    'Your Move: ${moveToEmoji(playerMove)}',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Computer: ${moveToEmoji(computerMove)}',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    result,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: result.contains('Win')
                          ? Colors.green
                          : result.contains('Lose')
                          ? Colors.red
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

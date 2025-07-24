import 'package:flutter/material.dart';
import '../models/move.dart';

class MoveButtons extends StatelessWidget {
  final Function(Move) onMoveSelected;

  const MoveButtons({super.key, required this.onMoveSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: Move.values.map((move) {
        return GestureDetector(
          onTap: () => onMoveSelected(move),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(moveToEmoji(move), style: const TextStyle(fontSize: 20)),
          ),
        );
      }).toList(),
    );
  }
}

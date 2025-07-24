enum Move { rock, paper, scissors }

String moveToEmoji(Move? move) {
  switch (move) {
    case Move.rock:
      return '🪨 Rock';
    case Move.paper:
      return '📄 Paper';
    case Move.scissors:
      return '✂️ Scissors';
    default:
      return '';
  }
}

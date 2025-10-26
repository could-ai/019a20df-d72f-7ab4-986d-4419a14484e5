enum Suit { hearts, diamonds, clubs, spades }

enum Rank { two, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace }

extension SuitExtension on Suit {
  String toSymbol() {
    switch (this) {
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
      case Suit.clubs:
        return '♣';
      case Suit.spades:
        return '♠';
    }
  }
}

extension RankExtension on Rank {
  String toShortString() {
    switch (this) {
      case Rank.two: return '2';
      case Rank.three: return '3';
      case Rank.four: return '4';
      case Rank.five: return '5';
      case Rank.six: return '6';
      case Rank.seven: return '7';
      case Rank.eight: return '8';
      case Rank.nine: return '9';
      case Rank.ten: return '10';
      case Rank.jack: return 'J';
      case Rank.queen: return 'Q';
      case Rank.king: return 'K';
      case Rank.ace: return 'A';
    }
  }
}

class PlayingCard {
  final Suit suit;
  final Rank rank;

  PlayingCard({required this.suit, required this.rank});

  @override
  String toString() {
    return '${rank.toShortString()}${suit.toSymbol()}';
  }
}

class Player {
  final int id;
  final bool isHuman;
  final String name;
  final List<PlayingCard> hand = [];
  int tricksWon = 0;
  int totalScore = 0;

  Player({required this.id, required this.isHuman, required this.name});
}

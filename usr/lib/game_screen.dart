import 'package:flutter/material.dart';
import 'models.dart';
import 'dart:math';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final List<Player> _players = [];
  List<PlayingCard> _deck = [];
  final List<Map<int, PlayingCard>> _tricks = [];
  Map<int, PlayingCard> _currentTrick = {};
  int _currentPlayerIndex = 0;
  int _trickStarterIndex = 0;
  Suit? _leadSuit;
  final Suit _trumpSuit = Suit.spades;
  bool _roundOver = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    _players.clear();
    _players.add(Player(id: 0, isHuman: true, name: "Player 1"));
    _players.add(Player(id: 1, isHuman: false, name: "Player 2"));
    _players.add(Player(id: 2, isHuman: false, name: "Player 3"));
    _players.add(Player(id: 3, isHuman: false, name: "Player 4"));
    _startNewRound();
  }

  void _startNewRound() {
    setState(() {
      _deck = _createDeck();
      _deck.shuffle();
      _dealCards();
      _tricks.clear();
      _currentTrick.clear();
      _leadSuit = null;
      _roundOver = false;
      for (var player in _players) {
        player.tricksWon = 0;
      }
      // Player 1 (human) always starts the first trick of a round
      _currentPlayerIndex = 0;
      _trickStarterIndex = 0;
    });
  }

  List<PlayingCard> _createDeck() {
    List<PlayingCard> deck = [];
    for (var suit in Suit.values) {
      for (var rank in Rank.values) {
        deck.add(PlayingCard(suit: suit, rank: rank));
      }
    }
    return deck;
  }

  void _dealCards() {
    for (var player in _players) {
      player.hand.clear();
    }
    int playerIndex = 0;
    for (var card in _deck) {
      _players[playerIndex].hand.add(card);
      playerIndex = (playerIndex + 1) % 4;
    }
    // Sort the human player's hand for better UI
    _players[0].hand.sort((a, b) {
      if (a.suit.index != b.suit.index) {
        return a.suit.index.compareTo(b.suit.index);
      } else {
        return b.rank.index.compareTo(a.rank.index);
      }
    });
  }

  void _playCard(PlayingCard card) {
    if (_roundOver || !_players[_currentPlayerIndex].isHuman) return;

    if (_isValidPlay(card)) {
      setState(() {
        _players[_currentPlayerIndex].hand.remove(card);
        _currentTrick[_currentPlayerIndex] = card;

        if (_currentTrick.length == 1) {
          _leadSuit = card.suit;
        }

        _currentPlayerIndex = (_currentPlayerIndex + 1) % 4;
      });

      if (_currentTrick.length < 4) {
        // Trigger bot plays
        Future.delayed(const Duration(milliseconds: 500), _playBotTurns);
      } else {
        // End of trick
        Future.delayed(const Duration(milliseconds: 1000), _endTrick);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid move!"), duration: Duration(seconds: 1)),
      );
    }
  }

  bool _isValidPlay(PlayingCard card) {
    final playerHand = _players[_currentPlayerIndex].hand;
    if (_leadSuit == null) return true; // Can lead with any card

    bool hasLeadSuit = playerHand.any((c) => c.suit == _leadSuit);
    if (hasLeadSuit) {
      return card.suit == _leadSuit;
    }
    return true; // If no lead suit, any card is valid
  }

  void _playBotTurns() {
    if (_roundOver || _players[_currentPlayerIndex].isHuman) return;

    PlayingCard cardToPlay = _getBotCard();

    setState(() {
      _players[_currentPlayerIndex].hand.remove(cardToPlay);
      _currentTrick[_currentPlayerIndex] = cardToPlay;

      if (_currentTrick.length == 1) {
        _leadSuit = cardToPlay.suit;
      }

      _currentPlayerIndex = (_currentPlayerIndex + 1) % 4;
    });

    if (_currentTrick.length < 4) {
      Future.delayed(const Duration(milliseconds: 500), _playBotTurns);
    } else {
      Future.delayed(const Duration(milliseconds: 1000), _endTrick);
    }
  }

  PlayingCard _getBotCard() {
    final bot = _players[_currentPlayerIndex];
    List<PlayingCard> validPlays = [];

    if (_leadSuit == null) {
      // Bot is leading the trick, play a random card
      return bot.hand[Random().nextInt(bot.hand.length)];
    }

    // Follow lead suit if possible
    validPlays = bot.hand.where((c) => c.suit == _leadSuit).toList();
    if (validPlays.isNotEmpty) {
      // Simple AI: play the highest card of the lead suit
      validPlays.sort((a, b) => b.rank.index.compareTo(a.rank.index));
      return validPlays.first;
    }

    // If cannot follow suit, try to play a trump card
    validPlays = bot.hand.where((c) => c.suit == _trumpSuit).toList();
    if (validPlays.isNotEmpty) {
      // Simple AI: play the highest trump
      validPlays.sort((a, b) => b.rank.index.compareTo(a.rank.index));
      return validPlays.first;
    }

    // If no lead suit and no trump, play a random card (lowest rank)
    bot.hand.sort((a, b) => a.rank.index.compareTo(b.rank.index));
    return bot.hand.first;
  }

  void _endTrick() {
    setState(() {
      int winnerIndex = _trickStarterIndex;
      PlayingCard winningCard = _currentTrick[winnerIndex]!;

      for (int i = 1; i < 4; i++) {
        int playerIndex = (_trickStarterIndex + i) % 4;
        PlayingCard playerCard = _currentTrick[playerIndex]!;

        if (playerCard.suit == winningCard.suit) {
          if (playerCard.rank.index > winningCard.rank.index) {
            winnerIndex = playerIndex;
            winningCard = playerCard;
          }
        } else if (playerCard.suit == _trumpSuit && winningCard.suit != _trumpSuit) {
          winnerIndex = playerIndex;
          winningCard = playerCard;
        }
      }

      _players[winnerIndex].tricksWon++;
      _tricks.add(Map.from(_currentTrick));
      _currentTrick.clear();
      _leadSuit = null;
      _currentPlayerIndex = winnerIndex;
      _trickStarterIndex = winnerIndex;

      if (_tricks.length == 13) {
        _endRound();
      } else {
        // If the winner is a bot, start the next trick automatically
        if (!_players[_currentPlayerIndex].isHuman) {
          Future.delayed(const Duration(milliseconds: 1000), _playBotTurns);
        }
      }
    });
  }

  void _endRound() {
    setState(() {
      for (var player in _players) {
        player.totalScore += player.tricksWon;
      }
      _roundOver = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Break'),
        actions: [
          TextButton(
            onPressed: _startNewRound,
            child: const Text(
              'New Round',
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      body: Container(
        color: Colors.green[800],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPlayerArea(_players[2], isTop: true),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPlayerArea(_players[1]),
                  _buildTableArea(),
                  _buildPlayerArea(_players[3]),
                ],
              ),
            ),
            _buildPlayerArea(_players[0], isHuman: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerArea(Player player, {bool isHuman = false, bool isTop = false}) {
    final isCurrentPlayer = _players[_currentPlayerIndex].id == player.id;
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: isCurrentPlayer ? Border.all(color: Colors.yellow, width: 3) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${player.name} (Score: ${player.totalScore})',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            'Tricks Won: ${player.tricksWon}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          if (isHuman)
            _buildHumanHand(player.hand)
          else
            _buildBotHand(player, isTop),
        ],
      ),
    );
  }

  Widget _buildHumanHand(List<PlayingCard> hand) {
    return Wrap(
      spacing: 4.0,
      runSpacing: 4.0,
      children: hand.map((card) {
        return GestureDetector(
          onTap: () => _playCard(card),
          child: CardWidget(card: card),
        );
      }).toList(),
    );
  }

  Widget _buildBotHand(Player player, bool isTop) {
    // To keep bot card positions consistent, we use Stack with positioned CardWidgets
    return SizedBox(
      width: 150,
      height: 80,
      child: Stack(
        children: List.generate(player.hand.length, (index) {
          return Positioned(
            left: index * 10.0,
            child: CardWidget(isFaceDown: true),
          );
        }),
      ),
    );
  }

  Widget _buildTableArea() {
    return Container(
      width: 200,
      height: 150,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white54),
        borderRadius: BorderRadius.circular(10),
      ),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          // This maps grid position to player index
          int playerIndex;
          switch (index) {
            case 0: playerIndex = 2; break; // Top
            case 1: playerIndex = 3; break; // Right
            case 2: playerIndex = 1; break; // Left
            case 3: playerIndex = 0; break; // Bottom
            default: playerIndex = 0;
          }
          final card = _currentTrick[playerIndex];
          if (card != null) {
            return Center(child: CardWidget(card: card));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class CardWidget extends StatelessWidget {
  final PlayingCard? card;
  final bool isFaceDown;

  const CardWidget({super.key, this.card, this.isFaceDown = false});

  @override
  Widget build(BuildContext context) {
    if (isFaceDown) {
      return Container(
        width: 50,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.blueGrey,
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Center(
          child: Icon(Icons.style, color: Colors.white70),
        ),
      );
    }

    final cardColor = (card!.suit == Suit.hearts || card!.suit == Suit.diamonds)
        ? Colors.red
        : Colors.black;

    return Container(
      width: 50,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: Text(
          '${card!.rank.toShortString()}\n${card!.suit.toSymbol()}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: cardColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

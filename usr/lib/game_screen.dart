import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Game'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Implement new game functionality
            },
            child: const Text(
              'New Game',
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      body: Container(
        color: Colors.green[800],
        child: const Center(
          child: Text(
            'Game Board - Coming Soon!',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

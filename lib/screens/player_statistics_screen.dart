
import 'package:flutter/material.dart';

class PlayerStatisticScreen extends StatefulWidget {
  const PlayerStatisticScreen({super.key});

  @override
  State<PlayerStatisticScreen> createState() => _PlayerStatisticScreenState();
}

class _PlayerStatisticScreenState extends State<PlayerStatisticScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Statistics")),
      body: const Center(child: Text("Player Statistics Screen")),
      //TODO: store, calculate and display player statistics,
    );
  }
}
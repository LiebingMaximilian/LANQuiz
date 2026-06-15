import 'package:flutter/material.dart';
import 'package:lan_quiz/gameState/host_game_state.dart';
import 'package:provider/provider.dart';
import '../gameState/base_game_state.dart';
import '../gameState/host_game_state.dart';


class PlayerManagementScreen extends StatefulWidget {
  const PlayerManagementScreen({super.key});

  @override
  State<PlayerManagementScreen> createState() => _PlayerManagementScreenState();
}

class _PlayerManagementScreenState extends State<PlayerManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Player Management")),
      body: const Center(child: Text("Player Management Screen")),
      //TODO: Add list of connected players with option to kick them, maybe also show their IPs and names
    );
  }
}
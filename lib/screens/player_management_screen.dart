import 'package:flutter/material.dart';
import 'package:lan_quiz/gameState/host_game_state.dart';
import 'package:provider/provider.dart';

class PlayerManagementScreen extends StatelessWidget {
  const PlayerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HostGameState>(
      builder: (context, gameState, child) {
        final players = gameState.playerManager.players.where((p) => p.id != gameState.myId).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text("Player Management"),
          ),
          body: players.isEmpty
              ? const Center(
                  child: Text("No players connected"),
                )
              : ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];

                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(player.name),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.person_remove,
                          color: Colors.red,
                        ),
                        tooltip: "Kick player",
                        onPressed: () {
                          gameState.kickPlayer(player.id);
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lan_quiz/player_data.dart';

class PlayerManager {
  List<PlayerData> players = [];

  void addPlayer(String name, String id) {
    if (!players.any((p) => p.id == id)) {
      players.add(PlayerData(name: name, id: id, score: 0));
    }
  }
  
  void increaseScore(String id) {
    PlayerData? player = players.firstWhere((p) => p.id == id, orElse: () => throw Exception('Player not found'));
    if (player != null) {
      player.score += 1;
    } 
    else {
      players.add(PlayerData(name: "Unknown", id: id, score: 1));
    }
  }

  void removePlayer(String id) {
    players.removeWhere((p) => p.id == id);
  }

  String? getNameById(String id) {
    PlayerData? player = players.firstWhere((p) => p.id == id, orElse: () => throw Exception('Player not found'));
    return player?.name;
  }

  void reset() {
    players.clear();
  }

  bool hasPlayer(String id) {
    return players.any((p) => p.id == id);
  }
}
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lan_quiz/host.dart';
import 'package:lan_quiz/player_data.dart';
import 'package:lan_quiz/screens/global_settings_screen.dart';

class PlayerManager {
  List<PlayerData> players = [];

  void addPlayer(String name, String id, {WebSocket? socket}) {
    if (!players.any((p) => p.id == id)) {
      players.add(PlayerData(name: name, id: id, score: 0, socket: socket));
    }
  }
  
  void increaseScore(String id) {
    PlayerData? player = players.firstWhere((p) => p.id == id, orElse: () => throw Exception('Player not found'));
    if (player != null) {
      player.score += 1;
    } 
  }

  void decreaseScore(String id) {
    PlayerData? player = players.firstWhere((p) => p.id == id, orElse:  () => throw Exception('Player not found'));
    if(player != null){
      player.score -= 1;
    }
  }

  void resetScores(){
    for(var player in players){
      player.score = 0;
    }
  }

  void removePlayer(String id) {
    players.removeWhere((p) => p.id == id);
  }

  String? getNameById(String id) {
    PlayerData? player = players.firstWhere((p) => p.id == id, orElse: () => throw Exception('Player not found'));
    return player?.name;
  }

  void removePlayerBySocket(WebSocket socket){
    players.removeWhere((p) => p.socket == socket);
  }

  void reset() {
    players.clear();
  }

  bool hasPlayer(String id) {
    return players.any((p) => p.id == id);
  }

  void kick(String id) {
    kickPlayer(id);
    removePlayer(id);
  }
}
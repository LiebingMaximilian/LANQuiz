import 'dart:io';

class PlayerData {
  String name;
  String id;
  int score;
  WebSocket? socket; // Add socket reference to PlayerData

  PlayerData({required this.name, required this.id, required this.score,required this.socket});
}
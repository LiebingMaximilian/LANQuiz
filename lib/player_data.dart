import 'dart:io';
import 'package:lan_quiz/enums/joker_type.dart';

class PlayerData {
  String name;
  String id;
  int score;
  WebSocket? socket; // Add socket reference to PlayerData
  Set<JokerType> usedJokers = {};

  PlayerData({required this.name, required this.id, required this.score,required this.socket});
}
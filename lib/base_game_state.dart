import 'package:flutter/material.dart';
import 'package:lan_quiz/leaderboard.dart';
import 'package:lan_quiz/main.dart';
import 'classes.dart';

abstract class BaseGameState extends ChangeNotifier {
  // Shared UI state variables
  bool isPlaying = false;
  bool showLeaderboard = false;
  int currentRound = 1;
  int totalRounds = 10;
  int answerTimeLimit = 20;
  String currentQuestion = "";
  List<String> currentAnswers = [];
  String myName = "Spieler ${DateTime.now().millisecond % 1000}";
  Map<String, dynamic> scores = {};
  Set<JokerType> myUsedJokers = {};
  bool isWaitingForJoker = false;
  Mode mode = Mode.none;
  String? localIp;

  // Shared interface that both components implement
  void processNetworkMessage(String msg);
}
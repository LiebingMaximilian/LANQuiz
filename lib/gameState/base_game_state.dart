import 'package:flutter/material.dart';
import 'package:lan_quiz/enums/Mode.dart';
import 'package:lan_quiz/enums/joker_type.dart';
import 'package:lan_quiz/enums/uiState.dart';
import 'package:lan_quiz/screens/leaderboard_screen.dart';
import 'package:lan_quiz/main.dart';
import '../client_question.dart';

abstract class BaseGameState extends ChangeNotifier {
  // Shared UI state variables
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
  UiState uiState = UiState.home;

  // Shared interface that both components implement
  void processNetworkMessage(String msg);
}
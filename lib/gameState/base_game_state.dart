import 'package:flutter/material.dart';
import 'package:lan_quiz/enums/Mode.dart';
import 'package:lan_quiz/enums/quiz_phase.dart';
import 'package:lan_quiz/enums/joker_type.dart';
import 'package:lan_quiz/enums/ui_state.dart';
import 'package:lan_quiz/player_manager.dart';
import 'package:lan_quiz/screens/leaderboard_screen.dart';
import 'package:uuid/uuid.dart';

abstract class BaseGameState extends ChangeNotifier {
  // Shared UI state variables
  int currentRound = 1;
  int totalRounds = 10;
  int answerTimeLimit = 20;
  String currentQuestion = "";
  List<String> currentAnswers = [];
  String currentCategory = "";
  String myName = "Spieler ${DateTime.now().millisecond % 1000}";
  String myId = Uuid().v4();
  PlayerManager playerManager = PlayerManager();
  Set<JokerType> myUsedJokers = {};
  bool isWaitingForJoker = false;
  Mode mode = Mode.none;
  String? localIp;
  UiState uiState = UiState.home;
  QuizPhase quizPhase = QuizPhase.answering;
  int correctAnswerIndex = -1;
  Map<String,String> playerAnswersThisRound = {}; // saves player id -> Answer
  bool unlockAnswer = false;
  bool isPaused = false;
  List<LeaderboardEntry> leaderboardEntries = [];
  int leaderboardTimeLimit = 5;
  bool isFinalLeaderboard = false;

  // Shared interface that both components implement
  void processNetworkMessage(String msg);
}
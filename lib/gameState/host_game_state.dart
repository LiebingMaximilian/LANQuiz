import 'dart:async';
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/material.dart';
import 'package:lan_quiz/gameState/base_game_state.dart';
import 'package:lan_quiz/gameState/client_game_state.dart'; // Ensure correct import matching filename
import 'package:lan_quiz/screens/leaderboard_screen.dart';
import 'package:web_socket_channel/io.dart';
import '../host.dart';
import '../main.dart';
import 'dart:convert';
import '../classes.dart';
import '../api_connector.dart';

class HostGameState extends ClientGameState { //extending clientgamestate means host is client and host in one, which is what we want
  int _correctAnswerIndex = 0;
  int _answersReceivedThisRound = 0;
  Map<String, Set<JokerType>> usedJokers = {};
  BonsoirBroadcast? _broadcast;

  Future<void> setup() async {
    // Optional placeholder setup lifecycle hook called from GameController
    await hostGame();
  }

  Future<void> hostGame() async {
    _broadcast = await startBroadcast();
    
    startSocketServer(
      onMessageReceived: (incomingText) {
        processNetworkMessage(incomingText);
      },
    );

    localIp = await getLocalIpAddress();
    print("Hosting on ip: " + localIp!);

    //here we join our own game
    await super.joinGame(localIp!);
    //important to override it here, as we set it in joinGame
    mode = Mode.host;
    uiState = UiState.hostLobby;

    notifyListeners();
  }

  Future<void> startGame(int rounds, int timeLimit) async {
    if (mode != Mode.host) return;

    scores[myName] = scores[myName] ?? 0;
    totalRounds = rounds;
    currentRound = 1;
    answerTimeLimit = timeLimit;

    await sendQuestion();
  }

  Future<void> sendQuestion() async {
    final ClientQuestion clientQuestion = await _getQuestionForRound();
    _correctAnswerIndex = clientQuestion.correctIndex;
    _answersReceivedThisRound = 0;
    
    final startGamePacket = StartRoundPacket(
      round: currentRound, 
      rounds: totalRounds, 
      timeLimit: answerTimeLimit, 
      question: clientQuestion.question, 
      answers: clientQuestion.answers
    );
    broadcastCommand(jsonEncode(startGamePacket. toJson()));
  }

  Future<ClientQuestion> _getQuestionForRound() async {
    Question question = await fetchQuestion();
    ClientQuestion clientQuestion = ClientQuestion.QuestionToClientQuestion(question);
    return clientQuestion;
  }

  void handleJokerRequest(Packet packet) {
    final request = packet as JokerRequestPacket;
    String pName = request.playerName;
    
    usedJokers.putIfAbsent(pName, () => <JokerType>{});
    if (usedJokers[pName]!.contains(request.jokerType)) return;
    
    usedJokers[pName]!.add(request.jokerType);
    
    switch (request.jokerType) {
      case JokerType.FIFTY_FIFTY:
        List<int> wrongIndices = [];
        for (int i = 0; i < currentAnswers.length; i++) {
          if (i != _correctAnswerIndex) {
            wrongIndices.add(i);
          }
        }
        wrongIndices.shuffle();
    
        final response = JokerResponsePacket(
          targetPlayerName: pName,
          answersToHide: [wrongIndices[0], wrongIndices[1]],
          jokerType: request.jokerType,
        );
    
        broadcastCommand(jsonEncode(response.toJson()));
        break;
    }
  }

  void endGame() {
    print("game ending...");

    final endPacket = ShowLeaderboardPacket(
        time: 0,
        entries: scoresToLeaderboard(scores),
        isFinalLeaderboard: true);

    broadcastCommand(jsonEncode(endPacket.toJson()));
    usedJokers.clear();
    
    _broadcast?.stop();
    _broadcast = null;

    stopSocketServer();

    scores.clear();
    notifyListeners();
  }

  Future<void> restartGame() async {
    if (mode != Mode.host) return;

    print("game restarting...");
    usedJokers.clear();
    scores.clear();
    _answersReceivedThisRound = 0;
    currentRound = 1;

    await sendQuestion();
  }

  void broadcastCommand(String jsonMessage) {
    if (mode == Mode.host) {
      broadcastToAll(jsonMessage);
    }
  }

  @override
  Future<void> processNetworkMessage(String msg) async {
    print("Host Server received: $msg");
    try {
      final packet = Packet.fromJson(jsonDecode(msg));
      if (packet.type == PacketType.SUBMIT_ANSWER && mode == Mode.host) {
        await handleAnswer(packet);
      } else if (packet.type == PacketType.JOKER_REQUEST && mode == Mode.host) {
        handleJokerRequest(packet as JokerRequestPacket);
      }
      else {
        //go to client 
        super.processNetworkMessage(msg);
      }
    } catch (e) {
      print("Error Host Gameloop: $e");
    }
  }

  Future<void> handleAnswer(Packet packet) async {
    final submitAnswerPacket = packet as SubmitAnswerPacket;
    String pName = submitAnswerPacket.playerName ?? "Unknown";
    String answer = submitAnswerPacket.answer ?? "";
    
    if (answer == currentAnswers[_correctAnswerIndex]) {
      scores[pName] = (scores[pName] ?? 0) + 1;
    } else {
      scores[pName] = scores[pName] ?? 0;
    }
    _answersReceivedThisRound++;
    
    if (_answersReceivedThisRound >= clientCount) {
      _answersReceivedThisRound = -999;
      if (currentRound < totalRounds) {
        Future.delayed(const Duration(seconds: 2), () async {
          await showLeaderboardForXSeconds(5, false);
          currentRound++;
          await sendQuestion();
        });
      } else {
        print("Game is over");
        await showLeaderboardForXSeconds(20, true);
      }
    }
  }

  Future<void> showLeaderboardForXSeconds(int seconds, bool isFinalLeaderboard) async {
    List<LeaderboardEntry> entries = scoresToLeaderboard(scores);
    ShowLeaderboardPacket showLeaderboardPacket = ShowLeaderboardPacket(
      time: seconds, 
      entries: entries, 
      isFinalLeaderboard: isFinalLeaderboard
    );
    broadcastCommand(jsonEncode(showLeaderboardPacket.toJson()));
    await Future.delayed(Duration(seconds: seconds));
  }

  List<LeaderboardEntry> scoresToLeaderboard(Map<String, dynamic> scores) {
    return scores.entries
        .map((e) => LeaderboardEntry(name: e.key, score: e.value as int))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
  }

  @override
  void dispose() {
    _broadcast?.stop();
    super.dispose();
  }
}
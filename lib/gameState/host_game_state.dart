import 'dart:async';
import 'dart:io';
import 'package:bonsoir/bonsoir.dart';
import 'package:lan_quiz/enums/Mode.dart';
import 'package:lan_quiz/enums/joker_type.dart';
import 'package:lan_quiz/enums/packet_type.dart';
import 'package:lan_quiz/enums/ui_state.dart';
import 'package:lan_quiz/gameState/client_game_state.dart'; // Ensure correct import matching filename
import 'package:lan_quiz/packets/base_packet.dart';
import 'package:lan_quiz/packets/joker_request_packet.dart';
import 'package:lan_quiz/packets/joker_response_packet.dart';
import 'package:lan_quiz/packets/register_packet.dart';
import 'package:lan_quiz/packets/show_leaderboard_packet.dart';
import 'package:lan_quiz/packets/start_round_packet.dart';
import 'package:lan_quiz/packets/submit_answer_packet.dart';
import 'package:lan_quiz/player_data.dart';
import 'package:lan_quiz/screens/leaderboard_screen.dart';
import '../host.dart';
import 'dart:convert';
import '../client_question.dart';
import '../api_connector.dart';
import '../packets/show_correct_answer_packet.dart';

class HostGameState extends ClientGameState { //extending client_game_state means host is client and host in one, which is what we want
  int _correctAnswerIndex = 0;
  int _answersReceivedThisRound = 0;
  Map<String, Set<JokerType>> usedJokers = {};
  BonsoirBroadcast? _broadcast;
  final Map<String,String> _answersThisRoundMap = {};
  int? categoryId; //null is all categories 

  Future<void> setup() async {
    // Optional placeholder setup lifecycle hook called from GameController
    await hostGame();
  }

  Future<void> hostGame() async {
    _broadcast = await startBroadcast();
    
    startSocketServer(
      onMessageReceived: (socket, data) {
        preProcessNetworkMessage(socket, data);
      },
    );

    localIp = await getLocalIpAddress();
    print("Hosting on ip: ${localIp!}");

    //here we join our own game
    await super.joinGame(localIp!);
    //important to override it here, as we set it in joinGame
    mode = Mode.host;
    uiState = UiState.hostLobby;

    notifyListeners();
  }

  Future<void> startGame(int rounds, int timeLimit) async {
    if (mode != Mode.host) return;

    
    totalRounds = rounds;
    currentRound = 1;
    answerTimeLimit = timeLimit;

    await sendQuestion();
  }

  Future<void> sendQuestion() async {
    _answersThisRoundMap.clear();
    final ClientQuestion clientQuestion = await _getQuestionForRound();
    _correctAnswerIndex = clientQuestion.correctIndex;
    _answersReceivedThisRound = 0;
    
    final startGamePacket = StartRoundPacket(
      round: currentRound, 
      rounds: totalRounds, 
      timeLimit: answerTimeLimit, 
      question: clientQuestion.question, 
      answers: clientQuestion.answers,
      category: clientQuestion.category,
    );
    broadcastCommand(jsonEncode(startGamePacket. toJson()));
  }

  Future<ClientQuestion> _getQuestionForRound() async {
    Question question = await fetchQuestion(categoryId); //categoryID if it is 0 it is read as null bya api_connector
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
    categoryId = null; //resetting category

    final endPacket = ShowLeaderboardPacket(
        time: 0,
        entries: scoresToLeaderboard(playerManager.players),
        isFinalLeaderboard: true);

    broadcastCommand(jsonEncode(endPacket.toJson()));
    usedJokers.clear();
    
    _broadcast?.stop();
    _broadcast = null;

    stopSocketServer();

    playerManager.reset();
    notifyListeners();
  }

  Future<void> restartGame() async {
    if (mode != Mode.host) return;

    print("game restarting...");
    usedJokers.clear();
    playerManager.reset();
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
      } else {
        //go to client 
        super.processNetworkMessage(msg);
      }
    } catch (e) {
      print("Error Host Game-loop: $e");
    }
  }

  Future<void> handleAnswer(Packet packet) async {
    final submitAnswerPacket = packet as SubmitAnswerPacket;
    String pId = submitAnswerPacket.playerId;
    String answer = submitAnswerPacket.answer;
    if(!playerManager.hasPlayer(pId)){
      throw Exception("Received answer from unregistered player with id $pId");
    }
    _answersThisRoundMap[playerManager.getNameById(pId)!] = answer;

    if (answer == currentAnswers[_correctAnswerIndex]) {
      playerManager.increaseScore(pId);
    }
    _answersReceivedThisRound++;
    
    if (_answersReceivedThisRound >= clientCount) {
      _answersReceivedThisRound = -999;

      final answerPacket = ShowCorrectAnswerPacket(
        correctAnswerIndex: _correctAnswerIndex,
        playerAnswers: _answersThisRoundMap,
      );

      broadcastCommand(jsonEncode(answerPacket.toJson()));

        Future.delayed(const Duration(seconds: 4), () async {
          if (currentRound < totalRounds) {
            await showLeaderboardForXSeconds(5, false);
            currentRound++;
            await sendQuestion();
      } else {
        print("Game is over");
        await showLeaderboardForXSeconds(20, true);
      }
    });
   }
  }

  Future<void> showLeaderboardForXSeconds(int seconds, bool isFinalLeaderboard) async {
    List<LeaderboardEntry> entries = scoresToLeaderboard(playerManager.players);
    ShowLeaderboardPacket showLeaderboardPacket = ShowLeaderboardPacket(
      time: seconds, 
      entries: entries, 
      isFinalLeaderboard: isFinalLeaderboard
    );
    broadcastCommand(jsonEncode(showLeaderboardPacket.toJson()));
    await Future.delayed(Duration(seconds: seconds));
  }

  List<LeaderboardEntry> scoresToLeaderboard(List<PlayerData> players) {
    return players
        .map((player) => LeaderboardEntry(name: player.name, score: player.score))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
  }

  @override
  void dispose() {
    _broadcast?.stop();
    super.dispose();
  }

  void preProcessNetworkMessage(WebSocket socket, String data) {
    final packet = Packet.fromJson(jsonDecode(data));
    if (packet.type == PacketType.REGISTER) {
      final registerPacket = RegisterPacket.fromJson(jsonDecode(data));
      playerManager.addPlayer(registerPacket.name, registerPacket.id, socket);
      registerPlayerSocket(registerPacket.id, socket);
      print("Player registered: ${registerPacket.name} with id ${registerPacket.id}");
      notifyListeners();
    }
    else {
      processNetworkMessage(data);
    }
  }
  void kickPlayer(String playerId) {
    playerManager.kick(playerId);
    notifyListeners();
  }
}
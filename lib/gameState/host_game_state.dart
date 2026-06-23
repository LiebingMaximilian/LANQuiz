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
import 'package:lan_quiz/packets/player_answered_packet.dart';
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
import '../packets/update_player_list_packet.dart';

class HostGameState extends ClientGameState { //extending client_game_state means host is client and host in one, which is what we want
  int _correctAnswerIndex = 0;
  int _answersReceivedThisRound = 0;
  Map<String, Set<JokerType>> usedJokers = {};
  BonsoirBroadcast? _broadcast;
  final Map<String,String> _answersThisRoundMap = {};
  int? categoryId; //null is all categories
  final Set<String> doubleDownActive = {};
  final Set<String> secondChanceActive = {};
  //       targetId, attackerId
  final Map<String, String> copyCatActive = {};


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
      onClientDisconnected: (socket) {
        playerManager.removePlayerBySocket(socket);
        notifyListeners();
      }
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
    doubleDownActive.clear();
    copyCatActive.clear();
    secondChanceActive.clear();
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
    String pId = playerManager.players.firstWhere((p) => p.name == pName).id;
    
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
    
        final responseFF = JokerResponsePacket(
          targetPlayerId: pId,
          sourcePlayerName: pName,
          answersToHide: [wrongIndices[0], wrongIndices[1]],
          jokerType: request.jokerType,
        );
        broadcastCommand(jsonEncode(responseFF.toJson()));
        break;

      case JokerType.DOUBLE_DOWN:
        doubleDownActive.add(pId);
        final responseDD = JokerResponsePacket(
          targetPlayerId: pId,
          sourcePlayerName: pName,
          jokerType: JokerType.DOUBLE_DOWN,
        );
        broadcastCommand(jsonEncode(responseDD.toJson()));
        break;

      case JokerType.SECOND_CHANCE:
        secondChanceActive.add(pId);
        final responseSC = JokerResponsePacket(
          targetPlayerId: pId,
          sourcePlayerName: pName,
          jokerType: JokerType.SECOND_CHANCE,
        );
        broadcastCommand(jsonEncode(responseSC.toJson()));
        break;

      case JokerType.INK_SPLASH:
        String targetId = request.targetId;
        // print("HOST: INK SPLASH RECEIVED, ATTACKER: $pName, TARGET: $targetId, TARGET_ID: ${request.targetId}");
        final responseIS = JokerResponsePacket(
            targetPlayerId: targetId,
            sourcePlayerName: pName,
            answersToHide: [],  // sending an empty list here
            jokerType: JokerType.INK_SPLASH,
        );
        broadcastCommand(jsonEncode(responseIS.toJson()));
        break;

      case JokerType.COPY_CAT:
        String targetId = request.targetId;
        String targetName = playerManager.getNameById(targetId) ?? "";

        if(_answersThisRoundMap.containsKey(targetName)){
          String answerToCopy = _answersThisRoundMap[targetName]!;
          _injectCopiedAnswer(pId, pName, answerToCopy);
        }
        else{
          copyCatActive[targetId] = pId;
          final responseCC = JokerResponsePacket(
            targetPlayerId: pId,
            sourcePlayerName: pName,
            jokerType: JokerType.COPY_CAT,
          );
          broadcastCommand(jsonEncode(responseCC.toJson()));
        }
        break;
    }
  }

  void _injectCopiedAnswer(String attackerId, String attackerName, String answer){
    _answersThisRoundMap[attackerName] = answer;

    bool hasDoubleDown = doubleDownActive.contains(attackerId);
    if (answer == currentAnswers[_correctAnswerIndex]) {
      playerManager.increaseScore(attackerId);
      if (hasDoubleDown) playerManager.increaseScore(attackerId);
    } else if (hasDoubleDown) {
      playerManager.decreaseScore(attackerId);
    }

    _answersReceivedThisRound++;

    final responseCC = JokerResponsePacket(
      targetPlayerId: attackerId,
      sourcePlayerName: attackerName,
      jokerType: JokerType.COPY_CAT,
    );
    broadcastCommand(jsonEncode(responseCC.toJson()));

    _checkRoundEnd();
  }

  void _checkRoundEnd(){
    if(_answersReceivedThisRound >= clientCount){
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
  }

  void broadcastPlayerList(){
    final list = playerManager.players.map((p) => {"name": p.name, "id": p.id}).toList();
    final updatePacket = UpdatePlayerListPacket(playerList: list, type: PacketType.UPDATE_PLAYER_LIST);
    broadcastCommand(jsonEncode(updatePacket.toJson()));
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
    playerManager.resetScores();
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

    final answeredPacket = PlayerAnsweredPacket(playerId: pId);
    broadcastCommand(jsonEncode(answeredPacket.toJson()));

    handlePlayerAnswered(answeredPacket);

    String pName = playerManager.getNameById(pId) ?? "Unknown";
    if(!playerManager.hasPlayer(pId)){
      throw Exception("Received answer from unregistered player with id $pId");
    }
    _answersThisRoundMap[playerManager.getNameById(pId)!] = answer;

    // Second Chance Logik
    if(answer != currentAnswers[_correctAnswerIndex] && secondChanceActive.contains(pId)){
      secondChanceActive.remove(pId);

      final response = JokerResponsePacket(
        targetPlayerId: pId,
        jokerType: JokerType.SECOND_CHANCE,
      );
      broadcastCommand(jsonEncode(response.toJson()));
      return;
    }


    _answersThisRoundMap[pName] = answer;
    bool hasDoubleDown = doubleDownActive.contains(pId);

    if (answer == currentAnswers[_correctAnswerIndex]) {
      playerManager.increaseScore(pId);
      if (hasDoubleDown) {
        playerManager.increaseScore(pId);
      }
    } else if(hasDoubleDown){
      playerManager.decreaseScore(pId);
    }

    _answersReceivedThisRound++;

    // Copy Cat waiting list check
    if (copyCatActive.containsKey(pId)){
      String attackerId = copyCatActive[pId]!;
      String attackerName = playerManager.getNameById(attackerId) ?? "Unknown";

      copyCatActive.remove(pId);
      _injectCopiedAnswer(attackerId, attackerName, answer);
    }
    _checkRoundEnd();
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
      playerManager.addPlayer(registerPacket.name, registerPacket.id, socket: socket);
      registerPlayerSocket(registerPacket.id, socket);
      print("Player registered: ${registerPacket.name} with id ${registerPacket.id}");
      broadcastPlayerList();
      notifyListeners();
    }
    else {
      processNetworkMessage(data);
    }
  }

  void kickPlayer(String playerId) {
    playerManager.kick(playerId);
    broadcastPlayerList();
    notifyListeners();
  }
}
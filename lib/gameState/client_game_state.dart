import 'dart:async';
import 'dart:io';
import 'package:bonsoir/bonsoir.dart';
import 'package:lan_quiz/enums/Mode.dart';
import 'package:lan_quiz/enums/quiz_phase.dart';
import 'package:lan_quiz/enums/joker_type.dart';
import 'package:lan_quiz/enums/packet_type.dart';
import 'package:lan_quiz/enums/ui_state.dart';
import 'package:lan_quiz/gameState/base_game_state.dart';
import 'package:lan_quiz/packets/base_packet.dart';
import 'package:lan_quiz/packets/join_rejected_packet.dart';
import 'package:lan_quiz/packets/joker_request_packet.dart';
import 'package:lan_quiz/packets/joker_response_packet.dart';
import 'package:lan_quiz/packets/player_answered_packet.dart';
import 'package:lan_quiz/packets/register_packet.dart';
import 'package:lan_quiz/packets/show_correct_answer_packet.dart';
import 'package:lan_quiz/packets/show_leaderboard_packet.dart';
import 'package:lan_quiz/packets/start_round_packet.dart';
import 'package:lan_quiz/screens/leaderboard_screen.dart';
import 'package:lan_quiz/stats_service.dart';
import 'package:web_socket_channel/io.dart';
import '../client.dart';
import 'dart:convert';
import 'package:flutter_background/flutter_background.dart';
import '../packets/update_player_list_packet.dart';


class ClientGameState extends BaseGameState {
  BonsoirDiscovery? _discovery;
  List<BonsoirService> discoveredServices = [];
  StreamSubscription? _streamSubscription;
  IOWebSocketChannel? channel;
  //Set<JokerType> myUsedJokers = {};
  late LeaderboardWidget leaderboard;
  bool isInkBlotted = false;
  Set<String> playersWhoAnswered = {};
  final _errorEventController = StreamController<String>.broadcast();
  Stream<String> get errorStream => _errorEventController.stream;

  Future<void> joinGame(String ip) async {

    const androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "LAN Quiz",
      notificationText: "Connected to Game round",
      notificationImportance: AndroidNotificationImportance.normal,
      notificationIcon: AndroidResource(name: 'background_icon', defType: 'drawable'),
    );

    Future<bool> backgroundPermissionAndroid() async {
      if(Platform.isAndroid){
        return await FlutterBackground.initialize(androidConfig: androidConfig);
      }
      return false;
    }

    bool hasPermissions = await backgroundPermissionAndroid();

    if(hasPermissions){
      await FlutterBackground.enableBackgroundExecution();
    }


    try {
      await _streamSubscription?.cancel();
      _streamSubscription = null;
      await channel?.sink.close();

      channel = createChannel(ip);

      _streamSubscription = channel!.stream.listen(
        (msg) {
          processNetworkMessage(msg);
        },
        onError: (error) {
          print("Error $error");
          _cleanupConnection();
        },
        onDone: () {
          print("Host disconnected connection terminated");
          _cleanupConnection();
        },
      );
      
      mode = Mode.join;
      uiState = UiState.waiting;
      print("Successfully connected to host at $ip");
      sendRegisterPacket();
      notifyListeners();
    } catch (e) {
      print("Unhandled connection error: $e");
    }
  }

  void _cleanupConnection(){
     isPaused = false;
     uiState = UiState.home;
     quizPhase = QuizPhase.answering;
     stopDiscovery();
     discoveredServices.clear();
     notifyListeners();
  }

  void sendToServer(String msg) {
    if (channel != null) {
      channel!.sink.add(msg);
    } else {
      print("Cannot write payload: Channel connection is dead.");
    }
  }

  void handlePlayerAnswered(Packet packet){
    final p = packet as PlayerAnsweredPacket;
    playersWhoAnswered.add(p.playerId);
    notifyListeners();
  }

  @override
  void processNetworkMessage(String msg) {
    print("Client dynamic engine received packet structural updates: $msg");
    try {
      final packet = Packet.fromJson(jsonDecode(msg));
      switch (packet.type) {
        case PacketType.START_ROUND:
          isPaused = false;
          startRound(packet);
          break;
        case PacketType.SHOW_LEADERBOARD:
          displayLeaderboard(packet);
          break;
        case PacketType.JOKER_RESPONSE:
          handleJokerResponse(packet);
          break;
        case PacketType.CORRECT_ANSWER:
          handleCorrectAnswer(packet);
          break;
        case PacketType.UPDATE_PLAYER_LIST:
          handlePlayerListUpdate(packet);
          break;
        case PacketType.PLAYER_ANSWERED:
          handlePlayerAnswered(packet);
        case PacketType.GAME_RESUMED:
          isPaused = false;
          notifyListeners();
          break;
        case PacketType.GAME_PAUSED:
          isPaused = true;
          notifyListeners();
          break;
        case PacketType.JOIN_REJECTED:
          handleJoinRejected(packet);
        default:
          break;
      }
    } catch (e) {
      print("Failed parsing client incoming message thread: $e");
    }
  }

  void sendRegisterPacket() {
    final registerPacket = RegisterPacket(name: myName, id: myId);
    sendToServer(jsonEncode(registerPacket.toJson()));
  }

  void handleJoinRejected(Packet packet){
    final rejectedPacket = packet as JoinRejectedPacket;

    _errorEventController.add(rejectedPacket.message);

    cancelJoin();
  }

  void handlePlayerListUpdate(Packet packet){
    final p = packet as UpdatePlayerListPacket;
    playerManager.players.clear();
    for(var playerMap in p.playerList){
      playerManager.addPlayer(playerMap['name']!, playerMap['id']!);
    }
    notifyListeners();
  }

  void handleJokerResponse(Packet packet) {
    final response = packet as JokerResponsePacket;

    // print("CLIENT ${myName}: ATTACKER: ${response.sourcePlayerName}, TARGET: ${response.targetPlayerId}, JOKER: ${response.jokerType}, GOT JOKER RESPONSE");
    // has host confirmed my request?
    if(response.sourcePlayerName == myName){
      isWaitingForJoker = false;
      notifyListeners();
    }

    // am i the target of the joker?
    if (response.targetPlayerId == myId) {

      // print("CLIENT ${myName}: ATTACKER: ${response.sourcePlayerName}, TARGET: ${response.targetPlayerId}, JOKER: ${response.jokerType}, I AM THE TARGET, USE JOKER");
      if(response.sourcePlayerName == myName) {
        myUsedJokers.add(response.jokerType);
      }

      switch(response.jokerType) {

        case JokerType.FIFTY_FIFTY:
          final hideList = response.answersToHide;
          if(hideList != null){
            for (int index in hideList) {
              if (index >= 0 && index < currentAnswers.length) {
                currentAnswers[index] = "";
              }
            }
          }
          break;

        case JokerType.SECOND_CHANCE:
          isWaitingForJoker = false;
          unlockAnswer = true;
          break;

        case JokerType.DOUBLE_DOWN:
          // nothing to do visually on client side
          break;

        case JokerType.INK_SPLASH:
          // print("CLIENT ${myName}: ATTACKER: ${response.sourcePlayerName}, TARGET: ${response.targetPlayerId}, JOKER: ${response.jokerType}, I GOT INK SPLASH");
          isInkBlotted = true;
          notifyListeners();
          break;

        case JokerType.COPY_CAT:
          break;
      }
      notifyListeners();
    }
  }

  void handleCorrectAnswer(Packet packet){
    final p = packet as ShowCorrectAnswerPacket;
    correctAnswerIndex = p.correctAnswerIndex;
    playerAnswersThisRound = p.playerAnswers;
    quizPhase = QuizPhase.showingResults;
    notifyListeners();
  }

  void useJoker(JokerType jokerType, {String targetId = ""}) {
    if (myUsedJokers.contains(jokerType) || isWaitingForJoker || currentAnswers.length == 2 || quizPhase != QuizPhase.answering) return;

    myUsedJokers.add(jokerType);
    isWaitingForJoker = true;
    statsController.trackJokers();
    final request = JokerRequestPacket(playerName: myName, jokerType: jokerType, targetId: targetId);
    sendToServer(jsonEncode(request.toJson()));
  }

  void startRound(Packet packet) {
    final startRoundPacket = packet as StartRoundPacket;
    if (startRoundPacket.round == 1) {
      myUsedJokers.clear();
      isWaitingForJoker = false;
    }
    print("Started Game on this Device");
    uiState = UiState.quiz;
    currentRound = startRoundPacket.round;
    totalRounds = startRoundPacket.rounds;
    answerTimeLimit = startRoundPacket.timeLimit;
    currentCategory = startRoundPacket.category;
    currentQuestion = startRoundPacket.question;
    currentAnswers = List<String>.from(startRoundPacket.answers);
    statsController.newQuestion(startRoundPacket.category);
    print(startRoundPacket.category);
    quizPhase = QuizPhase.answering;
    correctAnswerIndex = -1;
    playerAnswersThisRound.clear();
    isInkBlotted = false;
    playersWhoAnswered.clear();

    notifyListeners();
  }

  void displayLeaderboard(Packet packet) {
    final showLeaderboardPacket = packet as ShowLeaderboardPacket;
    uiState = UiState.leaderboard;

      leaderboardEntries = showLeaderboardPacket.entries;
      leaderboardTimeLimit = showLeaderboardPacket.time;
      isFinalLeaderboard = showLeaderboardPacket.isFinalLeaderboard;

    notifyListeners();
  }

  Future<void> discoverGames() async {
  discoveredServices.clear();
  notifyListeners();

  _discovery = BonsoirDiscovery(type: "_lanquiz._tcp", printLogs: true);
  await _discovery!.ready;
  print("DEBUG: Discovery ready, starting...");

  _discovery!.eventStream!.listen((event) {
    print("DEBUG: Event received — ${event.type}"); // prints every event

    if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
      print("DEBUG: Found service: ${event.service?.name}, attempting resolve...");
      event.service!.resolve(_discovery!.serviceResolver);
    } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved &&
        event.service != null) {
      final resolved = event.service as ResolvedBonsoirService;
      print("DEBUG: Resolved! name=${resolved.name} host=${resolved.host} port=${resolved.port}");
      if (!discoveredServices.any((s) => s.name == event.service!.name)) {
        discoveredServices.add(event.service!);
        print("DEBUG: Added to list, total=${discoveredServices.length}");
        notifyListeners();
      }
    } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
      print("DEBUG: Lost service: ${event.service?.name}");
      discoveredServices.removeWhere((s) => s.name == event.service!.name);
      notifyListeners();
    }
  });

  await _discovery!.start();
  print("DEBUG: Discovery started");
}

 /* Future<void> startDiscovery() async {         redundant?
    discoveredServices.clear();
    _discovery = BonsoirDiscovery(type: '_quizduell._tcp');
    await _discovery!.ready;

    _discovery!.eventStream!.listen((event) {
      if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
        event.service!.resolve(_discovery!.serviceResolver);
      } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved && event.service != null) {
        // final resolved = event.service as ResolvedBonsoirService;
        if (!discoveredServices.any((s) => s.name == event.service!.name)) {
          discoveredServices.add(event.service!);
          notifyListeners();
        }
      } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
        discoveredServices.removeWhere((s) => s.name == event.service!.name);
        notifyListeners();
      }
    });

    await _discovery!.start();
  }
  */

  void stopDiscovery() {
    _discovery?.stop();
    _discovery = null;
  }

  void setNames(String newName) {
    if (newName.trim().isNotEmpty) {
      myName = newName.trim();
      notifyListeners();
    }
  }

  void cancelJoin() {
    // Note: No await or async, if await is used here the code will
    // be stuck here when the wrong ip address was used when joining a game
    print('canceling join');

    if(Platform.isAndroid && FlutterBackground.isBackgroundExecutionEnabled){
      FlutterBackground.disableBackgroundExecution();
    }
    _streamSubscription?.cancel();
    _streamSubscription = null;
    channel?.sink.close();
    channel = null;

    discoveredServices.clear();

    mode = Mode.none;
    uiState = UiState.home;
    print('Canceled');
    notifyListeners();

  }

  @override
  void dispose() {
    if(Platform.isAndroid && FlutterBackground.isBackgroundExecutionEnabled){
      FlutterBackground.disableBackgroundExecution();
    }
    _streamSubscription?.cancel();
    channel?.sink.close();
    _discovery?.stop();
    _errorEventController.close();
    super.dispose();
  }
}
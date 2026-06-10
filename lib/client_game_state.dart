import 'dart:async';
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/material.dart';
import 'package:lan_quiz/base_game_state.dart';
import 'package:lan_quiz/leaderboard.dart';
import 'package:web_socket_channel/io.dart';
import 'host.dart';
import 'client.dart';
import 'main.dart';
import 'dart:convert';
import 'classes.dart';
import 'api_connector.dart';

class ClientGameState extends BaseGameState {
  IOWebSocketChannel? _channel;
  StreamSubscription? _sub;
  BonsoirDiscovery? _discovery;
  List<BonsoirService> discoveredServices = [];
  StreamSubscription? _streamSubscription;
  IOWebSocketChannel? channel;
  Set<JokerType> myUsedJokers = {};
  late LeaderboardWidget leaderboard;

  Future<void> joinGame(String ip) async {
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
          notifyListeners();
        },
        onDone: () {
          print("Host disconnected connection terminated");
          isPlaying = false;
          showLeaderboard = false;
          notifyListeners();
        },
      );
      
      mode = Mode.join;
      print("Successfully connected to host at $ip");
      notifyListeners();
    } catch (e) {
      print("Unhandled connection error: $e");
    }
  }

  void sendToServer(String msg) {
    if (channel != null) {
      channel!.sink.add(msg);
    } else {
      print("Cannot write payload: Channel connection is dead.");
    }
  }

  @override
  void processNetworkMessage(String msg) {
    print("Client dynamic engine received packet structural updates: $msg");
    try {
      final packet = Packet.fromJson(jsonDecode(msg));
      switch (packet.type) {
        case PacketType.START_ROUND:
          startRound(packet);
          break;
        case PacketType.SHOW_LEADERBOARD:
          displayLeaderboard(packet);
          break;
        case PacketType.JOKER_RESPONSE:
          handleJokerResponse(packet);
          break;
        default:
          break;
      }
    } catch (e) {
      print("Failed parsing client incoming message thread: $e");
    }
  }

  void handleJokerResponse(Packet packet) {
    final response = packet as JokerResponsePacket;
    if (response.targetPlayerName == myName) {
      myUsedJokers.add(response.jokerType);
      isWaitingForJoker = false;
      
      if (response.jokerType == JokerType.FIFTY_FIFTY) {
        final hideList = response.answersToHide;
        if (hideList != null) {
          for (int index in hideList) {
            if (index >= 0 && index < currentAnswers.length) {
              currentAnswers[index] = "";
            }
          }
        }
      }
      notifyListeners();
    }
  }

  void useJoker(JokerType jokerType) {
    if (myUsedJokers.contains(jokerType) || isWaitingForJoker) return;

    myUsedJokers.add(jokerType);
    isWaitingForJoker = true;

    final request = JokerRequestPacket(playerName: myName, jokerType: jokerType);
    sendToServer(jsonEncode(request.toJson()));
  }

  void startRound(Packet packet) {
    final startRoundPacket = packet as StartRoundPacket;
    if (startRoundPacket.round == 1) {
      myUsedJokers.clear();
      isWaitingForJoker = false;
    }
    print("Started Game on this Device");
    isPlaying = true;
    showLeaderboard = false;
    currentRound = startRoundPacket.round ?? 1;
    totalRounds = startRoundPacket.rounds ?? 10;
    answerTimeLimit = startRoundPacket.timeLimit ?? 20;
    currentQuestion = startRoundPacket.question ?? "No Question";
    currentAnswers = List<String>.from(startRoundPacket.answers);
    
    notifyListeners();
  }

  void displayLeaderboard(Packet packet) {
    final showLeaderboardPacket = packet as ShowLeaderboardPacket;
    isPlaying = false;
    showLeaderboard = true;
    
    leaderboard = LeaderboardWidget(
      entries: showLeaderboardPacket.entries,
      timeLimit: showLeaderboardPacket.time,
      isFinal: showLeaderboardPacket.isFinalLeaderboard,
    );
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
  Future<void> startDiscovery() async {
    discoveredServices.clear();
    _discovery = BonsoirDiscovery(type: '_quizduell._tcp');
    await _discovery!.ready;

    _discovery!.eventStream!.listen((event) {
      if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
        event.service!.resolve(_discovery!.serviceResolver);
      } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved && event.service != null) {
        final resolved = event.service as ResolvedBonsoirService;
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
    _streamSubscription?.cancel();
    _streamSubscription = null;
    channel?.sink.close();
    channel = null;

    discoveredServices.clear();

    mode = Mode.none;

    print('Canceled');
    notifyListeners();

  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    channel?.sink.close();
    _discovery?.stop();
    super.dispose();
  }
}
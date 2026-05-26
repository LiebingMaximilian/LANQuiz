import 'dart:async';
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/material.dart';
import 'package:lan_quiz/leaderboard.dart';
import 'package:web_socket_channel/io.dart';
import 'host.dart';
import 'client.dart';
import 'main.dart';
import 'dart:convert';
import 'classes.dart';
import 'api_connector.dart';

class GameState extends ChangeNotifier {
  // Connection State
  Mode mode = Mode.none;
  String? localIp;
  StreamSubscription? _streamSubscription;
  IOWebSocketChannel? channel;

  // Game Logic State
  bool isPlaying = false;
  bool showLeaderboard = false;
  int currentRound = 1;
  int totalRounds = 10;
  int answerTimeLimit = 20;
  String currentQuestion = "";
  List<String> currentAnswers = [];


  late LeaderboardWidget leaderboard;

  // Scoring and Loop Logic
  String myName = "Spieler ${DateTime.now().millisecond%1000}"; //randomname for now TODO player input own name
  Map<String,dynamic> scores = {};
  int _answersReceivedThisRound = 0;
  int _correctAnswerIndex = 2; // for example question

  // Discovery State
  List<BonsoirService> discoveredServices = [];
  BonsoirDiscovery? _discovery;
  BonsoirBroadcast? _broadcast;

  // ── Host ────────────────────────────────────────────────────────────────────

  Future<void> hostGame() async {
    _broadcast = await startBroadcast();
    startSocketServer(
      onMessageReceived: (incomingText) {
        processNetworkMessage(incomingText);
      },
    );

    localIp = await getLocalIpAddress();

    channel = createChannel('127.0.0.1');
    _streamSubscription = channel!.stream.listen(
        (msg){
          processNetworkMessage(msg);
        },
      onError: (error) => print("Loopback Fehler: $error"),
    );
    print("Hosting on ip: " + localIp!);
    mode = Mode.host;
    notifyListeners();
  }

  // ── Discovery ───────────────────────────────────────────────────────────────

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

  void stopDiscovery() {
    _discovery?.stop();
    _discovery = null;
  }

  // ── Join ────────────────────────────────────────────────────────────────────

  Future<void> joinGame(String ip) async {
    try {
      await _streamSubscription?.cancel();
      _streamSubscription = null;
      await channel?.sink.close();

      // Create channel and set up ONE listener here — no connectToHost helper
      channel = createChannel(ip);

      _streamSubscription = channel!.stream.listen(
        (msg) {
          processNetworkMessage(msg).catchError((error) { //"fire and forget should work here"
            print("Error processing message: $error");
          });

        },
        onError: (error) {
          print("Error $error");
          notifyListeners();
        },
        onDone: () {
          print("Host disconnected");
          notifyListeners();
        },
        cancelOnError: true,
      );

      mode = Mode.join;
      notifyListeners();
    } catch (e) {
      print("Error $e");
      notifyListeners();
    }
  }

  // ── Communication ───────────────────────────────────────────────────────────

  void broadcastCommand(String jsonMessage){
    if(mode == Mode.host){
      broadcastToAll(jsonMessage);
    }
  }

  void sendToServer(String jsonMessage){
    channel?.sink.add(jsonMessage);
  }

  // ── Dispose ─────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _broadcast?.stop();
    stopDiscovery();
    channel?.sink.close();
    super.dispose();
  }


  Future<ClientQuestion> _getQuestionForRound() async {
    Question question = await fetchQuestion(); 
    ClientQuestion clientQuestion = ClientQuestion.QuestionToClientQuestion(question);
    return clientQuestion;
  }

  Future<void> startGame(int rounds, int timeLimit) async{
    if (mode != Mode.host){
      return;
    }

    totalRounds = rounds;
    currentRound = 1;
    answerTimeLimit = timeLimit;

    await sendQuestion();
  }
  
  Future<void> sendQuestion () async{
    final ClientQuestion clientQuestion = await _getQuestionForRound();
    _correctAnswerIndex = clientQuestion.correctIndex;
    final startGamePacket = StartRoundPacket(round: currentRound, rounds: totalRounds, timeLimit: answerTimeLimit, question: clientQuestion.question, answers: clientQuestion.answers);

    broadcastCommand(jsonEncode(startGamePacket.toJson()));
  }

  Future<void> processNetworkMessage(String msg) async{
    print("Message received: $msg");
    try{
      final String msgString = msg.toString();
      final packet = Packet.fromJson(jsonDecode(msgString));

      if(packet.type == PacketType.START_ROUND){
        final startRoundPacket = packet as StartRoundPacket;
        print("Started Game on this Device");
        isPlaying = true;
        showLeaderboard = false;
        currentRound = startRoundPacket.round ?? 1;
        totalRounds = startRoundPacket.rounds ?? 10;
        answerTimeLimit = startRoundPacket.timeLimit ?? 20;
        currentQuestion = startRoundPacket.question ?? "No Question";
        currentAnswers = List<String>.from(startRoundPacket.answers);
        _answersReceivedThisRound = 0;
        notifyListeners();
      }
      else if(packet.type == PacketType.SUBMIT_ANSWER && mode == Mode.host){
        final submitAnswerPacket = packet as SubmitAnswerPacket;
        String pName = submitAnswerPacket.playerName ?? "Unknown";
        String answer = submitAnswerPacket.answer ?? "";

        if(answer == currentAnswers[_correctAnswerIndex]){
          scores[pName] = (scores[pName] ?? 0) + 1; // + 1 point
        }
        else{
          scores[pName] = scores[pName] ?? 0; // trägt spieler mit 0 punkte ein
        }
        _answersReceivedThisRound++;

        if(_answersReceivedThisRound >= clientCount){

          _answersReceivedThisRound = -999;

          if(currentRound < totalRounds){
            Future.delayed(const Duration(seconds: 2), () async {
              await showLeaderboardForXSeconds(5, false);
              int nextRound = currentRound + 1;

              final ClientQuestion clientQuestion = await _getQuestionForRound();
              _correctAnswerIndex = clientQuestion.correctIndex;

              final nextRoundPacket = StartRoundPacket(round: nextRound, rounds: totalRounds, timeLimit: answerTimeLimit, question: clientQuestion.question, answers: clientQuestion.answers);

              broadcastCommand(jsonEncode(nextRoundPacket.toJson()));

            });
          }else{
            print("Game is over");
            await showLeaderboardForXSeconds(20, true);
          }
        }
      }
      else if(packet.type == PacketType.SHOW_LEADERBOARD){
        final showLeaderboardPacket = packet as ShowLeaderboardPacket;
        leaderboard = LeaderboardWidget(entries: showLeaderboardPacket.entries,timeLimit: showLeaderboardPacket.time);
        isPlaying = false;
        showLeaderboard = true;
        notifyListeners();
        await Future.delayed(Duration(seconds: showLeaderboardPacket.time));
        if(showLeaderboardPacket.isFinalLeaderboard)
        {
          mode = Mode.none;
          isPlaying = false;
          showLeaderboard = false;
          notifyListeners();
        }
      }
    } catch(e){
      print("Error Gameloop");
    }
  }

  Future<void> showLeaderboardForXSeconds(int seconds, bool isFinalLeaderboard) async{
    List<LeaderboardEntry> entries = scoresToLeaderboard(scores);
    ShowLeaderboardPacket showLeaderboardPacket = ShowLeaderboardPacket(time: seconds, entries: entries, isFinalLeaderboard: isFinalLeaderboard) ;
    broadcastCommand(jsonEncode(showLeaderboardPacket.toJson()));
    await Future.delayed(Duration(seconds: seconds));
  }

  List<LeaderboardEntry> scoresToLeaderboard(Map<String, dynamic> scores) {
  return scores.entries
      .map((e) => LeaderboardEntry(name: e.key, score: e.value as int))
      .toList()
    ..sort((a, b) => b.score.compareTo(a.score));
}
}
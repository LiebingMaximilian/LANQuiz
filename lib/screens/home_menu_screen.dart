import 'dart:convert';

import 'dart:io';
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart';
import 'package:lan_quiz/client_question.dart';
import 'package:lan_quiz/enums/ui_state.dart';
import 'package:lan_quiz/packets/submit_answer_packet.dart';
import 'package:lan_quiz/screens/host_settings_screen.dart';
import 'package:lan_quiz/screens/player_waiting_screen.dart';
import 'package:lan_quiz/screens/quiz_question_screen.dart';
import 'package:lan_quiz/screens/global_settings_screen.dart';
import 'package:lan_quiz/stats_service.dart';
import 'package:provider/provider.dart';
import '../gameState/host_game_state.dart';
import 'player_statistics_screen.dart';
import 'package:lan_quiz/sound_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
bool isHostButtonPressed = false;

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController ipController = TextEditingController(); // ← moved here
  bool isDiscovering = false;

  @override
  void initState() {
  super.initState();
  
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final currentUsername = await getUsername();
    if (currentUsername == null || currentUsername.isEmpty) {
      usernameInputDialog(context, true);
    } else { //fetching saved username and setting it in gameState if username already exists.
      updateUsername(currentUsername, context);
    }
    audioInit();
    statsController.init();

  });
}

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    ipController.dispose();
    Provider.of<HostGameState>(context, listen: false).stopDiscovery();
    super.dispose();
  }

  Future<void> startDiscovery(HostGameState hostGameState) async {
    print("DEBUG: _startDiscovery called");
    setState(() => isDiscovering = true);
    await hostGameState.discoverGames();
  }

  void stopDiscovery(HostGameState gameState) {
    gameState.stopDiscovery();
    setState(() => isDiscovering = false);
  }
  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<HostGameState>();

    return switch (gameState.uiState) {
      UiState.home => const HomeMenuScreen(),
      UiState.hostLobby => HostSettingsScreen(gameState: gameState,),
      UiState.waiting => const PlayerWaitingScreen(),
      UiState.quiz => QuizQuestionWidget(
          currentRound: gameState.currentRound,
          totalRounds: gameState.totalRounds,
          question: parse(gameState.currentQuestion).body!.text,
          currentCategory: parse(gameState.currentCategory).body!.text,
          timeLimit: gameState.answerTimeLimit,
          answers: gameState.currentAnswers,
          giveAnswer: (answer, timeTaken){
            print("answer $answer logged in $timeTaken seconds");
            final answerPacket = SubmitAnswerPacket(answer: answer, timeTaken: timeTaken, playerName: gameState.myName, playerId: gameState.myId);
            gameState.sendToServer(jsonEncode(answerPacket.toJson()));
          },
      ),
      UiState.leaderboard => gameState.leaderboard,
    };
  
  }
}

class HomeMenuScreen extends StatefulWidget {
  const HomeMenuScreen({super.key});

  @override
  State<HomeMenuScreen> createState() => _HomeMenuScreenState();
}

class _HomeMenuScreenState extends State<HomeMenuScreen> {
  final ipController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isDiscovering = false;

  @override
  void dispose() {
    ipController.dispose();
    super.dispose();
  }

  Future<void> startDiscovery() async {
    setState(() => isDiscovering = true);

    await context.read<HostGameState>().discoverGames();
  }

  void stopDiscovery() {
    context.read<HostGameState>().stopDiscovery();

    setState(() => isDiscovering = false);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<HostGameState>();

    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leading: IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(
            builder: (context) => const PlayerStatisticScreen())), 
            icon: Icon(Icons.stacked_bar_chart)), 
            title: const Text("LAN Quiz"), 
          actions: [IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (context) => const GlobalSettingsScreen())), 
              icon: Icon(Icons.settings))],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40.0), 
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
              alignment: Alignment.center, 
              child: FutureBuilder<String?>(
                future: getUsername(), 
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text("");
                  }
                  final username = snapshot.data ?? '';
                  return Text(
                    username.isNotEmpty ? 'Welcome back, $username' : 'Welcome, Guest',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black, // Adjust color to fit your theme
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              children: [
                const Icon(Icons.wifi_tethering, size: 80, color: Colors.blue),
                const SizedBox(height: 30),

                // ── Host button ──────────────────────────────────────────────
                ElevatedButton.icon(
                  onPressed: () {
                    if(isHostButtonPressed == false){
                      isHostButtonPressed = true;
                      if(isDiscovering == true){
                        stopDiscovery(); //to fix host being able to join own game after exiting host settings screen
                        }
                    updateUsername(gameState.myName, context).then((_) => gameState.hostGame());
                    }},
                  icon: const Icon(Icons.dns),
                  label: const Text("Host Game"),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50)),
                ),

                const SizedBox(height: 40),
                const Row(children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("OR JOIN A GAME",
                        style:
                            TextStyle(color: Colors.grey, letterSpacing: 1.2)),
                  ),
                  Expanded(child: Divider()),
                ]),
                const SizedBox(height: 20),

                // ── Discover / Stop button ───────────────────────────────────
                ElevatedButton.icon(
                  onPressed: isDiscovering
                      ? () => stopDiscovery()
                      : () => startDiscovery(),
                  icon: isDiscovering
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.search),
                  label: Text(
                      isDiscovering ? "Stop Searching" : "Find Games"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor:
                        isDiscovering ? Colors.orange : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                // ── Discovered games list ────────────────────────────────────
                if (gameState.discoveredServices.isEmpty && isDiscovering)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text("Looking for games on your network…",
                        style: TextStyle(color: Colors.grey)),
                  )
                else if (gameState.discoveredServices.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Available Games",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      ...gameState.discoveredServices.map((service) {
                        final resolved = service as ResolvedBonsoirService;
                        final ip = resolved.host ?? "Unknown IP";
                        final port = resolved.port;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            tileColor: Colors.blue.shade50,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            leading: const Icon(Icons.sports_esports,
                                color: Colors.blue),
                            title: Text(service.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text("$ip : $port",
                                style: const TextStyle(
                                    color: Colors.blueGrey)),
                            trailing: const Icon(Icons.arrow_forward_ios,
                                size: 16),
                            onTap: () {
                              stopDiscovery();
                              updateUsername(gameState.myName, context);
                              gameState.joinGame(ip);
                            },
                          ),
                        );
                      }),
                    ],
                  ),

                // ── Manual IP entry — always visible ─────────────────────────
                const SizedBox(height: 24),
                const Row(children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("OR ENTER IP MANUALLY",
                        style: TextStyle(
                            color: Colors.grey, letterSpacing: 1.2)),
                  ),
                  Expanded(child: Divider()),
                ]),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: ipController,
                      keyboardType: (!kIsWeb && Platform.isIOS)
                      ? TextInputType.visiblePassword
                      : const TextInputType.numberWithOptions(decimal: true), //numberkeyboard wiht . 
                      inputFormatters:[
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                      ],
                      decoration: const InputDecoration(
                        labelText: "Host IP Address",
                        hintText: "e.g. 192.168.1.50",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lan),
                        ),
                        validator: (value){
                          if(value == null || value.isEmpty) {
                            return 'Please enter an IP address';
                          }
                          final ipRegex = RegExp(r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');

                          if(!ipRegex.hasMatch(value)){
                            return 'Please enter a valid IP address';
                          }
                          return null;
                        }
                      ),
                    ],
                  )
                ),


                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valid IP address! connecting...')),
                      );
                      stopDiscovery();
                      updateUsername(gameState.myName, context);
                      gameState.joinGame(ipController.text);
                    }
                  },
                  icon: const Icon(Icons.login),
                  label: const Text("Join Game"),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50)),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
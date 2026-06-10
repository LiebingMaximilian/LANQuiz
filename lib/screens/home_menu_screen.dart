import 'dart:convert';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart';
import 'package:lan_quiz/classes.dart';
import 'package:lan_quiz/screens/host_settings_screen.dart';
import 'package:lan_quiz/screens/player_waiting_screen.dart';
import 'package:lan_quiz/screens/quiz_question_screen.dart';
import 'package:provider/provider.dart';
import '../gameState/host_game_state.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController ipController = TextEditingController(); // ← moved here
  bool isDiscovering = false;

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
          timeLimit: gameState.answerTimeLimit,
          answers: gameState.currentAnswers,
          giveAnswer: (answer, timeTaken){
            print("answer $answer logged in $timeTaken seconds");
            final answerPacket = SubmitAnswerPacket(answer: answer, timeTaken: timeTaken, playerName: gameState.myName);
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
        appBar: AppBar(title: const Text("LAN Quiz")),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              children: [
                const Icon(Icons.wifi_tethering, size: 80, color: Colors.blue),
                const SizedBox(height: 30),

                // ── Host button ──────────────────────────────────────────────
                ElevatedButton.icon(
                  onPressed: () => gameState.hostGame(),
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
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
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
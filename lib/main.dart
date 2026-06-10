import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lan_quiz/classes.dart';
import 'package:lan_quiz/host_game_state.dart';
import 'package:lan_quiz/quiz_question_widget.dart';
import 'package:provider/provider.dart';
import 'package:bonsoir/bonsoir.dart';
import 'client_game_state.dart';
import 'dart:async';
import 'package:html/parser.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider<ClientGameState>(
      create: (context) => ClientGameState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LAN Quiz',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController ipController = TextEditingController(); 
  bool _isDiscovering = false;
  final _formKey = GlobalKey<FormState>();
  
  // Keep track of the host state locally if this specific device becomes the host
  HostGameState? _hostGameState;

  @override
  void dispose() {
    ipController.dispose();
    // Use the provider carefully on teardown
    final clientState = Provider.of<ClientGameState>(context, listen: false);
    clientState.stopDiscovery();
    _hostGameState?.stopDiscovery();
    super.dispose();
  }

  Future<void> _startDiscovery(ClientGameState gameState) async {
    print("DEBUG: _startDiscovery called");
    setState(() => _isDiscovering = true);
    await gameState.discoverGames();
  }

  void _stopDiscovery(ClientGameState gameState) {
    gameState.stopDiscovery();
    setState(() => _isDiscovering = false);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<ClientGameState>(context);
    
    if (gameState.showLeaderboard) {
      return gameState.leaderboard;
    }

    if (gameState.isPlaying) {
      return QuizQuestionWidget(
        currentRound: gameState.currentRound,
        totalRounds: gameState.totalRounds,
        question: parse(gameState.currentQuestion).body!.text,
        timeLimit: gameState.answerTimeLimit,
        answers: gameState.currentAnswers,
        giveAnswer: (answer, timeTaken) {
          print("answer $answer logged in $timeTaken seconds");
          final answerPacket = SubmitAnswerPacket(
              answer: answer, timeTaken: timeTaken, playerName: gameState.myName);
          gameState.sendToServer(jsonEncode(answerPacket.toJson()));
        },
      );
    }

    // ── 1. START SCREEN ──────────────────────────────────────────────────────
    if (gameState.mode == Mode.none) {
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
                  onPressed: () {
                    // Instantiating the HostGameState dynamically here.
                    // Because HostGameState extends ClientGameState, it carries all client operations
                    // plus your background server features!
                    _hostGameState = HostGameState();
                    _hostGameState!.hostGame();
                    
                    // Sync up core essential properties from the base state if necessary
                    _hostGameState!.mode = Mode.host; 
                    
                    setState(() {});
                  },
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
                        style: TextStyle(color: Colors.grey, letterSpacing: 1.2)),
                  ),
                  Expanded(child: Divider()),
                ]),
                const SizedBox(height: 20),

                // ── Discover / Stop button ───────────────────────────────────
                ElevatedButton.icon(
                  onPressed: _isDiscovering
                      ? () => _stopDiscovery(gameState)
                      : () => _startDiscovery(gameState),
                  icon: _isDiscovering
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.search),
                  label: Text(_isDiscovering ? "Stop Searching" : "Find Games"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: _isDiscovering ? Colors.orange : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                // ── Discovered games list ────────────────────────────────────
                if (gameState.discoveredServices.isEmpty && _isDiscovering)
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
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                            leading: const Icon(Icons.sports_esports, color: Colors.blue),
                            title: Text(service.name,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("$ip : $port",
                                style: const TextStyle(color: Colors.blueGrey)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              _stopDiscovery(gameState);
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
                        style: TextStyle(color: Colors.grey, letterSpacing: 1.2)),
                  ),
                  Expanded(child: Divider()),
                ]),

                Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                            controller: ipController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                            ],
                            decoration: const InputDecoration(
                              labelText: "Host IP Address",
                              hintText: "e.g. 192.168.1.50",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lan),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an IP address';
                              }
                              final ipRegex = RegExp(
                                  r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');

                              if (!ipRegex.hasMatch(value)) {
                                return 'Please enter a valid IP address';
                              }
                              return null;
                            }),
                      ],
                    )),

                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Valid IP address! connecting...')),
                      );
                      _stopDiscovery(gameState);
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

    // ── 2. Splitting of Host and Players ────────────────────────────────
    // Check local tracker instance first to evaluate hosting mode safely
    if (_hostGameState != null || gameState.mode == Mode.host) {
      final effectiveHostState = _hostGameState ?? (gameState as HostGameState);
      if (effectiveHostState.localIp == "10.0.2.16") {
        effectiveHostState.localIp = "10.0.2.2";
      }
      
      // We explicitly feed the subclass widget with its necessary type here.
      return ChangeNotifierProvider<HostGameState>.value(
        value: effectiveHostState,
        child: HostSettingsScreen(gameState: effectiveHostState),
      );
    } else {
      return const PlayerWaitingScreen();
    }
  }
}

class HostSettingsScreen extends StatefulWidget {
  final HostGameState gameState;
  const HostSettingsScreen({super.key, required this.gameState});

  @override
  State<HostSettingsScreen> createState() => _HostSettingsScreenState();
}

class _HostSettingsScreenState extends State<HostSettingsScreen> {
  double _rounds = 10; 
  double _answertimelimit = 20;
  final hostNameController = TextEditingController();

  @override
  void dispose() {
    hostNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Game Settings"),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              // Reset hosting state logic safely here if needed
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi, color: Colors.blue),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Spieler können beitreten über: "),
                      Text(
                        widget.gameState.localIp ?? "Loading IP ...",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            Text(
              "Number of Rounds: ${_rounds.toInt()}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _rounds,
              min: 2,
              max: 30,
              divisions: 25,
              label: _rounds.toInt().toString(),
              onChanged: (double value) {
                setState(() {
                  _rounds = value;
                });
              },
            ),
            const SizedBox(height: 40),
            Text(
              "Answering Time limit: ${_answertimelimit.toInt()} sec",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _answertimelimit,
              min: 5,
              max: 60,
              divisions: 55,
              label: _answertimelimit.toInt().toString(),
              onChanged: (double value) {
                setState(() {
                  _answertimelimit = value;
                });
              },
            ),

            const SizedBox(height: 15),

            TextFormField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter your Username',
              ),
              maxLength: 15,
              controller: hostNameController,
              onChanged: (text) {
                // Resolved type collision safely via Provider mapping
                Provider.of<HostGameState>(context, listen: false).setNames(text);
              },
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: () {
                print("Starting Game with ${_rounds.toInt()} rounds");
                print("Starting Game with answering time: ${_answertimelimit.toInt()}");

                widget.gameState.startGame(_rounds.toInt(), _answertimelimit.toInt());
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              child: const Text("START GAME"),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerWaitingScreen extends StatefulWidget {
  const PlayerWaitingScreen({super.key});

  @override
  State<PlayerWaitingScreen> createState() => _PlayerWaitingScreenState();
}

class _PlayerWaitingScreenState extends State<PlayerWaitingScreen> {
  late Timer _timer;
  int _factIndex = 0;
  final playerNameController = TextEditingController();

  final List<String> _facts = [
    "An octopus has 3 hearts.",
    "Botanically speaking, bananas are berries.",
    "Strawberries are not actually berries, but aggregate fruits.",
    "The Eiffel Tower can grow up to 15 cm in the summer.",
    "In Switzerland, it is illegal to own just one guinea pig.",
    "Honey never spoils. You can eat 3,000-year-old honey.",
    "A day on Venus is longer than a year on Venus.",
    "Nintendo's headquarters were originally built to manufacture playing cards.",
    "Kangaroos cannot walk backwards.",
    "A child asks up to 500 questions a day.",
    "In ancient Rome, urine was an important ingredient in laundry detergents.",
    "The shortest war in history was between Great Britain and Zanzibar – it lasted only 38 minutes and ended in a clear victory for Great Britain.",
    "A shark's teeth constantly grow back, totaling about 30,000 teeth in a shark's lifetime.",
    "The moon has no atmosphere, which is why there are no sounds, wind movements, or weather phenomena.",
    "A human has an average of 1,460 dreams per year. That's 4 per night.",
    "Polar bears have black skin to better absorb the sun's rays.",
    "The first 5 seconds after an earthquake are the most dangerous because this is when the strongest tremors often occur, destabilizing buildings, bridges, and other structures, making the risk of collapse and further damage the highest.",
    "The longest time anyone has held their breath underwater is 24 minutes and 37 seconds.",
    "Lemons float on water, whereas limes sink.",
    "The British Labour Party sings its party anthem to the tune of 'O Tannenbaum' ('O Christmas Tree').",
    "This App was made by Maximilian, Julian and Severin",
  ];

  @override
  void initState() {
    super.initState();
    _facts.shuffle();
    _timer = Timer.periodic(const Duration(seconds: 7), (timer) {
      setState(() {
        _factIndex = (_factIndex + 1) % _facts.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    playerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white70)
                    ),
                    const SizedBox(width: 15),
                    const Text(
                      "Waiting for Host ...",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.2
                      ),
                    ),
                    const SizedBox(width: 50),
                    ElevatedButton(
                      onPressed: () {
                        Provider.of<ClientGameState>(context, listen:false).cancelJoin();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Icon(Icons.cancel_outlined),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white54,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Did you know ?",
                        style: TextStyle(color: Colors.white60, fontSize: 20),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        height: 150,
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder: (Widget child, Animation<double> animation){
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                      begin: const Offset(0.0, 0.2),
                                      end: Offset.zero)
                                      .animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              _facts[_factIndex],
                              key: ValueKey<int>(_factIndex),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 35),

                TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.white),
                    floatingLabelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    labelText: 'Enter your Username',
                    enabledBorder: OutlineInputBorder(
                      borderSide:  BorderSide(color: Colors.white54, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 2.5),
                    ),
                  ),
                  maxLength: 15,
                  controller: playerNameController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (text) {
                    Provider.of<ClientGameState>(context, listen:false).setNames(text);
                  },
                ),

                const Spacer(flex: 3),

                const Text(
                  "LAN Quizduell",
                  style: TextStyle(color: Colors.white24, fontSize: 12),
                ),
              ],
            )
          )
        )
      ),
    );
  }
}
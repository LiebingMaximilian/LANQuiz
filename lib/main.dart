import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bonsoir/bonsoir.dart';
import 'game_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (context) => GameState(),
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

enum Mode { none, host, join }

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController messageController = TextEditingController();
  final TextEditingController ipController = TextEditingController(); // ← moved here
  bool _isDiscovering = false;

  @override
  void dispose() {
    messageController.dispose();
    ipController.dispose();
    Provider.of<GameState>(context, listen: false).stopDiscovery();
    super.dispose();
  }

  Future<void> _startDiscovery(GameState gameState) async {
    print("DEBUG: _startDiscovery called");
    setState(() => _isDiscovering = true);
    await gameState.discoverGames();
  }

  void _stopDiscovery(GameState gameState) {
    gameState.stopDiscovery();
    setState(() => _isDiscovering = false);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);

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
                  label: Text(
                      _isDiscovering ? "Stop Searching" : "Find Games"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor:
                        _isDiscovering ? Colors.orange : Colors.blue,
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
                        style: TextStyle(
                            color: Colors.grey, letterSpacing: 1.2)),
                  ),
                  Expanded(child: Divider()),
                ]),
                const SizedBox(height: 16),
                TextField(
                  controller: ipController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Host IP Address",
                    hintText: "e.g. 192.168.1.50",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lan),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    if (ipController.text.isNotEmpty) {
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

    // ── 2. LOBBY SCREEN ──────────────────────────────────────────────────────
    return Scaffold(
      appBar: AppBar(
        title: Text(gameState.mode == Mode.host
            ? "Lobby (Hosting)"
            : "Lobby (Joined)"),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              // gameState.reset();
            },
          )
        ],
      ),
      body: Column(
        children: [
          if (gameState.mode == Mode.host)
            Container(
              color: Colors.blue.shade50,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text("Your friends should connect to:"),
                  const SizedBox(height: 4),
                  SelectableText(
                    gameState.localIp ?? "Finding IP...",
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: gameState.messages.length,
              itemBuilder: (context, index) => Card(
                child: ListTile(title: Text(gameState.messages[index])),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onSubmitted: (_) {
                        if (messageController.text.isNotEmpty) {
                          gameState.send(messageController.text);
                          messageController.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton(
                    mini: true,
                    onPressed: () {
                      if (messageController.text.isNotEmpty) {
                        gameState.send(messageController.text);
                        messageController.clear();
                      }
                    },
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
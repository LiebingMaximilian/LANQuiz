import 'dart:async';
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'host.dart';
import 'client.dart';
import 'main.dart';

class GameState extends ChangeNotifier {
  // Connection State
  Mode mode = Mode.none;
  String? localIp;
  StreamSubscription? _streamSubscription;
  List<String> messages = [];
  IOWebSocketChannel? channel;

  // Discovery State
  List<BonsoirService> discoveredServices = [];
  BonsoirDiscovery? _discovery;
  BonsoirBroadcast? _broadcast;

  // ── Host ────────────────────────────────────────────────────────────────────

  Future<void> hostGame() async {
    _broadcast = await startBroadcast();
    startSocketServer(
      onMessageReceived: (incomingText) {
        messages.add("Player: $incomingText");
        notifyListeners();
      },
    );
    localIp = await getLocalIpAddress();
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
          messages.add("Host: $msg");
          notifyListeners();
        },
        onError: (error) {
          messages.add("System: Connection Error — $error");
          notifyListeners();
        },
        onDone: () {
          messages.add("System: Disconnected.");
          notifyListeners();
        },
        cancelOnError: true,
      );

      mode = Mode.join;
      notifyListeners();
    } catch (e) {
      messages.add("System: Failed to join — $e");
      notifyListeners();
    }
  }

  // ── Send ────────────────────────────────────────────────────────────────────

  void send(String text) {
    if (mode == Mode.host) {
      broadcastToAll(text);
      messages.add("Me (Host): $text");
    } else {
      channel?.sink.add(text);
      messages.add("Me: $text");
    }
    notifyListeners();
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
}
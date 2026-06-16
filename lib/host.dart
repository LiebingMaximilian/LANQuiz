import 'dart:io';
import 'package:bonsoir/bonsoir.dart';

// platform specific IP-Lookup
Future<String?> getLocalIpAddress() async {
  if (Platform.isAndroid) {
    return await getAndroidIpAddress();
  } else if (Platform.isIOS) {
    return await getIosIpAddress();
  }
  return null;
}

Future<String?> getIosIpAddress() async {
  try {
    List<NetworkInterface> interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );

    final iosInterface = interfaces.firstWhere(
      (interface) => interface.name.toLowerCase() == 'en0',
    );

    return iosInterface.addresses.first.address;
  } catch (e) {
    print("Failed to get ios IP : $e");
    return null;
  }
}

Future<String?> getAndroidIpAddress() async {
  try {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          return addr.address;
        }
      }
    }
  } catch (e) {
    print("Could not find local IP: $e");
  }
  return null;
}

// Returns the broadcast object so the caller can keep it alive
Future<BonsoirBroadcast> startBroadcast() async {
  BonsoirService service = BonsoirService(
    name: "LANQuiz-Lobby",
    type: "_lanquiz._tcp",
    port: 8080,
  );

  BonsoirBroadcast broadcast = BonsoirBroadcast(service: service);

  await broadcast.ready;
  await broadcast.start();

  print("Game is now visible in the network.");

  return broadcast;
}

class ClientConnection {
  final WebSocket socket;
  String? playerId;

  ClientConnection({
    required this.socket,
    this.playerId,
  });
}

final List<ClientConnection> _connectedClients = [];

HttpServer? _server;

Future<void> startSocketServer({
  required Function(WebSocket socket, String message) onMessageReceived,
  required Function(WebSocket socket) onClientDisconnected,
}) async {
  await stopSocketServer();

  _server = await HttpServer.bind(
    InternetAddress.anyIPv4,
    8080,
  );

  print("Server running...");

  _server!.listen((HttpRequest request) async {
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }

    final socket = await WebSocketTransformer.upgrade(request);

    final connection = ClientConnection(socket: socket);

    _connectedClients.add(connection);

    socket.listen(
      (data) {
        onMessageReceived(socket, data.toString());
      },
      onDone: () {
        _connectedClients.remove(connection);
        onClientDisconnected(socket);
      },
      onError: (_) {
        _connectedClients.remove(connection);
        onClientDisconnected(socket);
      },
    );
  });
}

Future<void> stopSocketServer() async {
  if (_server != null) {
    await _server!.close(force: true);
    _server = null;
  }

  for (final client in _connectedClients) {
    await client.socket.close();
  }

  _connectedClients.clear();

  print("stopped server and port is freed");
}

void broadcastToAll(String jsonMessage) {
  for (final client in _connectedClients) {
    client.socket.add(jsonMessage);
  }
}

void registerPlayerSocket(String playerId, WebSocket socket) {
  final connection = _connectedClients.firstWhere(
    (c) => c.socket == socket,
  );

  connection.playerId = playerId;
}

Future<void> kickPlayer(String playerId) async {
  try {
    final connection = _connectedClients.firstWhere(
      (c) => c.playerId == playerId,
    );

    await connection.socket.close(
      WebSocketStatus.normalClosure,
      "Kicked by host",
    );

    _connectedClients.remove(connection);

    print("Kicked player $playerId");
  } catch (_) {
    print("Player $playerId not found");
  }
}

int get clientCount => _connectedClients.length;
import 'dart:io';
import 'package:bonsoir/bonsoir.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<String?> getLocalIpAddress() async {
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
  return broadcast; // ← caller must store this
}

List<WebSocket> _connectedClients = [];

void startSocketServer({required Function(String) onMessageReceived}) async {
  var server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print("Server running...");
  server.transform(WebSocketTransformer()).listen((WebSocket clientSocket) {
    _connectedClients.add(clientSocket);
    clientSocket.listen((data) {
      onMessageReceived(data.toString());
    }, onDone: () {
      _connectedClients.remove(clientSocket);
    });
  });
}

void broadcastToAll(String jsonMessage) {
  for (var player in _connectedClients) {
    player.add(jsonMessage);
  }
}

int get clientCount => _connectedClients.length;
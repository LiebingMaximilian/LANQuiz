import 'dart:io';
import 'package:bonsoir/bonsoir.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

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
// save WebSocketChannel
List<WebSocketChannel> _connectedChannels = [];

void startSocketServer({required Function(String) onMessageReceived}) async {
  var handler = webSocketHandler((WebSocketChannel webSocket) {

    _connectedChannels.add(webSocket);
    print("Player is connected!");

    webSocket.stream.listen(
            (message) {
          onMessageReceived(message.toString());
        },
        onDone: () {
          _connectedChannels.remove(webSocket);
          print("Player disconnected.");
        },
        onError: (error) {
          _connectedChannels.remove(webSocket);
          print("Error at Player: $error");
        }
    );
  });

  // start Server on Port 8080
  var server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('Server läuft auf ws://${server.address.address}:${server.port}');
}

// Send with sink.add
void broadcastToAll(String jsonMessage) {
  for (var channel in _connectedChannels) {
    channel.sink.add(jsonMessage);
  }
}
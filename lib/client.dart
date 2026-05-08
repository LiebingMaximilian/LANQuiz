import 'package:web_socket_channel/io.dart';

IOWebSocketChannel createChannel(String ip) {
  const String url = "ws://10.0.2.2:8080";
  print("client connects to: $url");
  return IOWebSocketChannel.connect(Uri.parse(url));
}

void sendAnswer(IOWebSocketChannel channel, int index) {
  channel.sink.add('{"type": "SUBMIT_ANSWER", "index": $index}');
}


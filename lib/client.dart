import 'package:web_socket_channel/io.dart';

IOWebSocketChannel createChannel(String ip) {
  return IOWebSocketChannel.connect('ws://$ip:8080');
}

void sendAnswer(IOWebSocketChannel channel, int index) {
  channel.sink.add('{"type": "SUBMIT_ANSWER", "index": $index}');
}


import 'package:web_socket_channel/io.dart';

IOWebSocketChannel createChannel(String ip) {
  return IOWebSocketChannel.connect('ws://$ip:8080');
}


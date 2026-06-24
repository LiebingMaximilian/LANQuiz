import 'package:lan_quiz/enums/packet_type.dart';
import 'package:lan_quiz/packets/base_packet.dart';

class GameStatusPacket extends Packet {
  final bool isPaused;

  GameStatusPacket({
    required this.isPaused,
  }) : super(type: isPaused ? PacketType.GAME_PAUSED : PacketType.GAME_RESUMED);

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'isPaused': isPaused,
  };

  factory GameStatusPacket.fromJson(Map<String, dynamic> json) =>
      GameStatusPacket(
        isPaused: json['isPaused'] as bool,
      );
}

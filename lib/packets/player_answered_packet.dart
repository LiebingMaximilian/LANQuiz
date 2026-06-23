import 'package:lan_quiz/packets/base_packet.dart';
import 'package:lan_quiz/enums/packet_type.dart';

class PlayerAnsweredPacket extends Packet {
  final String playerId;

  PlayerAnsweredPacket({
    super.type = PacketType.PLAYER_ANSWERED,
    required this.playerId,
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'playerId': playerId,
  };

  factory PlayerAnsweredPacket.fromJson(Map<String, dynamic> json) =>
      PlayerAnsweredPacket(
        playerId: json['playerId'] as String,
      );
}


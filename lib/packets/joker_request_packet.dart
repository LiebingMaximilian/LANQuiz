import 'package:lan_quiz/enums/joker_type.dart';
import 'package:lan_quiz/enums/packet_type.dart';
import 'package:lan_quiz/packets/base_packet.dart';

class JokerRequestPacket extends Packet{
  String playerId;
  JokerType jokerType;
  String targetId;

  JokerRequestPacket({
    super.type = PacketType.JOKER_REQUEST,
    required this.playerId,
    required this.jokerType,
    required this.targetId,
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'playerId' : playerId,
    'jokerType' : jokerType.name,
    'targetId' : targetId,
  };

  factory JokerRequestPacket.fromJson(Map<String,dynamic> json) =>
      JokerRequestPacket(
        playerId: json['playerId'] as String,
        jokerType: JokerType.values.byName(json['jokerType'] as String),
        targetId: json['targetId'] as String,
      );

}
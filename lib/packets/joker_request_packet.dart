import 'package:lan_quiz/enums/joker_type.dart';
import 'package:lan_quiz/enums/packet_type.dart';
import 'package:lan_quiz/packets/base_packet.dart';

class JokerRequestPacket extends Packet{
  String playerName;
  JokerType jokerType;

  JokerRequestPacket({
    super.type = PacketType.JOKER_REQUEST,
    required this.playerName,
    required this.jokerType,
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'playerName' : playerName,
    'jokerType' : jokerType.name,
  };

  factory JokerRequestPacket.fromJson(Map<String,dynamic> json) =>
      JokerRequestPacket(
        playerName: json['playerName'] as String,
        jokerType: JokerType.values.byName(json['jokerType'] as String),
      );

}
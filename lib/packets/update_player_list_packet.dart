import 'package:lan_quiz/enums/packet_type.dart';
import 'package:lan_quiz/packets/base_packet.dart';

class UpdatePlayerListPacket extends Packet{
  List<Map<String,String>> playerList;

  UpdatePlayerListPacket({
    required this.playerList,
    required super.type,
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'playerList' : playerList,
  };

  factory UpdatePlayerListPacket.fromJson(Map<String,dynamic> json) =>
      UpdatePlayerListPacket(
        playerList: (json['playerList'] as List)
          .map((e) => Map<String,String>.from(e as Map))
          .toList(),
        type: PacketType.UPDATE_PLAYER_LIST,
      );

}
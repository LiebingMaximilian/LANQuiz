import 'package:lan_quiz/enums/joker_type.dart';
import 'package:lan_quiz/enums/packet_type.dart';
import 'package:lan_quiz/packets/base_packet.dart';

class JokerResponsePacket extends Packet{
  String targetPlayerName;
  List<int> answersToHide;
  JokerType jokerType;

  JokerResponsePacket({
    super.type = PacketType.JOKER_RESPONSE,
    required this.targetPlayerName,
    required this.answersToHide,
    required this.jokerType,
  });

  @override
  Map<String,dynamic> toJson() => {
    ...super.toJson(),
    'targetPlayerName' : targetPlayerName,
    'answersToHide' : answersToHide,
    'jokerType' : jokerType.name,
  };

  factory JokerResponsePacket.fromJson(Map<String,dynamic> json) =>
      JokerResponsePacket(
        targetPlayerName: json['targetPlayerName'] as String,
        answersToHide: List<int>.from(json['answersToHide']),
        jokerType: JokerType.values.byName(json['jokerType'] as String),
      );
}
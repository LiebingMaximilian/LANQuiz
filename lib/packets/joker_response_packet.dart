import 'package:lan_quiz/enums/joker_type.dart';
import 'package:lan_quiz/enums/packet_type.dart';
import 'package:lan_quiz/packets/base_packet.dart';

class JokerResponsePacket extends Packet{
  String? targetPlayerId;
  String? sourcePlayerId;
  List<int>? answersToHide;
  JokerType jokerType;

  JokerResponsePacket({
    super.type = PacketType.JOKER_RESPONSE,
    this.targetPlayerId,
    this.sourcePlayerId,
    this.answersToHide,
    required this.jokerType,
  });

  @override
  Map<String,dynamic> toJson() => {
    ...super.toJson(),
    'targetPlayerId' : targetPlayerId,
    'sourcePlayerId' : sourcePlayerId,
    'answersToHide' : answersToHide,
    'jokerType' : jokerType.name,
  };

  factory JokerResponsePacket.fromJson(Map<String,dynamic> json) =>
      JokerResponsePacket(
        targetPlayerId: json['targetPlayerId'] as String?,
        sourcePlayerId: json['sourcePlayerId'] as String?,
        answersToHide: json['answersToHide'] != null
            ? List<int>.from(json['answersToHide'])
            : [],
        jokerType: JokerType.values.byName(json['jokerType'] as String),
      );
}
import 'package:lan_quiz/enums/joker_type.dart';
import 'package:lan_quiz/enums/packet_type.dart';
import 'package:lan_quiz/packets/base_packet.dart';

class JokerResponsePacket extends Packet{
  String? targetPlayerId;
  String? sourcePlayerName;
  List<int>? answersToHide;
  JokerType jokerType;

  JokerResponsePacket({
    super.type = PacketType.JOKER_RESPONSE,
    this.targetPlayerId,
    this.sourcePlayerName,
    this.answersToHide,
    required this.jokerType,
  });

  @override
  Map<String,dynamic> toJson() => {
    ...super.toJson(),
    'targetPlayerId' : targetPlayerId,
    'sourcePlayerName' : sourcePlayerName,
    'answersToHide' : answersToHide,
    'jokerType' : jokerType.name,
  };

  factory JokerResponsePacket.fromJson(Map<String,dynamic> json) =>
      JokerResponsePacket(
        targetPlayerId: json['targetPlayerId'] as String?,
        sourcePlayerName: json['sourcePlayerName'] as String?,
        answersToHide: json['answersToHide'] != null
            ? List<int>.from(json['answersToHide'])
            : [],
        jokerType: JokerType.values.byName(json['jokerType'] as String),
      );
}
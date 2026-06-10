import 'package:lan_quiz/enums/packet_type.dart';
import 'package:lan_quiz/packets/base_packet.dart';

class SubmitAnswerPacket extends Packet {
  String answer;
  String playerName;
  int timeTaken;

  SubmitAnswerPacket({
    super.type = PacketType.SUBMIT_ANSWER,
    required this.answer,
    required this.playerName,
    required this.timeTaken,
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'answer': answer,
    'playerName': playerName,
    'timeTaken': timeTaken,
  };

  factory SubmitAnswerPacket.fromJson(Map<String, dynamic> json) =>
      SubmitAnswerPacket(
        answer: json['answer'] as String,
        playerName: json['playerName'] as String,
        timeTaken: json['timeTaken'] as int,
      );
}
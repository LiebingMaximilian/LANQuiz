import 'package:lan_quiz/enums/packet_type.dart';
import 'package:lan_quiz/packets/base_packet.dart';
import 'package:uuid/uuid.dart';

class ShowCorrectAnswerPacket extends Packet{
  int correctAnswerIndex;
  Map<String,String> playerAnswers;


  ShowCorrectAnswerPacket({
    super.type = PacketType.CORRECT_ANSWER,
    required this.correctAnswerIndex,
    required this.playerAnswers,
  });

  @override
  Map<String,dynamic> toJson() => {
    ...super.toJson(),
    'correctAnswerIndex' : correctAnswerIndex,
    'playerAnswers' : playerAnswers,
  };

  factory ShowCorrectAnswerPacket.fromJson(Map<String,dynamic> json) =>
    ShowCorrectAnswerPacket(
      correctAnswerIndex: json['correctAnswerIndex'] as int,
      playerAnswers: Map<String,String>.from(json['playerAnswers'] as Map),
    );

}
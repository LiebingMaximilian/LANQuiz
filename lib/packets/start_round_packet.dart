import 'package:lan_quiz/enums/packet_type.dart';
import 'package:lan_quiz/packets/base_packet.dart';

class StartRoundPacket extends Packet {
  int round;
  int rounds;
  int timeLimit;
  String question;
  List<String> answers;


  StartRoundPacket({
    super.type = PacketType.START_ROUND,
    required this.round,
    required this.rounds,
    required this.timeLimit,
    required this.question,
    required this.answers,
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'round': round,
    'rounds': rounds,
    'timeLimit': timeLimit,
    'question': question,
    'answers': answers,
  };

  factory StartRoundPacket.fromJson(Map<String, dynamic> json) =>
      StartRoundPacket(
        round: json['round'] as int,
        rounds: json['rounds'] as int,
        timeLimit: json['timeLimit'] as int,
        question: json['question'] as String,
        answers: List<String>.from(json['answers']),
      );
}
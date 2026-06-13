import 'package:lan_quiz/client_question.dart';
import 'package:lan_quiz/enums/packet_type.dart';
import 'package:lan_quiz/packets/joker_request_packet.dart';
import 'package:lan_quiz/packets/joker_response_packet.dart';
import 'package:lan_quiz/packets/show_correct_answer_packet.dart';
import 'package:lan_quiz/packets/show_leaderboard_packet.dart';
import 'package:lan_quiz/packets/start_round_packet.dart';
import 'package:lan_quiz/packets/submit_answer_packet.dart';

class Packet {
  PacketType type;
  Packet({required this.type});

  Map<String, dynamic> toJson() => {
    'type': type.name,
  };

  /// Decode any packet — returns the correct subclass based on 'type'
  static Packet fromJson(Map<String, dynamic> json) {
    final type = PacketType.values.byName(json['type'] as String);
    switch (type) {
      case PacketType.START_ROUND:
        return StartRoundPacket.fromJson(json);
      case PacketType.SHOW_LEADERBOARD:
        return ShowLeaderboardPacket.fromJson(json);
      case PacketType.SUBMIT_ANSWER:
        return SubmitAnswerPacket.fromJson(json);
      case PacketType.JOKER_REQUEST:
        return JokerRequestPacket.fromJson(json);
      case PacketType.JOKER_RESPONSE:
        return JokerResponsePacket.fromJson(json);
      case PacketType.CORRECT_ANSWER:
        return ShowCorrectAnswerPacket.fromJson(json);
    }
  }
}
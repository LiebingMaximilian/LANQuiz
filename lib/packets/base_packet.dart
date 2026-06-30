import 'package:lan_quiz/enums/packet_type.dart';
import 'package:lan_quiz/packets/game_status_packet.dart';
import 'package:lan_quiz/packets/joker_request_packet.dart';
import 'package:lan_quiz/packets/joker_response_packet.dart';
import 'package:lan_quiz/packets/player_answered_packet.dart';
import 'package:lan_quiz/packets/register_packet.dart';
import 'package:lan_quiz/packets/show_correct_answer_packet.dart';
import 'package:lan_quiz/packets/show_leaderboard_packet.dart';
import 'package:lan_quiz/packets/start_round_packet.dart';
import 'package:lan_quiz/packets/submit_answer_packet.dart';
import 'package:lan_quiz/packets/update_player_list_packet.dart';

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
      case PacketType.REGISTER:
        return RegisterPacket.fromJson(json);
      case PacketType.UPDATE_PLAYER_LIST:
        return UpdatePlayerListPacket.fromJson(json);
      case PacketType.PLAYER_ANSWERED:
        return PlayerAnsweredPacket.fromJson(json);
      case PacketType.GAME_PAUSED:
        return GameStatusPacket.fromJson(json);
      case PacketType.GAME_RESUMED:
        return GameStatusPacket.fromJson(json);
    }
  }
}
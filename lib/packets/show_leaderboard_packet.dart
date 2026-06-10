import 'package:lan_quiz/enums/packet_type.dart';
import 'package:lan_quiz/packets/base_packet.dart';
import 'package:lan_quiz/screens/leaderboard_screen.dart';

class ShowLeaderboardPacket extends Packet {
  List<LeaderboardEntry> entries;
  int time;
  bool isFinalLeaderboard;

  ShowLeaderboardPacket({
    super.type = PacketType.SHOW_LEADERBOARD,
    required this.time,
    required this.entries,
    required this.isFinalLeaderboard,
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'time': time,
    'entries': entries.map((e) => e.toJson()).toList(),
    'isFinalLeaderboard': isFinalLeaderboard,
  };

  factory ShowLeaderboardPacket.fromJson(Map<String, dynamic> json) =>
      ShowLeaderboardPacket(
        time: json['time'] as int,
        isFinalLeaderboard: json['isFinalLeaderboard'] as bool,
        entries: (json['entries'] as List)
            .map((e) => LeaderboardEntry.fromJson(e))
            .toList(),
      );
}
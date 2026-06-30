import 'package:lan_quiz/enums/packet_type.dart';
import 'package:lan_quiz/packets/base_packet.dart';

class JoinRejectedPacket extends Packet {
  String message;

  JoinRejectedPacket({
    super.type = PacketType.JOIN_REJECTED,
    required this.message,
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'message' : message,
  };

  factory JoinRejectedPacket.fromJson(Map<String, dynamic> json) {
    return JoinRejectedPacket(
      message: json['message'] as String,
    );
  }

}
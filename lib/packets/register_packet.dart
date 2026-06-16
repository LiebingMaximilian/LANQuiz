import 'package:lan_quiz/enums/packet_type.dart';
import 'package:lan_quiz/packets/base_packet.dart';

class RegisterPacket extends Packet{
  String name;
  String id;

  RegisterPacket({
    super.type = PacketType.REGISTER,
    required this.name,
    required this.id,
  });

  @override
  Map<String,dynamic> toJson() => {
    ...super.toJson(),
    'name' : name,
    'id' : id,
  };

  factory RegisterPacket.fromJson(Map<String,dynamic> json) =>
    RegisterPacket(
      name: json['name'] as String,
      id: json['id'] as String,
    );
}
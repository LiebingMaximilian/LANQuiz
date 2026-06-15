import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> answerSelected() async {
    await _player.play(AssetSource('sounds/answerSelected.mp3'));
  }
  static Future<void> answerCorrect() async {
    await _player.play(AssetSource('sounds/correctAnswer.mp3'));
  }
}
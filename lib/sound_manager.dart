import 'package:audioplayers/audioplayers.dart';
bool isSoudEnabled = true;

 void audioInit() async{
   await AudioPlayer.global.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient, //so it does't interrupt music and respects silence mode
    ),
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification, //sonification is for user action therefore doesnt interrupt music
      usageType: AndroidUsageType.assistanceSonification,
      audioFocus: AndroidAudioFocus.none,  //important says android it doesnt want audio focus at all

    ),
    ));
    print("audioconfig initialized");
  }

class SoundManager {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> answerSelected() async {
    if(!isSoudEnabled){return;}
    await _player.play(AssetSource('sounds/answerSelected.mp3'));
  }
  static Future<void> answerCorrect() async {
    if(!isSoudEnabled){return;}
    await _player.play(AssetSource('sounds/correctAnswer.mp3'));
  }
}
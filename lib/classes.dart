import 'package:lan_quiz/api_connector.dart';
import 'package:lan_quiz/leaderboard.dart';

class ClientQuestion{
  String question = "";
  List<String> answers = [];
  int correctIndex = -1;
  ClientQuestion({required this.question, required  this.answers, required this.correctIndex});

  static ClientQuestion QuestionToClientQuestion(Question question){
    List<String> allAnswers = [question.correctAnswer, ...question.incorrectAnswers]; 

    allAnswers.shuffle();

    int correctIndex = allAnswers.indexOf(question.correctAnswer);

    return ClientQuestion(question:question.question, answers:allAnswers, correctIndex:correctIndex );
  }
}


enum PacketType {
  START_ROUND,
  SHOW_LEADERBOARD,
  SUBMIT_ANSWER,
  JOKER_REQUEST,
  JOKER_RESPONSE,
}

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
    }
  }
}

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

enum JokerType{
  FIFTY_FIFTY,
  // TODO: add more Joker
}

class JokerRequestPacket extends Packet{
  String playerName;
  JokerType jokerType;

  JokerRequestPacket({
    super.type = PacketType.JOKER_REQUEST,
    required this.playerName,
    required this.jokerType,
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'playerName' : playerName,
    'jokerType' : jokerType.name,
  };

  factory JokerRequestPacket.fromJson(Map<String,dynamic> json) =>
      JokerRequestPacket(
        playerName: json['playerName'] as String,
        jokerType: JokerType.values.byName(json['jokerType'] as String),
      );

}

class JokerResponsePacket extends Packet{
  String targetPlayerName;
  List<int> answersToHide;
  JokerType jokerType;

  JokerResponsePacket({
    super.type = PacketType.JOKER_RESPONSE,
    required this.targetPlayerName,
    required this.answersToHide,
    required this.jokerType,
  });

  @override
  Map<String,dynamic> toJson() => {
    ...super.toJson(),
    'targetPlayerName' : targetPlayerName,
    'answersToHide' : answersToHide,
    'jokerType' : jokerType.name,
  };

  factory JokerResponsePacket.fromJson(Map<String,dynamic> json) =>
      JokerResponsePacket(
        targetPlayerName: json['targetPlayerName'] as String,
        answersToHide: List<int>.from(json['answersToHide']),
        jokerType: JokerType.values.byName(json['jokerType'] as String),
      );
}

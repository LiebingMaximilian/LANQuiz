import 'package:lan_quiz/api_connector.dart';
import 'package:lan_quiz/screens/leaderboard_screen.dart';

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



















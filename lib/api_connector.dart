import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

/*USAGE: List<Question> varName = await fetchQuestions(amount of questions);
varName[questionNum].type for the type of question
varName[questionNum].question for the question string
varName[questionNum].correctAnswer for the correct Answer
varName[questionNum].incorrectAnswers for the incorrect Answer

for later use .difficulty, .category are also available
*/

String? token = "3b3"; //false token, let the code create a new one through the exception
int excCntr = 0;


class QuestionData{  //because the api is staged we have to first handle responsecodes
  final int responseCode;
  final List<Question> questions; //and make the rest into a list to handle in the other class



  const QuestionData({
    required this.responseCode,
    required this.questions,
  });

  factory QuestionData.fromJson(Map<String, dynamic> json){
    return QuestionData(
      responseCode: json['response_code'], //decoding response code
      questions: List<Question>.from(
        json['results'].map((x) => Question.fromJson(x)),
      ),
    );
  }
}

class Question { //question class with all available information
  final String type;
  final String difficulty;
  final String category;
  final String question;
  final String correctAnswer;
  final List<String> incorrectAnswers;

  const Question({
    required this.type,
    required this.difficulty,
    required this.category,
    required this.question,
    required this.correctAnswer,
    required this.incorrectAnswers,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      type: json['type'],
      difficulty: json['difficulty'],
      category: json['category'],
      question: json['question'],
      correctAnswer: json['correct_answer'],
      incorrectAnswers: List<String>.from(json['incorrect_answers']),
    );
  }
}


Future<List<Question>> fetchQuestions(int amountQuestions) async { // fetches and returns questions.
  if(amountQuestions > 0 || amountQuestions < 100) {
    final String url = 'https://opentdb.com/api.php?amount=$amountQuestions' +
        (token != null ? '&token=' : '');
    final response = await http.get(
        Uri.parse(url)
    );

    if (response.statusCode ==
        200) { //if server returned 200 OK response, parse json to map
      final data = QuestionData.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
      switch (data.responseCode) {
        case 0: //OK return questions
          if(excCntr != 0) {
            excCntr = 0; //resetting exception counter;
          }
          return data.questions;
        case 1: //no questions left
          throw Exception("No Results, not enough questions left");
        case 2: // invalid url
          throw Exception("Invalid Parameter");
        case 3:
        //creates token when token is invalid
          Token newToken = await createToken();
          token = newToken.token;
          return fetchQuestions(amountQuestions);
        case 4: // no questions available who havent been used - reset token
          //getting new token and replacing it
        //TODO: Error message in user interface telling user token has been reset
          Token newToken = await createToken();
          token = newToken.token;
        return fetchQuestions(amountQuestions);

        case 5: //too fast request, probably not used anymore because the statuscode handles that with 429
        if(excCntr < 3) {
          excCntr++; //exception counter
          await Future.delayed(Duration(seconds: 5));
          return fetchQuestions(amountQuestions);
        } else {
          excCntr = 0;
          throw Exception("Unknown error, failed 3 times fetching questions");
        }
        default: //unknown code
          throw Exception("Unknown Error: code ${data.responseCode}");
      }
    } else if (response.statusCode == 429) { //handles too fast requests
      if(excCntr < 3) {
        excCntr++; //exception counter
        await Future.delayed(Duration(seconds: 5));
        return fetchQuestions(amountQuestions);
      } else {
        excCntr = 0;
        throw Exception("Unknown error, failed 3 times fetching questions");
      }
    } else {
      throw Exception('http request failed'); //unknown error
    }
  } else {
    throw Exception("Invalid question count");
  }
}
class Token{ //token class for handling tokens
  final String token;
  const Token({required this.token});
  factory Token.fromJson(Map<String, dynamic> json) {
    return Token(
    token: json['token'],
    );
  }
}
Future<Token> createToken() async{ //fetching tokens
  final response = await http.get(Uri.parse("https://opentdb.com/api_token.php?command=request"));
  if(response.statusCode == 200){
    return Token.fromJson(jsonDecode(response.body));
  } else {
    throw Exception("Unknown Error token creator");
  }
}
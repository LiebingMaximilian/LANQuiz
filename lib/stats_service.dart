
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


final QuizStatsController statsController = QuizStatsController();

class QuizStatsController{
  UserStatistics cachedStats = UserStatistics();
  String? _currentCategory;



  Future<void> init() async {
    final data = await SharedPreferences.getInstance();
    final jsonString = data.getString('user_stats');
    if(jsonString != null){
      cachedStats = UserStatistics.fromJson(jsonDecode(jsonString));
    }
  }
  void newQuestion(String category){

    _currentCategory = category;
    print("Tracked new question");
    print(cachedStats.globalTotalQuestions);
    cachedStats.globalTotalQuestions = (cachedStats.globalTotalQuestions ?? 0)+1;
    print(cachedStats.globalTotalQuestions);
    CategoryStats cat = cachedStats.categoryStats.putIfAbsent(category, ()=> CategoryStats());
    cat.totalQuestions = (cat.totalQuestions ?? 0) +1;
  }

  void trackAnswertime(int timeInS){
    if(_currentCategory == null) return;
    int globalCount = (cachedStats.globalAnsweredQuestions ?? 0) +1;
    cachedStats.globalAnsweredQuestions = globalCount;
    double currGlobalAvg = cachedStats.globalAverageAnswerTime ?? 0.0;
    cachedStats.globalAverageAnswerTime = currGlobalAvg +((timeInS - currGlobalAvg)/globalCount);

    CategoryStats cat = cachedStats.categoryStats[_currentCategory!]!;
    int catCount =(cat.answeredQuestions ?? 0) +1;
    cat.answeredQuestions = catCount;
    double currCatAvg = cat.averageAnswerTime ?? 0.0;
    cat.averageAnswerTime = currCatAvg + ((timeInS - currCatAvg)/catCount);
    print("tracked Answer time");
  }

  void trackJokers(bool isUsed){
    if(_currentCategory == null) return;
    if(isUsed){
    int globalJokers = (cachedStats.jokersUsed ?? 0) +1;
    cachedStats.jokersUsed = globalJokers;
    print("Tracked Joker");
    }
  }

  Future<void> trackRoundRes(bool isCorrect) async {
    if(_currentCategory == null) return;

    if(isCorrect) {
      cachedStats.globalCorrectAnswers = (cachedStats.globalCorrectAnswers ?? 0) +1;
      CategoryStats cat = cachedStats.categoryStats[_currentCategory!]!;
      cat.correctAnswers = (cat.correctAnswers ?? 0) +1;
      print("tracked Correct Answer");
    }

    _currentCategory = null;

    final data = await SharedPreferences.getInstance();
    await data.setString('user_stats', jsonEncode(cachedStats.toJson()));
    print("saved data");
  }


}



class CategoryStats{
  int? totalQuestions;
  int?answeredQuestions;
  int?correctAnswers;
  double? averageAnswerTime; 


CategoryStats({
  this.totalQuestions = 0,
  this.answeredQuestions = 0,
  this.correctAnswers = 0,
  this.averageAnswerTime = 0.0,
});

factory CategoryStats.fromJson(Map<String, dynamic> json){
  return CategoryStats(
    totalQuestions: json['totalQuestions'] ?? 0,
    answeredQuestions: json['answeredQuestions'] ?? 0,
    correctAnswers: json['correctAnswers'] ?? 0,
    averageAnswerTime: (json['averageAnswerTime'] as num?)?.toDouble() ?? 0.0,
  );
}

Map<String, dynamic> toJson(){
  return{
    'totalQuestions' : totalQuestions,
    'answeredQuestions' : answeredQuestions,
    'correctAnswers' : correctAnswers,
    'averageAnswerTime' : averageAnswerTime,
  };
}

}

class UserStatistics{
  int? globalTotalQuestions;
  int? globalAnsweredQuestions;
  int? globalCorrectAnswers;
  int? jokersUsed;
  double? globalAverageAnswerTime;
  Map<String, CategoryStats> categoryStats;

  UserStatistics({
    this.globalTotalQuestions = 0,
    this.globalAnsweredQuestions = 0,
    this.globalCorrectAnswers = 0,
    this.jokersUsed = 0,
    this.globalAverageAnswerTime = 0.0,
    Map<String, CategoryStats>? categoryStats,
  }) : categoryStats = categoryStats ?? {};

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    final mapData = json['categoryStats'] as Map<String, dynamic>? ?? {};
    final parsedCategoryStats = mapData.map((key, value) => MapEntry(key, CategoryStats.fromJson(value as Map<String, dynamic>)),
    );

    return UserStatistics(
      globalTotalQuestions: json['globalTotalQuestions'] ?? 0,
      globalAnsweredQuestions: json['globalAnsweredQuestions'] ?? 0,
      globalCorrectAnswers: json['globalCorrectAnswers'] ?? 0,
      jokersUsed: json['jokersUsed'] ?? 0,
      globalAverageAnswerTime: (json['globalAverageAnswerTime'] as num?)?.toDouble() ?? 0.0,
      categoryStats: parsedCategoryStats,
    );
  }
  Map<String, dynamic> toJson(){
    final jsonCategoryStats = categoryStats?.map((key, value) => MapEntry(key, value.toJson()),) ?? {};
    return{
      'globalTotalQuestions' : globalTotalQuestions,
      'globalAnsweredQuestions' : globalAnsweredQuestions,
      'globalCorrectAnswers' : globalCorrectAnswers,
      'jokersUsed' : jokersUsed,
      'globalAverageAnswerTime' : globalAverageAnswerTime,
      'categoryStats' : jsonCategoryStats,
    };
  }
}



import 'package:flutter/material.dart';
import 'package:lan_quiz/stats_service.dart';

class PlayerStatisticScreen extends StatefulWidget {
  const PlayerStatisticScreen({super.key});

  @override
  State<PlayerStatisticScreen> createState() => _PlayerStatisticScreenState();
}

class _PlayerStatisticScreenState extends State<PlayerStatisticScreen> {
  final statsData = statsController.cachedStats;
  List<String> get categories => statsData.categoryStats.keys.toList();
  initState(){
    super.initState();

  }

  

  @override
  Widget build(BuildContext context) {
    final answertimeInS = ((statsData.globalAverageAnswerTime)! / 1000).toStringAsFixed(2);
    return Scaffold(
      appBar: AppBar(title: const Text("Statistics")),
      //body: const Center(child: Text("Player Statistics Screen")),
      //TODO: store, calculate and display player statistics,
      body: Column(
        children: [
             ListTile(
            title: Text("Total Questions: "),
            subtitle: Text(statsData.globalTotalQuestions.toString()),
          ),  
          ListTile(
            title: Text("Answered Questions: "),
            subtitle: Text(statsData.globalAnsweredQuestions.toString()),
          ), 
          ListTile(
            title: Text("Average Answer Time: "),
            subtitle: Text("${answertimeInS.toString()} seconds"),
          ), 
          ListTile(
            title: Text("Jokers Used: "),
            subtitle: Text(statsData.jokersUsed.toString()),
          ),       
          Expanded(
            child: categories.isEmpty
                ? const Center(child: Text("Play some games to see your stats!"))
                : ListView.builder(
                    itemCount: categories.length, 
                    itemBuilder: (context, index) {
                      final categoryName = categories[index]; 
                      final catData = statsData.categoryStats[categoryName]!;

                      int answered = catData.answeredQuestions ?? 0;
                      int correct = catData.correctAnswers ?? 0;
                      double accuracy = answered > 0 ? (correct / answered) * 100 : 0.0;

                      return ListTile(
                        title: Text(categoryName ),
                        subtitle: Text("Accuracy: ${accuracy.toStringAsFixed(0)}%"),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
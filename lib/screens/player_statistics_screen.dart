
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

    int answered = statsData.globalAnsweredQuestions ?? 0;
    int correct = statsData.globalCorrectAnswers ?? 0;
    double globalAccuracy = answered > 0 ? (correct / answered) * 100 : 0.0;
    return Scaffold(
      appBar: AppBar(title: const Text("Statistics")),
      body:SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             SizedBox(height: 0),
                 Row(children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("General Stats",
                        style: TextStyle(
                            color: Colors.grey, letterSpacing: 1.2)),
                  ),
                  Expanded(child: Divider()),
                ]),
            Padding(padding: EdgeInsets.all(6.0),
            child: Row(
              children: [
                 Text("Total Questions: ${statsData.globalTotalQuestions.toString()}",
                 style: TextStyle(fontSize:  16, fontWeight: FontWeight.bold)),
              ],
            ),
            ),
            Padding(padding: EdgeInsets.all(6.0),
            child: Row(
              children: [
                 Text("Answered Questions: ${statsData.globalAnsweredQuestions.toString()}",
                 style: TextStyle(fontSize:  16, fontWeight: FontWeight.bold)),
              ],
            ),
            ),
            Padding(padding: EdgeInsets.all(6.0),
            child: Row(
              children: [
                 Text("Accuracy: ${globalAccuracy.toStringAsFixed(2)}%",
                 style: TextStyle(fontSize:  16, fontWeight: FontWeight.bold)),
              ],
            ),
            ),
            Padding(padding: EdgeInsets.all(6.0),
            child: Row(
              children: [
                 Text("Average Answer Time: ${answertimeInS.toString()} Seconds",
                 style: TextStyle(fontSize:  16, fontWeight: FontWeight.bold)),
              ],
            ),
            ),
            Padding(padding: EdgeInsets.all(6.0),
            child: Row(
              children: [
                 Text("Jokers Used: ${statsData.jokersUsed.toString()}",
                 style: TextStyle(fontSize:  16, fontWeight: FontWeight.bold)),
              ],
            ),
            ),
             SizedBox(height: 6),
                 Row(children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("Category Stats",
                        style: TextStyle(
                            color: Colors.grey, letterSpacing: 1.2)),
                  ),
                  Expanded(child: Divider()),
                ]),
                categories.isEmpty
                ? const Center(child: Text("No stats available, play some games to see them!"))
                : (() {
                    final sortedCategories = List<String>.from(categories);
                    sortedCategories.sort((a, b) {
                      final dataA = statsData.categoryStats[a]!;
                      final dataB = statsData.categoryStats[b]!;
                      double accuracyA = (dataA.answeredQuestions ?? 0) > 0 
                          ? ((dataA.correctAnswers ?? 0) / dataA.answeredQuestions!) * 100 
                          : 0.0;                          
                      double accuracyB = (dataB.answeredQuestions ?? 0) > 0 
                          ? ((dataB.correctAnswers ?? 0) / dataB.answeredQuestions!) * 100 
                          : 0.0;
                      return accuracyB.compareTo(accuracyA); 
                    });
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedCategories.length, 
                      itemBuilder: (context, index) {
                        final categoryName = sortedCategories[index]; 
                        final catData = statsData.categoryStats[categoryName]!;
                        int answered = catData.answeredQuestions ?? 0;
                        int correct = catData.correctAnswers ?? 0;
                        double accuracy = answered > 0 ? (correct / answered) * 100 : 0.0;
                        return ListTile(
                          visualDensity: VisualDensity.compact,
                          title: Text(categoryName),
                          subtitle: Text("Accuracy: ${accuracy.toStringAsFixed(0)}%"),
                        );
                      },
                    );
                  }()), 


            
          ],
          ),
        
        ),
      ),
      //body: const Center(child: Text("Player Statistics Screen")),
      //TODO: store, calculate and display player statistics,
      /*body: Column(
        children: [
             ListTile(
            title: Text("Total Questions: ${statsData.globalTotalQuestions.toString()}"),
          ),  
          ListTile(
            title: Text("Answered Questions: ${statsData.globalAnsweredQuestions.toString()}"),
          ),
          ListTile(
            title: Text("Accuracy: ${globalAccuracy.toStringAsFixed(0)}%"),
          ), 
          ListTile(
            title: Text("Average Answer Time: ${answertimeInS.toString()} Seconds"),
          ), 
          ListTile(
            title: Text("Jokers Used: ${statsData.jokersUsed.toString()}"),
          ),       
          const SizedBox(height: 24),
                const Row(children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("Category Stats",
                        style: TextStyle(
                            color: Colors.grey, letterSpacing: 1.2)),
                  ),
                  Expanded(child: Divider()),
                ]),
          Expanded(
            child: categories.isEmpty
                ? const Center(child: Text("No stats available, play some games to see them!"))
                : (() {
                    final sortedCategories = List<String>.from(categories);
                    sortedCategories.sort((a, b) {
                      final dataA = statsData.categoryStats[a]!;
                      final dataB = statsData.categoryStats[b]!;
                      double accuracyA = (dataA.answeredQuestions ?? 0) > 0 
                          ? ((dataA.correctAnswers ?? 0) / dataA.answeredQuestions!) * 100 
                          : 0.0;                          
                      double accuracyB = (dataB.answeredQuestions ?? 0) > 0 
                          ? ((dataB.correctAnswers ?? 0) / dataB.answeredQuestions!) * 100 
                          : 0.0;
                      return accuracyB.compareTo(accuracyA); 
                    });
                    return ListView.builder(
                      itemCount: sortedCategories.length, 
                      itemBuilder: (context, index) {
                        final categoryName = sortedCategories[index]; 
                        final catData = statsData.categoryStats[categoryName]!;
                        int answered = catData.answeredQuestions ?? 0;
                        int correct = catData.correctAnswers ?? 0;
                        double accuracy = answered > 0 ? (correct / answered) * 100 : 0.0;
                        return ListTile(
                          title: Text(categoryName),
                          subtitle: Text("Accuracy: ${accuracy.toStringAsFixed(0)}%"),
                        );
                      },
                    );
                  }()), 
          ),
        ],
      ),*/
    );
  }
}
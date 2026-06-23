import 'package:flutter/material.dart';
import 'package:lan_quiz/api_connector.dart';
import 'package:lan_quiz/gameState/host_game_state.dart';
import 'package:lan_quiz/screens/home_menu_screen.dart';
import 'package:provider/provider.dart';
import 'package:lan_quiz/screens/player_management_screen.dart';
class HostSettingsScreen extends StatefulWidget{
  final HostGameState gameState;
  const HostSettingsScreen({super.key, required this.gameState});

  @override
  State<HostSettingsScreen> createState() => _HostSettingsScreenState();
}

class _HostSettingsScreenState extends State<HostSettingsScreen> {
  bool onStartPressed = false; //to prevent double pressing
  late Future<List<TriviaCategory>> _categoriesFuture;
  TriviaCategory? selectedCategory;
  @override
  void initState() {
    super.initState();
    _categoriesFuture = fetchCategories();
    onStartPressed = false; //set it to false when screen loads
    isHostButtonPressed = false;
  }


  double _rounds = 10; // Presetting
  double _answertimelimit = 20;
  final hostNameController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<HostGameState>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.people),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerManagementScreen()));
          },
        ),
        title: const Text("Game Settings"),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
               Provider.of<HostGameState>(context, listen: false).endGame();
              // cancel game later, return to Homescreen
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi, color: Colors.blue),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Spieler können beitreten über: "),
                      Text(
                         widget.gameState.localIp ?? "Loading IP ...",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            // TODO add more Setting for Jokers, SpecialRounds, etc.
            Text(
              "Number of Rounds: ${_rounds.toInt()}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _rounds,
              min: 2,
              max: 30,
              divisions: 25,
              label: _rounds.toInt().toString(),
              onChanged: (double value){
                setState(() {
                  _rounds = value;
                });
              },
            ),

            const SizedBox(height: 40),
            Text(
              "Answering Time limit: ${_answertimelimit.toInt()} sec",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _answertimelimit,
              min: 5,
              max: 60,
              divisions: 55,
              label: _answertimelimit.toInt().toString(),
              onChanged: (double value){
                setState(() {
                  _answertimelimit = value;
                });
              },
            ),
            const SizedBox(height: 40),
            Text("Category",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
              FutureBuilder<List<TriviaCategory>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 56, 
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Text("Error loading categories");
                  }

                  final categoryList = snapshot.data!;

                  return DropdownMenu<TriviaCategory>(
                    initialSelection: categoryList.first, 
                    onSelected: (TriviaCategory? category) {
                      setState(() {
                        selectedCategory = category;
                        
                        widget.gameState.categoryId = category?.id; 
                      });
                    },
                    dropdownMenuEntries: categoryList.map((category) {
                      return DropdownMenuEntry<TriviaCategory>(
                        value: category,
                        label: category.name,
                      );
                    }).toList(),
                  );
                },
              ),

            const Spacer(),

            ElevatedButton(
                onPressed: (){
                  // Start Game
                  if(onStartPressed == false){
                    onStartPressed = true; //so only one press gets registered
                  print("Starting Game with ${_rounds.toInt()} rounds");
                  print("Staring Game with answering time: ${_answertimelimit.toInt()}");
                  widget.gameState.startGame(_rounds.toInt(), _answertimelimit.toInt());
                  }

                },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              child: const Text("START GAME"),
            ),
          ],
        ),
      ),
    );
  }
}
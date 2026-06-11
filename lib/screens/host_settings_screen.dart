import 'package:flutter/material.dart';
import 'package:lan_quiz/gameState/host_game_state.dart';
import 'package:provider/provider.dart';
class HostSettingsScreen extends StatefulWidget{
  final HostGameState gameState;
  const HostSettingsScreen({super.key, required this.gameState});

  @override
  State<HostSettingsScreen> createState() => _HostSettingsScreenState();
}

class _HostSettingsScreenState extends State<HostSettingsScreen> {
  double _rounds = 10; // Presetting
  double _answertimelimit = 20;
  final hostNameController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<HostGameState>();

    return Scaffold(
      appBar: AppBar(
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

            const SizedBox(height: 15),

            TextFormField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter your Username',
              ),
              maxLength: 15,
              controller: hostNameController,
              onChanged: (text) {
                Provider.of<HostGameState>(context, listen:false).setNames(text);
              },
            ),

            const Spacer(),

            ElevatedButton(
                onPressed: (){
                  // Start Game
                  print("Starting Game with ${_rounds.toInt()} rounds");
                  print("Staring Game with answering time: ${_answertimelimit.toInt()}");

                  widget.gameState.startGame(_rounds.toInt(), _answertimelimit.toInt());

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
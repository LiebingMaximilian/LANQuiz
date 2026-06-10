import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lan_quiz/gameState/host_game_state.dart';
import 'package:provider/provider.dart';

class PlayerWaitingScreen extends StatefulWidget {
  const PlayerWaitingScreen({super.key});

  @override
  State<PlayerWaitingScreen> createState() => _PlayerWaitingScreenState();
}

class _PlayerWaitingScreenState extends State<PlayerWaitingScreen>{
  late Timer _timer;
  int _factIndex = 0;
  final playerNameController = TextEditingController();


  final List<String> _facts = [
    "An octopus has 3 hearts.",
    "Botanically speaking, bananas are berries.",
    "Strawberries are not actually berries, but aggregate fruits.",
    "The Eiffel Tower can grow up to 15 cm in the summer.",
    "In Switzerland, it is illegal to own just one guinea pig.",
    "Honey never spoils. You can eat 3,000-year-old honey.",
    "A day on Venus is longer than a year on Venus.",
    "Nintendo's headquarters were originally built to manufacture playing cards.",
    "Kangaroos cannot walk backwards.",
    "A child asks up to 500 questions a day.",
    "In ancient Rome, urine was an important ingredient in laundry detergents.",
    "The shortest war in history was between Great Britain and Zanzibar – it lasted only 38 minutes and ended in a clear victory for Great Britain.",
    "A shark's teeth constantly grow back, totaling about 30,000 teeth in a shark's lifetime.",
    "The moon has no atmosphere, which is why there are no sounds, wind movements, or weather phenomena.",
    "A human has an average of 1,460 dreams per year. That's 4 per night.",
    "Polar bears have black skin to better absorb the sun's rays.",
    "The first 5 seconds after an earthquake are the most dangerous because this is when the strongest tremors often occur, destabilizing buildings, bridges, and other structures, making the risk of collapse and further damage the highest.",
    "The longest time anyone has held their breath underwater is 24 minutes and 37 seconds.",
    "Lemons float on water, whereas limes sink.",
    "The British Labour Party sings its party anthem to the tune of 'O Tannenbaum' ('O Christmas Tree')."
    "This App was made by Maximilian, Julian and Severin",
  ];

  @override
  void initState(){
    super.initState();
    _facts.shuffle();
    _timer = Timer.periodic(const Duration(seconds: 7), (timer){
      setState(() {
        _factIndex = (_factIndex + 1) % _facts.length;
      });
    });
  }

  @override
  void dispose(){
    _timer.cancel();
    playerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white70)
                    ),
                    SizedBox(width: 15),
                    Text(
                      "Waiting for Host ...",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.2
                      ),
                    ),
                    const SizedBox(width: 50),
                    ElevatedButton(
                      onPressed: () {
                        Provider.of<HostGameState>(context, listen:false).cancelJoin();
                        },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Icon(Icons.cancel_outlined),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
                const SizedBox(height: 20),

                // Facts w Animation
                Container(
                  padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white54,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                      child: Column(
                        children: [
                          const Text(
                            "Did you know ?",
                            style: TextStyle(color: Colors.white60, fontSize: 20),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            height: 150,
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                transitionBuilder: (Widget child, Animation<double> animation){
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                          begin: const Offset(0.0, 0.2),
                                          end: Offset.zero)
                                          .animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Text(
                                  _facts[_factIndex],
                                  key: ValueKey<int>(_factIndex),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
                  ),
                const SizedBox(height: 35),

                TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.white),
                    floatingLabelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    labelText: 'Enter your Username',
                    enabledBorder: OutlineInputBorder(
                      borderSide:  BorderSide(color: Colors.white54, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 2.5),
                    ),
                  ),
                  maxLength: 15,
                  controller: playerNameController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (text) {
                    Provider.of<HostGameState>(context, listen:false).setNames(text);
                  },
                ),

                const Spacer(flex: 3),

                const Text(
                    "LAN Quizduell",
                    style: TextStyle(color: Colors.white24, fontSize: 12),
                  ),
              ],
            )
          )
        )
      ),
    );
  }


}
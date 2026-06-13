import 'package:flutter/material.dart';
import 'package:lan_quiz/enums/quiz_phase.dart';
import 'package:lan_quiz/enums/joker_type.dart';
import 'package:lan_quiz/gameState/host_game_state.dart';
import 'package:provider/provider.dart';

class QuizQuestionWidget extends StatefulWidget {
  final int currentRound;
  final int totalRounds;
  final int timeLimit;

  final String question;
  final List<String> answers;

  /// Called when an answer is given.
  ///
  /// index:
  /// 0-3 = answer index
  /// 4 = timeout
  ///
  /// timeTaken:
  /// seconds it took to answer
  final void Function(String answer, int timeTaken) giveAnswer;

  const QuizQuestionWidget({
    super.key,
    required this.currentRound,
    required this.totalRounds,
    required this.question,
    required this.answers,
    required this.giveAnswer,
    required this.timeLimit
  });

  @override
  State<QuizQuestionWidget> createState() => _QuizQuestionWidgetState();
}

class _QuizQuestionWidgetState extends State<QuizQuestionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerController;

  bool _answered = false;
  String? _answer;

  late DateTime _startTime;

  @override
  void initState() {
    super.initState();

    _startTime = DateTime.now();

    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.timeLimit),
    );

    _timerController.forward();

    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_answered) {
        _answered = true;

        final timeTaken =
            DateTime.now().difference(_startTime).inMilliseconds;

        widget.giveAnswer("", timeTaken);

        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(QuizQuestionWidget oldWidget){
    super.didUpdateWidget(oldWidget);
    if(oldWidget.currentRound != widget.currentRound){
      setState(() {
        _answered = false;
        _answer = null;
        _startTime = DateTime.now();
      });

      _timerController.reset();
      _timerController.forward();
    }
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  void _handleAnswer(String answer) {
    if (_answered) return;

    _answered = true;
    _answer = answer;

    _timerController.stop();

    final timeTaken =
        DateTime.now().difference(_startTime).inMilliseconds;

    widget.giveAnswer(answer, timeTaken);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<HostGameState>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF4AA3D9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // TOP INFO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Round ${widget.currentRound} / ${widget.totalRounds}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(
                    Icons.timer,
                    color: Colors.white,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // QUESTION CARD
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 10,
                            color: Colors.black26,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.question,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ANSWERS
                    Expanded(
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.answers.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.8,
                        ),
                        itemBuilder: (context, index) {
                          final isSelected = _answer == widget.answers[index];
                          final isCorrect = index == gameState.correctAnswerIndex;
                          final isShowingResult = gameState.quizPhase == QuizPhase.showingResults;

                          // when the 50:50 Joker is used this makes the 2 randomly selected wrong answers disappear
                          if(widget.answers[index] == ""){
                            return const SizedBox.shrink();
                          }

                          Color bgColor = const Color(0xFF2F2F2F);
                          if(isShowingResult){
                            if(isCorrect){
                              bgColor = Colors.green;
                            }
                            else if(isSelected){
                              bgColor = Colors.red;
                            }
                            else{
                              bgColor = Colors.grey.shade800;
                            }
                          }
                          else if(isSelected){
                            bgColor = Colors.orange;
                          }

                          List<String> playersWhoChoseThis = [];
                          if(isShowingResult){
                            gameState.playerAnswersThisRound.forEach((name,answerText){
                              if(answerText == widget.answers[index]){
                                playersWhoChoseThis.add(name);
                              }
                            });
                          }

                          return ElevatedButton(
                            onPressed: _answered
                                ? null
                                : () => _handleAnswer(widget.answers[index]),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: bgColor,
                              disabledBackgroundColor: bgColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 8,
                              padding: const EdgeInsets.all(16),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Text(
                                    widget.answers[index],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                if(isShowingResult && playersWhoChoseThis.isNotEmpty)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: playersWhoChoseThis.map((name) {
                                        String initial = name.isNotEmpty ? name[0].toUpperCase() : "?";
                                        bool isMe = name == gameState.myName;

                                        return Container(
                                          margin: const EdgeInsets.only(left: 4),
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: isMe ? Colors.blue : Colors.purpleAccent,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 1.5),
                                          ),
                                          child: Center(
                                            child: Text(
                                              isMe ? "Du" : initial,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // here add Buttons for Jokers
              Row(
                children: [
                  ElevatedButton(
                    onPressed: (gameState.myUsedJokers.contains(JokerType.FIFTY_FIFTY) || gameState.isWaitingForJoker)
                    ? null
                    : () {
                      gameState.useJoker(JokerType.FIFTY_FIFTY);
                    },

                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text("50:50"),
                  ),
                  // here

                ],
              ),

              const SizedBox(height: 4),

              // TIMER BAR
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 24,
                  child: AnimatedBuilder(
                    animation: _timerController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: 1 - _timerController.value,
                        minHeight: 24,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
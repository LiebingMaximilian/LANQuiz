import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:lan_quiz/enums/quiz_phase.dart';
import 'package:lan_quiz/enums/joker_type.dart';
import 'package:lan_quiz/gameState/host_game_state.dart';
import 'package:lan_quiz/sound_manager.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:lan_quiz/stats_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class QuizQuestionWidget extends StatefulWidget {
  final int currentRound;
  final int totalRounds;
  final int timeLimit;
  final String currentCategory;

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
    required this.timeLimit,
    required this.currentCategory
  });

  @override
  State<QuizQuestionWidget> createState() => _QuizQuestionWidgetState();
}

class _QuizQuestionWidgetState extends State<QuizQuestionWidget>
    with TickerProviderStateMixin {
  late AnimationController _timerController;

  bool _answered = false;
  String? _answer;

  late DateTime _startTime;

  late AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    QuizStatsController().init();
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
    _lottieController = AnimationController(vsync: this);
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
    _lottieController.dispose();
    super.dispose();
  }

  void _handleAnswer(String answer) {
    if (_answered) return;

    _answered = true;
    _answer = answer;

    _timerController.stop();

    final timeTaken =
        DateTime.now().difference(_startTime).inMilliseconds;
    statsController.trackAnswertime(timeTaken);
    widget.giveAnswer(answer, timeTaken);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<HostGameState>(context);

    if(gameState.isPaused && _timerController.isAnimating){
      _timerController.stop();
    } else if(!gameState.isPaused && !_timerController.isAnimating && !_answered){
      _timerController.forward();
    }

    if (gameState.unlockAnswer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _answered = false;
            _answer = null;
            gameState.unlockAnswer = false;
          });
        }
      });
    }

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
                      Stack(
                        clipBehavior: Clip.none,
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
                          Positioned(
                            //category addon on top of the question widget
                            top: 0,
                            left: 0,
                            right: 0,
                            child: FractionalTranslation(
                              translation: const Offset(0.0, -0.5),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2F2F2F),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    widget.currentCategory,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ANSWERS
                      Expanded(
                        child: Stack(
                          children: [
                            GridView.builder(
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
                                if (widget.answers[index] == "") {
                                  return const SizedBox.shrink();
                                }

                                Color bgColor = const Color(0xFF2F2F2F);
                                if (isShowingResult) {
                                  if (isCorrect) {
                                    bgColor = Colors.green;
                                    if (isSelected) SoundManager.answerCorrect();
                                    if (isSelected) {statsController.trackRoundRes(true); } else {statsController.trackRoundRes(false);}
                                  } else if (isSelected) {
                                    bgColor = Colors.red;
                                  } else {
                                    bgColor = Colors.grey.shade800;
                                  }
                                } else if (isSelected) {
                                  bgColor = Colors.orange;
                                }

                                List<String> playersWhoChoseThis = [];
                                if (isShowingResult) {
                                  gameState.playerAnswersThisRound
                                      .forEach((name, answerText) {
                                    if (answerText == widget.answers[index]) {
                                      playersWhoChoseThis.add(name);
                                    }
                                  });
                                }

                                return ElevatedButton(
                                  onPressed: _answered
                                      ? null
                                      : () async {
                                    await SoundManager.answerSelected();
                                    _handleAnswer(widget.answers[index]);
                                  },
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
                                        child: AutoSizeText(
                                          widget.answers[index],
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (isShowingResult &&
                                          playersWhoChoseThis.isNotEmpty)
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: playersWhoChoseThis.map((name) {
                                              String initial = name.isNotEmpty
                                                  ? name[0].toUpperCase()
                                                  : "?";
                                              bool isMe = name == gameState.myName;

                                              return Container(
                                                margin: const EdgeInsets.only(left: 4),
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: isMe
                                                      ? Colors.blue
                                                      : Colors.purpleAccent,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: Colors.white,
                                                      width: 1.5),
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
                            if (gameState.isInkBlotted)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Lottie.asset(
                                    'assets/InkSplatterAnimation.json',
                                    controller: _lottieController,
                                    repeat: false,
                                    fit: BoxFit.cover,
                                    animate: true,
                                    onLoaded: (composition) {
                                      _lottieController.duration = composition.duration;

                                      _lottieController.forward(from: 0).then((_) {
                                        Future.delayed(const Duration(seconds: 1), () {
                                          if (mounted && gameState.isInkBlotted) {
                                            _lottieController.reverse().then((_) {
                                              if (mounted) {
                                                gameState.isInkBlotted = false;
                                                setState(() {});
                                              }
                                            });
                                          }
                                        });
                                      });
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Joker Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: (_answered || gameState.myUsedJokers.contains(JokerType.FIFTY_FIFTY) ||
                        gameState.isWaitingForJoker)
                        ? null
                        : () {
                      gameState.useJoker(JokerType.FIFTY_FIFTY);
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text("50:50"),
                  ),
                  ElevatedButton(
                    onPressed: (_answered || gameState.myUsedJokers.contains(JokerType.DOUBLE_DOWN) ||
                        gameState.isWaitingForJoker)
                        ? null
                        : () {
                      gameState.useJoker(JokerType.DOUBLE_DOWN);
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                          const FaIcon(FontAwesomeIcons.diceD20, color: Colors.purple,),

                           Positioned(
                             top: -5,
                             right: -10,
                             child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                               child: const Text(
                                 "x2",
                                 style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),

                               ),
                             ),
                           ),
                        Positioned(
                          bottom: -5,
                          left: -10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: const Text(
                              "-1",
                              style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),

                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /*
                  ElevatedButton(
                    onPressed: (_answered || gameState.myUsedJokers.contains(JokerType.SECOND_CHANCE) ||
                        gameState.isWaitingForJoker)
                        ? null
                        : () {
                      gameState.useJoker(JokerType.SECOND_CHANCE);
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Icon(Icons.replay),
                   ),
                   */
                  ElevatedButton(
                    onPressed: (_answered || gameState.myUsedJokers.contains(JokerType.COPY_CAT) ||
                        gameState.isWaitingForJoker)
                        ? null
                        : () {
                      _showCopyCatDialog(context, gameState);
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.cat, color: Colors.purple),

                        Transform.flip(
                          flipX: true,
                          child: FaIcon(
                            FontAwesomeIcons.cat,
                            color: Colors.grey.withAlpha(110),
                          ),
                        )
                      ],
                    )
                  ),

                  ElevatedButton(
                    onPressed: (_answered || gameState.myUsedJokers.contains(JokerType.INK_SPLASH) ||
                        gameState.isWaitingForJoker)
                        ? null
                        : () {
                      _showPaintSplashDialog(context, gameState);
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Icon(Icons.water_drop),
                  ),
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

  void _showPaintSplashDialog(BuildContext context, dynamic gameState) {
    showDialog(
      context: context,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: gameState,
          builder: (context, child) {

            if (gameState.quizPhase != QuizPhase.answering) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (ctx.mounted) Navigator.canPop(ctx) ? Navigator.pop(ctx) : null;
              });
            }

            return AlertDialog(
              title: const Text("Who do you want to attack?"),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: gameState.playerManager.players.length,
                  itemBuilder: (context, index) {
                    final player = gameState.playerManager.players[index];
                    if (player.id == gameState.myId) return const SizedBox.shrink();

                    return ListTile(
                      leading: const Icon(Icons.person),
                      key: ValueKey(player.id),
                      title: Text(player.name),
                      onTap: () {
                        gameState.useJoker(JokerType.INK_SPLASH, targetId: player.id);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCopyCatDialog(BuildContext context, dynamic gameState) {
    showDialog(
      context: context,
      builder: (context) {
        // ListenableBuilder only rebuilds the dialog when gameState.notifyListeners() is used
        return ListenableBuilder(
          listenable: gameState,
          builder: (context, child) {

            if(gameState.quizPhase != QuizPhase.answering){
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if(context.mounted) Navigator.canPop(context) ? Navigator.pop(context) : null;
              });
            }

            final otherPlayers = gameState.playerManager.players
                .where((p) => p.id != gameState.myId)
                .toList();

            return AlertDialog(
              title: const Text("Who do you want to copy?"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: otherPlayers.map<Widget>((player){
                  // has player answered?
                  bool hasAnswered = gameState.playersWhoAnswered.contains(player.id);

                  return ListTile(
                    key: ValueKey(player.id),
                    leading: FaIcon(
                      FontAwesomeIcons.cat,
                      color: hasAnswered ? Colors.purple : Colors.grey.shade400,
                    ),
                    title: Text(
                      player.name,
                      style: TextStyle(
                        color: hasAnswered ? Colors.black : Colors.grey,
                        fontWeight: hasAnswered ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: hasAnswered
                        ? const Text("has answered", style: TextStyle(color: Colors.green, fontSize: 12))
                        : const Text("is still thinking...", style: TextStyle(fontSize: 12)),

                    onTap: !hasAnswered
                      ? null
                      :  () {
                      gameState.useJoker(JokerType.COPY_CAT, targetId: player.id);
                      Navigator.of(context).pop();
                    },

                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';

class QuizQuestionWidget extends StatefulWidget {
  final int currentRound;
  final int totalRounds;

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
  final void Function(int index, double timeTaken) giveAnswer;//TODO what do we do with the answer

  const QuizQuestionWidget({
    super.key,
    required this.currentRound,
    required this.totalRounds,
    required this.question,
    required this.answers,
    required this.giveAnswer,
  });

  @override
  State<QuizQuestionWidget> createState() => _QuizQuestionWidgetState();
}

class _QuizQuestionWidgetState extends State<QuizQuestionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerController;

  bool _answered = false;
  int? _selectedIndex;

  late DateTime _startTime;

  @override
  void initState() {
    super.initState();

    _startTime = DateTime.now();

    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _timerController.forward();

    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_answered) {
        _answered = true;

        final timeTaken =
            DateTime.now().difference(_startTime).inMilliseconds / 1000;

        widget.giveAnswer(5, timeTaken);

        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  void _handleAnswer(int index) {
    if (_answered) return;

    _answered = true;
    _selectedIndex = index;

    _timerController.stop();

    final timeTaken =
        DateTime.now().difference(_startTime).inMilliseconds / 1000;

    widget.giveAnswer(index, timeTaken);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
                            fontSize: 30,
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
                          final isSelected = _selectedIndex == index;

                          return ElevatedButton(
                            onPressed: _answered
                                ? null
                                : () => _handleAnswer(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? Colors.orange
                                  : const Color(0xFF2F2F2F),
                              disabledBackgroundColor: isSelected
                                  ? Colors.orange
                                  : const Color(0xFF2F2F2F),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 8,
                              padding: const EdgeInsets.all(16),
                            ),
                            child: Text(
                              widget.answers[index],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

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
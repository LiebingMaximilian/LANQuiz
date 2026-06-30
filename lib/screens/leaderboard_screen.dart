import 'package:flutter/material.dart';
import 'package:lan_quiz/gameState/host_game_state.dart';
import 'package:provider/provider.dart';

class LeaderboardWidget extends StatefulWidget {
  /// List of players with their names and scores.
  final List<LeaderboardEntry> entries;
  final int timeLimit;
  final bool isHost;
  final bool isFinal;

  const LeaderboardWidget({
    super.key,
    required this.entries,
    required this.timeLimit,
    this.isHost = false,
    this.isFinal = false,
  });

  @override
  State<LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

class LeaderboardEntry {
  final String name;
  final int score;

  const LeaderboardEntry({required this.name, required this.score});
  Map<String, dynamic> toJson() => {'name': name, 'score': score};

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        name: json['name'] as String,
        score: json['score'] as int,
      );
}

class _LeaderboardWidgetState extends State<LeaderboardWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _barControllers;
  late List<Animation<double>> _barAnimations;
  late AnimationController _timerController;
  late List<LeaderboardEntry> _sorted;
  bool buttonActivated = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    buttonActivated = false;
  }

  @override
  void dispose() {
    for (final c in _barControllers) {
      c.dispose();
    }
    _timerController.dispose();
    super.dispose();
  }

  Color _barColor(int rank) {
    switch (rank) {
      case 0:
        return const Color(0xFFFFD700); // Gold
      case 1:
        return const Color(0xFFC0C0C0); // Silver
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return const Color(0xFF2F2F2F);
    }
  }

  List<LeaderboardEntry> _getSortedEntries(List<LeaderboardEntry> entries){
    return List.of(entries)..sort((a,b) => b.score.compareTo(a.score));
  }

  void _initAnimations(){
    // Sort descending by score
    if(widget.entries.isEmpty){
      _sorted = [];
    } else {
      _sorted = _getSortedEntries(widget.entries);
    }

    final int maxScore =
    _sorted.isNotEmpty ? _sorted.first.score : 1;
    _barControllers = List.generate(
      _sorted.length,
          (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      ),
    );

    _barAnimations = List.generate(_sorted.length, (i) {
      double targetHeight = 0.0;
      if( _sorted[i].score >= 0 && maxScore > 0) {
        targetHeight =
        maxScore > 0 ? _sorted[i].score / maxScore : 0.0;
      }
      return Tween<double>(begin: 0, end: targetHeight).animate(

        CurvedAnimation(
          parent: _barControllers[i],
          curve: Curves.easeOutCubic,
        ),
      );
    });

    // Stagger the bar animations
    for (int i = 0; i < _barControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 150 * i), () {
        if (mounted) _barControllers[i].forward();
      });
    }

    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.timeLimit),
    );

    _timerController.forward();

    _timerController.addStatusListener((status) {
    });
  }

  @override
  void didUpdateWidget(LeaderboardWidget oldWidget){
    super.didUpdateWidget(oldWidget);
    if(oldWidget.entries.length != widget.entries.length){
      for(final c in _barControllers) c.dispose();
      _initAnimations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<HostGameState>(context);

    if(gameState.isPaused && _timerController.isAnimating){
      _timerController.stop();
    } else if(!gameState.isPaused && !_timerController.isAnimating){
      _timerController.forward();
    }

    if (widget.isFinal) {
      return _buildFinalLeaderboard(context);
    }
    else {
      const double maxBarHeight = 220;

      return Scaffold(
        backgroundColor: const Color(0xFF4AA3D9),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title
                const Text(
                  "🏆 Leaderboard",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 32),

                // Bar chart
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_sorted.length, (i) {
                      final entry = _sorted[i];
                      return _BarColumn(
                        entry: entry,
                        rank: i,
                        animation: _barAnimations[i],
                        barColor: _barColor(i),
                        maxBarHeight: maxBarHeight,
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 32),

                // Continue button
                // Replace the SizedBox + ElevatedButton with:
                // no timer for the final leaderboard, host should use the end game or restart buttons instead
                if(!widget.isFinal)...[
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
              ],
            ),
          ),
        ),
      );
    }
  }

    Widget _buildFinalLeaderboard(BuildContext context){

      List<Widget> podiumWidgets = [];
      if(_sorted.isNotEmpty){

        if(_sorted.length > 1){
          podiumWidgets.add(_buildPodiumPillar(_sorted[1], 2, 130, _barColor(1)));
        }

        podiumWidgets.add(_buildPodiumPillar(_sorted[0], 1, 180, _barColor(0)));

        if(_sorted.length > 2){
          podiumWidgets.add(_buildPodiumPillar(_sorted[2], 3, 100, _barColor(2)));
        }
      }

      return Scaffold(
        backgroundColor: const Color(0xFF1E1E2C),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                const Text("🏆  Final Results  🏆",
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 30),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: podiumWidgets,
                  ),
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: _sorted.length >  3 ?
                      ListView.builder(
                    itemCount: _sorted.length > 3 ? _sorted.length - 3 : 0,
                    itemBuilder: (context, index){
                      final actualRank = index + 3;
                      final entry = _sorted[actualRank];
                      return Card(
                        color: const Color(0xFF2F2F3D),
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade800,
                            child: Text("${actualRank + 1}", style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(entry.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          trailing: Text("${entry.score} Points", style: const TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      );
                    },
                  )
                  : const Center(
                    child: Text(""),
                    ),
                ),
                if(widget.isHost)...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (){
                            if(!buttonActivated){
                              buttonActivated = true; //edge detection, only press button once
                              Provider.of<HostGameState>(context, listen: false).restartGame();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)
                            ),
                          ),
                          child: const Text('Restart Game'),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Provider.of<HostGameState>(context, listen: false).endGame();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('End Game'),
                          ),
                      ),
                    ],
                  )
                ],
              ],
            ),
          ),
        ),
      );
    }

    Widget _buildPodiumPillar(LeaderboardEntry entry, int rank, double height, Color color){
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text("${entry.score}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              width: 80,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top:  Radius.circular(12)),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))]
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("$rank", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black38)),
                ],
              ),
            ),
            Container(
              width: 80,
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF2F2F2F),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Text(
                entry.name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            )
          ],
        ),
      );
    }
  }



class _BarColumn extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final Animation<double> animation;
  final Color barColor;
  final double maxBarHeight;

  const _BarColumn({
    required this.entry,
    required this.rank,
    required this.animation,
    required this.barColor,
    required this.maxBarHeight,
  });

  

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final barHeight = animation.value * maxBarHeight;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Score label
            Text(
              "${entry.score}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 6),

            // Bar
            Container(
              width: 60,
              height: barHeight,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 8,
                    color: Colors.black26,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),

            // Name label
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF2F2F2F),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Text(
                entry.name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
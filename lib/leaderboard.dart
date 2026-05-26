import 'package:flutter/material.dart';

class LeaderboardWidget extends StatefulWidget {
  /// List of players with their names and scores.
  final List<LeaderboardEntry> entries;
  final int timeLimit;             // ADD THIS
  final VoidCallback onTimerEnd; 

  const LeaderboardWidget({
    super.key,
    required this.entries,
    required this.timeLimit,
    required this.onTimerEnd,
  });

  @override
  State<LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

class LeaderboardEntry {
  final String name;
  final int score;

  const LeaderboardEntry({required this.name, required this.score});
}

class _LeaderboardWidgetState extends State<LeaderboardWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _barControllers;
  late List<Animation<double>> _barAnimations;
  late AnimationController _timerController;
  late List<LeaderboardEntry> _sorted;

  @override
  void initState() {
    super.initState();

    // Sort descending by score
    _sorted = List.of(widget.entries)
      ..sort((a, b) => b.score.compareTo(a.score));

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
      final targetHeight =
          maxScore > 0 ? _sorted[i].score / maxScore : 0.0;
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
      if (status == AnimationStatus.completed) {
        widget.onTimerEnd();
      }
  });
  }

  @override
  void dispose() {
    for (final c in _barControllers) {
      c.dispose();
    }
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

  @override
  Widget build(BuildContext context) {
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
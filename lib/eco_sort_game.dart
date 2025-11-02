import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// ECO SORT!  — Drag items into the right bin (Recycle / Organic / Trash)
/// No extra packages. Self-contained.
/// Hook onRoundFinished to award points in your app if you want.
class EcoSortGamePage extends StatefulWidget {
  final void Function(double coinsEarned)? onRoundFinished;
  const EcoSortGamePage({super.key, this.onRoundFinished});

  @override
  State<EcoSortGamePage> createState() => _EcoSortGamePageState();
}

enum _EcoType { recycle, organic, trash }

class _EcoItem {
  final _EcoType type;
  final String label;
  final String emoji;
  const _EcoItem(this.type, this.label, this.emoji);
}

class _EcoSortGamePageState extends State<EcoSortGamePage> {
  static const int _roundSeconds = 60;

  final _rnd = Random();

  final List<_EcoItem> _pool = const [
    _EcoItem(_EcoType.recycle, 'Newspaper', '📰'),
    _EcoItem(_EcoType.recycle, 'Plastic Bottle', '🧴'),
    _EcoItem(_EcoType.recycle, 'Soda Can', '🥫'),
    _EcoItem(_EcoType.organic, 'Apple Core', '🍎'),
    _EcoItem(_EcoType.organic, 'Banana Peel', '🍌'),
    _EcoItem(_EcoType.organic, 'Carrot', '🥕'),
    _EcoItem(_EcoType.trash, 'Chip Packet', '🍟'),
    _EcoItem(_EcoType.trash, 'Broken Toy', '🧸'),
    _EcoItem(_EcoType.trash, 'Dust', '🧹'),
  ];

  late _EcoItem _current;
  Timer? _ticker;
  bool _running = false;
  int _timeLeft = _roundSeconds;
  int _score = 0;
  int _streak = 0;

  bool _showCorrect = false;
  bool _showWrong = false;

  // Colors align with your app palette
  Color get deepGreen => const Color(0xFF27463A);
  Color get ivory => const Color(0xFFEDE7E3);
  Color get recycleGreen => const Color(0xFF0EA5A5);
  Color get organicGreen => const Color(0xFF22C55E);
  Color get trashRed => const Color(0xFFE11D48);

  @override
  void initState() {
    super.initState();
    _current = _randomItem();
    _startRound();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  _EcoItem _randomItem() => _pool[_rnd.nextInt(_pool.length)];

  void _startRound() {
    setState(() {
      _running = true;
      _timeLeft = _roundSeconds;
      _score = 0;
      _streak = 0;
      _current = _randomItem();
      _showCorrect = false;
      _showWrong = false;
    });

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_running) return;
      if (_timeLeft <= 1) {
        t.cancel();
        _endRound();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _endRound() {
    setState(() => _running = false);

    double coinsEarned = _score / 5000;
    coinsEarned = double.parse(coinsEarned.toStringAsFixed(2));

    // Send coins (as int) to parent
    widget.onRoundFinished?.call(coinsEarned);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Time’s up!'),
        content: Text('Nice work!\n\nYour Score: $_score\nCoins Earned: $coinsEarned 🪙'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startRound();
            },
            child: const Text('Play Again'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleDrop(_EcoType target) {
    final correct = (target == _current.type);
    if (correct) {
      _streak++;
      int gained = 5 + min(_streak, 5); // +5 base, up to +10 max for long streaks
      setState(() {
        _score += gained;
        _flashCorrect();
        _current = _randomItem();
      });
    } else {
      setState(() {
        _streak = 0;
        _score = (_score - 5).clamp(0, 1 << 30);
        _flashWrong();
        _current = _randomItem();
      });
    }
  }

  void _flashCorrect() {
    _showCorrect = true;
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _showCorrect = false);
    });
  }

  void _flashWrong() {
    _showWrong = true;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _showWrong = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepGreen,
      appBar: AppBar(
        backgroundColor: deepGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Eco Sort!', style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _running ? _endRound : _startRound,
              child: Text(
                _running ? 'Finish' : 'Start',
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // HUD
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Row(
                children: [
                  _hudPill('Time', '$_timeLeft s', Icons.timer, Colors.amber),
                  const SizedBox(width: 8),
                  _hudPill('Score', '$_score', Icons.stars, Colors.lightBlueAccent),
                  const SizedBox(width: 8),
                  _hudPill('Streak', 'x$_streak', Icons.local_fire_department,
                      Colors.lightGreenAccent),
                ],
              ),
            ),

            // Draggable item
            Expanded(
              child: Center(
                child: Draggable<_EcoType>(
                  data: _current.type,
                  feedback: _itemChip(_current, scale: 1.2, elevated: true),
                  childWhenDragging:
                  _itemChip(_current, faded: true, elevated: false),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 140),
                    scale: _showCorrect
                        ? 1.12
                        : _showWrong
                        ? 0.9
                        : 1.0,
                    child: _itemChip(_current, elevated: true),
                  ),
                ),
              ),
            ),

            // Bins row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _bin(
                      'Recycle',
                      Icons.recycling,
                      recycleGreen,
                          () => _handleDrop(_EcoType.recycle),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _bin(
                      'Organic',
                      Icons.eco,
                      organicGreen,
                          () => _handleDrop(_EcoType.organic),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _bin(
                      'Trash',
                      Icons.delete_outline,
                      trashRed,
                          () => _handleDrop(_EcoType.trash),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- UI helpers ----------

  Widget _hudPill(String label, String value, IconData icon, Color chipColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // slightly smaller
        decoration: BoxDecoration(
          color: ivory.withOpacity(0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 6),

            // label - allow it to shrink and ellipsize on overflow
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),

            const SizedBox(width: 6),

            // value "chip" - keep a minimum width and ellipsize if needed
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 36, maxWidth: 84),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: chipColor.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemChip(_EcoItem item,
      {bool faded = false, bool elevated = false, double scale = 1.0}) {
    return Transform.scale(
      scale: scale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(faded ? 0.6 : 1),
          borderRadius: BorderRadius.circular(18),
          boxShadow: elevated
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Text(item.label,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _bin(String label, IconData icon, Color color, VoidCallback onAccept) {
    return DragTarget<_EcoType>(
      onWillAccept: (_) => true,
      onAccept: (_) => onAccept(),
      builder: (context, candidates, rejects) {
        final hovering = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: hovering ? color.withOpacity(0.28) : Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: hovering ? Colors.white : Colors.white24, width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

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

class _EcoSortGamePageState extends State<EcoSortGamePage>
    with TickerProviderStateMixin {
  static const int _roundSeconds = 60;

  final _rnd = Random();

  // 🧩 Expanded item pool
  final List<_EcoItem> _pool = const [
    _EcoItem(_EcoType.recycle, 'Newspaper', '📰'),
    _EcoItem(_EcoType.recycle, 'Plastic Bottle', '🧴'),
    _EcoItem(_EcoType.recycle, 'Soda Can', '🥫'),
    _EcoItem(_EcoType.recycle, 'Glass Bottle', '🍾'),
    _EcoItem(_EcoType.recycle, 'Paper Bag', '🛍️'),
    _EcoItem(_EcoType.organic, 'Apple Core', '🍎'),
    _EcoItem(_EcoType.organic, 'Banana Peel', '🍌'),
    _EcoItem(_EcoType.organic, 'Carrot', '🥕'),
    _EcoItem(_EcoType.organic, 'Leaves', '🍃'),
    _EcoItem(_EcoType.trash, 'Chip Packet', '🍟'),
    _EcoItem(_EcoType.trash, 'Broken Toy', '🧸'),
    _EcoItem(_EcoType.trash, 'Dust', '🧹'),
    _EcoItem(_EcoType.trash, 'Battery', '🔋'),
    _EcoItem(_EcoType.trash, 'Old Phone', '📱'),
  ];

  late _EcoItem _current;
  Timer? _ticker;
  bool _running = false;
  int _timeLeft = _roundSeconds;
  int _score = 0;
  int _streak = 0;
  bool _showCorrect = false;
  bool _showWrong = false;

  // 🌈 Theme
  final Color background = const Color(0xFF0F0F0F);
  final Color cardColor = const Color(0xFF1C1C1C);
  final Color accent = Colors.greenAccent;

  // 🪙 Floating coin animation
  late AnimationController _coinController;
  late Animation<double> _coinAnimation;
  bool _showCoin = false;

  @override
  void initState() {
    super.initState();
    _current = _randomItem();
    _startRound();

    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _coinAnimation =
        CurvedAnimation(parent: _coinController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _coinController.dispose();
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
    double coinsEarned = double.parse((_score / 5000).toStringAsFixed(2));
    widget.onRoundFinished?.call(coinsEarned);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text('⏰ Time’s up!', style: TextStyle(color: Colors.white)),
        content: Text(
          'Nice work!\n\nYour Score: $_score\nCoins Earned: $coinsEarned 🪙',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startRound();
            },
            child: Text('Play Again', style: TextStyle(color: accent)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _handleDrop(_EcoType target) {
    final correct = (target == _current.type);
    if (correct) {
      _streak++;
      int gained = 5 + min(_streak, 5);
      setState(() {
        _score += gained;
        _flashCorrect();
        _current = _randomItem();
      });
      _triggerCoinAnimation();
    } else {
      setState(() {
        _streak = 0;
        _score = (_score - 5).clamp(0, 999999);
        _flashWrong();
        _current = _randomItem();
      });
    }
  }

  void _triggerCoinAnimation() {
    setState(() => _showCoin = true);
    _coinController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showCoin = false);
    });
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
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          '♻️ Eco Sort!',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _running ? _endRound : _startRound,
              child: Text(
                _running ? 'Finish' : 'Start',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // HUD
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _hudPill('⏱ Time', '$_timeLeft s', Colors.amber),
                      const SizedBox(width: 8),
                      _hudPill('⭐ Score', '$_score', Colors.lightBlueAccent),
                      const SizedBox(width: 8),
                      _hudPill('🔥 Streak', 'x$_streak', accent),
                    ],
                  ),
                ),

                // Item
                Expanded(
                  child: Center(
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: _showCorrect
                          ? 1.2
                          : _showWrong
                          ? 0.8
                          : 1.0,
                      child: Draggable<_EcoType>(
                        data: _current.type,
                        feedback: _itemCard(_current, elevated: true),
                        childWhenDragging: _itemCard(_current, faded: true),
                        child: _itemCard(_current, elevated: true),
                      ),
                    ),
                  ),
                ),

                // Bins
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                  child: Row(
                    children: [
                      Expanded(child: _bin('Recycle', Icons.recycling, Colors.tealAccent, _EcoType.recycle)),
                      const SizedBox(width: 12),
                      Expanded(child: _bin('Organic', Icons.eco, Colors.greenAccent, _EcoType.organic)),
                      const SizedBox(width: 12),
                      Expanded(child: _bin('Trash', Icons.delete_outline, Colors.redAccent, _EcoType.trash)),
                    ],
                  ),
                ),
              ],
            ),

            // 🪙 Floating Coin Animation
            if (_showCoin)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _coinAnimation,
                  builder: (context, child) {
                    final dy = (1 - _coinAnimation.value) * 120;
                    final opacity = 1 - _coinAnimation.value;
                    return Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: Offset(0, -dy),
                        child: Center(
                          child: Text(
                            '+🪙',
                            style: TextStyle(
                              fontSize: 42,
                              color: accent,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                    color: accent.withOpacity(0.8),
                                    blurRadius: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // UI helpers
  Widget _hudPill(String label, String value, Color glow) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: glow.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: glow.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: glow, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _itemCard(_EcoItem item, {bool faded = false, bool elevated = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(faded ? 0.6 : 1),
        borderRadius: BorderRadius.circular(18),
        boxShadow: elevated
            ? [
          BoxShadow(
            color: accent.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 1,
          )
        ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Text(item.label,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _bin(String label, IconData icon, Color color, _EcoType type) {
    return DragTarget<_EcoType>(
      onWillAccept: (_) => true,
      onAccept: (_) => _handleDrop(type),
      builder: (context, candidates, rejects) {
        final hovering = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: hovering ? color : Colors.white12,
                width: hovering ? 2.5 : 1.2),
            boxShadow: hovering
                ? [
              BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, spreadRadius: 2),
            ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        );
      },
    );
  }
}
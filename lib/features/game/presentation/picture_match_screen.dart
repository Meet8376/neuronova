import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/db/database_helper.dart';
import '../../../services/adaptive_difficulty_service.dart';

class NERCardItem {
  final String id;
  final String title;
  final IconData icon;
  final Color color;

  const NERCardItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
  });
}

class PictureMatchScreen extends StatefulWidget {
  final int initialTier;
  const PictureMatchScreen({super.key, this.initialTier = 1});

  @override
  State<PictureMatchScreen> createState() => _PictureMatchScreenState();
}

class _PictureMatchScreenState extends State<PictureMatchScreen> {
  late int _tier;
  late List<_CardTileData> _cards;
  int _firstFlippedIndex = -1;
  int _secondFlippedIndex = -1;
  bool _isProcessing = false;

  int _moves = 0;
  int _matchesFound = 0;
  int _totalPairs = 2;

  int _elapsedSeconds = 0;
  Timer? _timer;

  // Culturally familiar North Eastern Region items
  final List<NERCardItem> _nerCatalog = const [
    NERCardItem(id: 'rhino', title: 'Kaziranga Rhino', icon: Icons.pets_rounded, color: Color(0xFF795548)),
    NERCardItem(id: 'tea', title: 'Assam Tea Leaf', icon: Icons.eco_rounded, color: Color(0xFF4CAF50)),
    NERCardItem(id: 'dhol', title: 'Bihu Dhol', icon: Icons.queue_music_rounded, color: Color(0xFFFF9800)),
    NERCardItem(id: 'hornbill', title: 'Hornbill', icon: Icons.flutter_dash_rounded, color: Color(0xFFE91E63)),
    NERCardItem(id: 'mask', title: 'Majuli Mask', icon: Icons.theater_comedy_rounded, color: Color(0xFF9C27B0)),
    NERCardItem(id: 'lake', title: 'Loktak Lake', icon: Icons.water_rounded, color: Color(0xFF0288D1)),
  ];

  @override
  void initState() {
    super.initState();
    _tier = widget.initialTier;
    _setupGame();
  }

  void _setupGame() {
    _moves = 0;
    _matchesFound = 0;
    _firstFlippedIndex = -1;
    _secondFlippedIndex = -1;
    _isProcessing = false;

    if (_tier == 1) {
      _totalPairs = 2; // 4 cards total
    } else if (_tier == 2) {
      _totalPairs = 3; // 6 cards total
    } else {
      _totalPairs = 6; // 12 cards total
    }

    final selectedItems = _nerCatalog.take(_totalPairs).toList();
    final List<_CardTileData> tileList = [];

    for (int i = 0; i < selectedItems.length; i++) {
      tileList.add(_CardTileData(item: selectedItems[i], pairId: i));
      tileList.add(_CardTileData(item: selectedItems[i], pairId: i));
    }

    tileList.shuffle();
    _cards = tileList;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onCardTap(int index) {
    if (_isProcessing || _cards[index].isFaceUp || _cards[index].isMatched) return;

    setState(() {
      _cards[index].isFaceUp = true;
    });

    if (_firstFlippedIndex == -1) {
      _firstFlippedIndex = index;
    } else {
      _secondFlippedIndex = index;
      _moves++;
      _isProcessing = true;

      if (_cards[_firstFlippedIndex].pairId == _cards[_secondFlippedIndex].pairId) {
        // Match!
        setState(() {
          _cards[_firstFlippedIndex].isMatched = true;
          _cards[_secondFlippedIndex].isMatched = true;
          _firstFlippedIndex = -1;
          _secondFlippedIndex = -1;
          _matchesFound++;
          _isProcessing = false;
        });

        if (_matchesFound == _totalPairs) {
          _onGameComplete();
        }
      } else {
        // No match - turn back face down after delay
        Timer(const Duration(milliseconds: 900), () {
          if (mounted) {
            setState(() {
              _cards[_firstFlippedIndex].isFaceUp = false;
              _cards[_secondFlippedIndex].isFaceUp = false;
              _firstFlippedIndex = -1;
              _secondFlippedIndex = -1;
              _isProcessing = false;
            });
          }
        });
      }
    }
  }

  Future<void> _onGameComplete() async {
    _timer?.cancel();

    // Calculate score percentage (moves vs optimal)
    final minMoves = _totalPairs;
    double scoreFactor = (minMoves / _moves).clamp(0.4, 1.0);
    int finalScore = (scoreFactor * 100).round();

    // Save session to SQLite
    final db = await DatabaseHelper.instance.database;
    await db.insert('game_sessions', {
      'id': const Uuid().v4(),
      'game_type': 'picture_match',
      'played_at': DateTime.now().millisecondsSinceEpoch,
      'category': 'NER Culture',
      'language': 'en',
      'length': 'short',
      'difficulty_tier': _tier,
      'content_id': 'ner_cards_$_totalPairs',
      'text_title': 'Picture Match (NER)',
      'source_text': '$_totalPairs pairs matched in $_moves moves',
      'spoken_text': '',
      'score_percent': finalScore,
      'word_match_count': _matchesFound,
      'total_words': _totalPairs,
      'recording_path': null,
    });

    // Evaluate adaptive difficulty
    final metrics = await AdaptiveDifficultyService.instance.evaluatePatientCognitiveState();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.stars_rounded, color: Colors.amber, size: 36),
            SizedBox(width: 12),
            Text('Wonderful Job!', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You matched all $_totalPairs pairs in $_moves moves and $_elapsedSeconds seconds!',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cognitive Score: $finalScore%\nNext Difficulty: Tier ${metrics.currentTier}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Back to Games', style: TextStyle(color: Colors.white, fontFamily: 'Nunito')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = _totalPairs <= 2 ? 2 : 3;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Picture Match (NER)', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Stats header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statChip(Icons.touch_app_rounded, 'Moves: $_moves', Colors.blue),
                  _statChip(Icons.timer_rounded, 'Time: ${_elapsedSeconds}s', Colors.orange),
                  _statChip(Icons.check_circle_rounded, 'Pairs: $_matchesFound/$_totalPairs', Colors.green),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    final showFace = card.isFaceUp || card.isMatched;

                    return GestureDetector(
                      onTap: () => _onCardTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: showFace ? Colors.white : AppColors.primary,
                          borderRadius: BorderRadius.circular(18),
                          border: showFace
                              ? Border.all(color: card.item.color, width: 3)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: showFace
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(card.item.icon, size: 40, color: card.item.color),
                                    const SizedBox(height: 6),
                                    Text(
                                      card.item.title,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: card.item.color,
                                      ),
                                    ),
                                  ],
                                )
                              : const Icon(Icons.help_outline_rounded, size: 44, color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTileData {
  final NERCardItem item;
  final int pairId;
  bool isFaceUp = false;
  bool isMatched = false;

  _CardTileData({
    required this.item,
    required this.pairId,
  });
}

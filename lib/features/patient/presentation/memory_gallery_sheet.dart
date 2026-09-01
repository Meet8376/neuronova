import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/tts_service.dart';

class MemoryItem {
  final String title;
  final String description;
  final String imagePath;
  final String date;

  MemoryItem({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.date,
  });
}

class MemoryGallerySheet extends StatefulWidget {
  const MemoryGallerySheet({super.key});

  @override
  State<MemoryGallerySheet> createState() => _MemoryGallerySheetState();
}

class _MemoryGallerySheetState extends State<MemoryGallerySheet> {
  final _tts = TtsService.instance;

  final List<MemoryItem> _memories = [
    MemoryItem(
      title: 'Family Garden Reunion',
      description: 'You and your loving family sitting together in the sunny garden at Barabanki.',
      imagePath: 'assets/images/memory_family.png',
      date: 'Family Moment',
    ),
    MemoryItem(
      title: 'Teatime with Meena',
      description: 'A cozy morning cup of hot tea and fresh cookies by the window.',
      imagePath: 'assets/images/memory_tea.png',
      date: 'Comfort Moment',
    ),
    MemoryItem(
      title: 'Bruno the Dog',
      description: 'Your gentle Golden Retriever resting lovingly on your lap at home.',
      imagePath: 'assets/images/memory_pet.png',
      date: 'Pet Memory',
    ),
  ];

  void _speakMemory(MemoryItem memory) {
    _tts.speak('${memory.title}. ${memory.description}');
  }

  void _addNewMemoryDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.cardBgWarm,
        title: const Row(
          children: [
            Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 28),
            SizedBox(width: 10),
            Text('Add Memory Photo', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.photo_library_rounded, size: 44, color: AppColors.primaryLight),
                  SizedBox(height: 6),
                  Text('Tap to choose photo from gallery', style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Memory Title (e.g. Birthday Party)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Who is in this picture?',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 44)),
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                setState(() {
                  _memories.insert(
                    0,
                    MemoryItem(
                      title: titleCtrl.text,
                      description: descCtrl.text.isEmpty ? 'A special memory moment.' : descCtrl.text,
                      imagePath: 'assets/images/memory_family.png', // Demo default
                      date: 'Just Added',
                    ),
                  );
                });
              }
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.check_rounded, size: 20),
            label: const Text('Save Photo'),
          ),
        ],
      ),
    );
  }

  void _openDetailModal(MemoryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.asset(
                item.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.photo, size: 60, color: AppColors.primary),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _speakMemory(item),
                    icon: const Icon(Icons.volume_up_rounded, size: 22),
                    label: const Text('Read Aloud'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBgWarm,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Memory Album 🌸',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _addNewMemoryDialog,
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Comforting pictures of your home, family, and happy moments',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Horizontal Photo Cards
          SizedBox(
            height: 230,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _memories.length,
              itemBuilder: (ctx, i) {
                final item = _memories[i];
                return GestureDetector(
                  onTap: () => _openDetailModal(item),
                  child: Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppShadows.card,
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: Image.asset(
                            item.imagePath,
                            height: 130,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 130,
                              color: AppColors.primary.withOpacity(0.1),
                              child: const Icon(Icons.photo, color: AppColors.primary, size: 40),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addNewMemoryDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardBgWarm,
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 2),
            ),
            icon: const Icon(Icons.add_a_photo_rounded, size: 22),
            label: const Text('Add a Comfort Photo', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

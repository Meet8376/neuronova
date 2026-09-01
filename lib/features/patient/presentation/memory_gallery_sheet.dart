import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_image_view.dart';
import '../../../data/repositories/memory_repository.dart';
import '../../../services/tts_service.dart';

class MemoryGallerySheet extends StatefulWidget {
  const MemoryGallerySheet({super.key});

  @override
  State<MemoryGallerySheet> createState() => _MemoryGallerySheetState();
}

class _MemoryGallerySheetState extends State<MemoryGallerySheet> {
  final _tts = TtsService.instance;
  final _memoryRepo = MemoryRepository();
  final _picker = ImagePicker();

  List<MemoryItem> _memories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    final list = await _memoryRepo.getMemories();
    if (!mounted) return;
    setState(() {
      _memories = list;
      _loading = false;
    });
  }

  void _speakMemory(MemoryItem memory) {
    _tts.speak('${memory.title}. ${memory.description}');
  }

  Future<void> _addNewMemoryDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedImagePath;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickPhoto(ImageSource source) async {
            try {
              final picked = await _picker.pickImage(
                source: source,
                maxWidth: 1600,
                maxHeight: 1600,
                imageQuality: 88,
              );
              if (picked != null) {
                setDialogState(() {
                  selectedImagePath = picked.path;
                });
              }
            } catch (e) {
              debugPrint('Error picking image: $e');
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: AppColors.cardBgWarm,
            title: const Row(
              children: [
                Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 28),
                SizedBox(width: 10),
                Text(
                  'Add Memory Photo',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image picker / preview area
                  GestureDetector(
                    onTap: () => _showSourceOptions(context, pickPhoto),
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selectedImagePath != null
                              ? AppColors.primary
                              : AppColors.divider,
                          width: 2,
                        ),
                      ),
                      child: selectedImagePath != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    File(selectedImagePath!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.refresh_rounded, color: Colors.white, size: 14),
                                        SizedBox(width: 4),
                                        Text('Change', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.photo_library_rounded, size: 44, color: AppColors.primaryLight),
                                SizedBox(height: 8),
                                Text(
                                  'Tap to choose from Gallery or Camera',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Upload a cherished photo',
                                  style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppColors.textHint),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Memory Title (e.g. Family at Garden)',
                      hintText: 'Enter a name for this memory',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description or Message',
                      hintText: 'Who or what is in this picture?',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(minimumSize: const Size(130, 44)),
                onPressed: () async {
                  if (titleCtrl.text.trim().isNotEmpty) {
                    final photoPath = selectedImagePath ?? 'assets/images/memory_family.png';
                    await _memoryRepo.addMemory(
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim().isEmpty
                          ? 'A special comforting memory.'
                          : descCtrl.text.trim(),
                      sourceImagePath: photoPath,
                      dateLabel: 'Personal Moment',
                    );
                    await _loadMemories();
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text('Save Photo'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSourceOptions(BuildContext context, Function(ImageSource) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Select Photo Source',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.surfaceVariant,
                child: Icon(Icons.photo_library_rounded, color: AppColors.primary),
              ),
              title: const Text('Choose from Gallery', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(ctx);
                onSelect(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.surfaceVariant,
                child: Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              ),
              title: const Text('Take a Photo with Camera', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(ctx);
                onSelect(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openDetailModal(MemoryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppImageView(
                imagePath: item.imagePath,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
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
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _speakMemory(item),
                          icon: const Icon(Icons.volume_up_rounded, size: 22),
                          label: const Text('Read Aloud'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        if (!item.imagePath.startsWith('assets/')) ...[
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                            tooltip: 'Delete Memory',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: ctx,
                                builder: (c) => AlertDialog(
                                  title: const Text('Delete Photo?'),
                                  content: const Text('Are you sure you want to remove this photo from your memory album?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, true),
                                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await _memoryRepo.deleteMemory(item.id);
                                await _loadMemories();
                                if (ctx.mounted) Navigator.pop(ctx);
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
              const Row(
                children: [
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

          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_memories.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Icon(Icons.photo_library_outlined, size: 54, color: AppColors.textHint),
                    const SizedBox(height: 10),
                    const Text(
                      'No memories added yet',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _addNewMemoryDialog,
                      icon: const Icon(Icons.add_a_photo_rounded, size: 20),
                      label: const Text('Add Your First Photo'),
                    ),
                  ],
                ),
              ),
            )
          else
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
                            child: AppImageView(
                              imagePath: item.imagePath,
                              height: 130,
                              width: double.infinity,
                              fit: BoxFit.cover,
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

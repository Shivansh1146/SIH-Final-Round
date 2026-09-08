import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/reminder_item.dart';
import '../models/patient_profile.dart';
import '../services/reminder_service.dart';
import '../services/audio_narration_service.dart';
import '../theme/app_theme.dart';

class RemindersScreen extends StatefulWidget {
  /// Optional: notify parent when reminders change (for summary card sync).
  final ValueChanged<List<ReminderItem>>? onRemindersUpdated;
  /// Legacy compat — ignored; screen loads from Hive directly.
  final List<ReminderItem>? reminders;
  final bool isEmbedded;

  const RemindersScreen({
    super.key,
    this.reminders,
    this.onRemindersUpdated,
    this.isEmbedded = false,
  });

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<ReminderItem> _items = [];
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _syncFromService();
    ReminderService.instance.addListener(_syncFromService);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ReminderService.instance.initialize(context);
      }
    });
  }

  @override
  void dispose() {
    ReminderService.instance.removeListener(_syncFromService);
    super.dispose();
  }

  void _syncFromService() {
    if (mounted) {
      setState(() {
        _items = List.from(ReminderService.instance.reminders);
      });
      widget.onRemindersUpdated?.call(List.from(_items));
    }
  }

  void _toggleComplete(int index) {
    if (index < 0 || index >= _items.length) return;
    final item = _items[index];
    final willBeCompleted = !item.isCompleted;
    ReminderService.instance.toggleComplete(item.id);

    if (willBeCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'Completed: "${item.title}"',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: AppTheme.forestGreen,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _deleteReminder(int index) {
    if (index < 0 || index >= _items.length) return;
    final deleted = _items[index];
    ReminderService.instance.deleteReminder(deleted.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "${deleted.title}"', style: GoogleFonts.inter()),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppTheme.warmPeach,
          onPressed: () {
            ReminderService.instance.addReminder(deleted);
          },
        ),
        backgroundColor: AppTheme.forestGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showReminderModal([ReminderItem? existingItem]) {
    final titleController = TextEditingController(text: existingItem?.title ?? '');
    final notesController = TextEditingController(text: existingItem?.notes ?? '');
    TimeOfDay selectedTime = existingItem?.time ?? const TimeOfDay(hour: 9, minute: 0);
    String selectedEmoji = existingItem?.emoji ?? '💊';
    ReminderCategory selectedCategory = existingItem?.category ?? ReminderCategory.medicine;
    bool isDaily = existingItem?.isRepeatingDaily ?? true;

    final presetOptions = [
      {'emoji': '💊', 'label': 'Medicine', 'cat': ReminderCategory.medicine},
      {'emoji': '💧', 'label': 'Water', 'cat': ReminderCategory.hydration},
      {'emoji': '🍽', 'label': 'Meal', 'cat': ReminderCategory.meal},
      {'emoji': '🧠', 'label': 'Brain Game', 'cat': ReminderCategory.activity},
      {'emoji': '🚶', 'label': 'Walk', 'cat': ReminderCategory.walk},
      {'emoji': '☕', 'label': 'Tea/Rest', 'cat': ReminderCategory.other},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(modalContext).viewInsets.bottom + 28,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modal Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceBorder,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existingItem == null ? 'Add New Reminder' : 'Edit Reminder',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.forestGreen,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Quick Category Presets
                  Text(
                    'Quick Presets',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: presetOptions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final opt = presetOptions[i];
                        final isSelected = selectedEmoji == opt['emoji'];
                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              selectedEmoji = opt['emoji'] as String;
                              selectedCategory = opt['cat'] as ReminderCategory;
                              if (titleController.text.isEmpty) {
                                titleController.text = opt['label'] as String;
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.forestGreen : AppTheme.sageLight,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: isSelected ? AppTheme.forestGreen : AppTheme.sageBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(opt['emoji'] as String, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  opt['label'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : AppTheme.forestGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Reminder Title
                  Text(
                    'Reminder Title',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Afternoon Blood Pressure Tablet',
                      hintStyle: GoogleFonts.inter(fontSize: 14, color: AppTheme.textLight),
                      filled: true,
                      fillColor: AppTheme.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.forestGreen, width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Time Selector Card
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scheduled Time',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: modalContext,
                                  initialTime: selectedTime,
                                );
                                if (picked != null) {
                                  setModalState(() => selectedTime = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppTheme.background,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.surfaceBorder),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 20, color: AppTheme.forestGreen),
                                    const SizedBox(width: 10),
                                    Text(
                                      selectedTime.format(modalContext),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.edit_rounded, size: 16, color: AppTheme.textSecondary),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Daily Repeat Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.repeat_rounded, color: AppTheme.forestGreen, size: 20),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Repeat Daily',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Alerts every day at this time',
                                  style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: isDaily,
                          activeColor: AppTheme.forestGreen,
                          onChanged: (val) => setModalState(() => isDaily = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Notes input
                  Text(
                    'Notes (Optional)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesController,
                    style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g. Take with a glass of warm water',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: AppTheme.textLight),
                      filled: true,
                      fillColor: AppTheme.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.forestGreen, width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final title = titleController.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please enter a reminder title',
                                  style: GoogleFonts.inter()),
                              backgroundColor: AppTheme.warmTerracotta,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                          return;
                        }

                        final newItem = ReminderItem(
                          id: existingItem?.id ?? 'rem-${DateTime.now().millisecondsSinceEpoch}',
                          title: title,
                          time: selectedTime,
                          emoji: selectedEmoji,
                          category: selectedCategory,
                          isRepeatingDaily: isDaily,
                          notes: notesController.text.trim().isNotEmpty
                              ? notesController.text.trim()
                              : null,
                          isCompleted: existingItem?.isCompleted ?? false,
                        );

                        if (existingItem != null) {
                          ReminderService.instance.updateReminder(newItem);
                        } else {
                          ReminderService.instance.addReminder(newItem);
                        }

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              existingItem == null
                                  ? '✓  "${newItem.title}" reminder added!'
                                  : '✓  "${newItem.title}" reminder updated!',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                            backgroundColor: AppTheme.forestGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.forestGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      child: Text(
                        existingItem == null ? 'Save Reminder' : 'Update Reminder',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _playScheduleAudio() {
    final pending = _items.where((e) => !e.isCompleted).toList();
    final name = PatientProfile.loadFromHive()?.fullName.split(' ').first ?? 'Patient';

    final StringBuffer speechText = StringBuffer();
    speechText.write('Hello $name. Here is your schedule for today. ');
    if (pending.isEmpty) {
      speechText.write('All reminders are completed. Wonderful job!');
    } else {
      for (final p in pending) {
        speechText.write('${p.title} scheduled for ${p.formattedTime}. ');
      }
    }

    // Start real-time speech narration
    AudioNarrationService.instance.speak(speechText.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: AppTheme.forestGreen, size: 24),
            const SizedBox(width: 8),
            Text('Today\'s Audio Schedule', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.pastelYellow,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.graphic_eq_rounded, size: 14, color: AppTheme.warmTerracotta),
                      const SizedBox(width: 4),
                      Text(
                        'SPEAKING ALOUD',
                        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.warmTerracotta),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Here are your upcoming tasks for today, $name:',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            ...pending.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Text(p.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${p.title} at ${p.formattedTime}',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )),
            if (pending.isEmpty)
              Text(
                'All reminders completed! Wonderful job, $name.',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppTheme.forestGreen),
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              AudioNarrationService.instance.stop();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.forestGreen),
            child: const Text('Stop Audio & Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _items.where((e) => e.isCompleted).length;
    final totalCount = _items.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    final filteredList = _items.where((item) {
      if (_filter == 'Pending') return !item.isCompleted;
      if (_filter == 'Completed') return item.isCompleted;
      if (_filter == 'Medicines') return item.category == ReminderCategory.medicine;
      return true;
    }).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.sageLight,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'DAILY RHYTHM',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.0,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.forestGreen,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reminders & Routine',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 24.0 : 30.0,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.forestGreen,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Gentle daily cues for medicine, water, and activities.',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 12.5 : 14.0,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Add Reminder Button & Audio Reader
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.volume_up_rounded, color: AppTheme.forestGreen),
                  tooltip: 'Listen to Schedule',
                  onPressed: _playScheduleAudio,
                ),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  onPressed: () => _showReminderModal(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    isMobile ? 'Add' : 'Add Reminder',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 12.5 : 14.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warmTerracotta,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 14 : 20,
                      vertical: isMobile ? 10 : 12,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Progress Card
        Container(
          padding: const EdgeInsets.all(18.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: AppTheme.surfaceBorder, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: AppTheme.sageLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.check_rounded, color: AppTheme.forestGreen, size: 16),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$completedCount of $totalCount Completed Today',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isMobile ? 14.0 : 16.0,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.forestGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.background,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.forestGreen),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Filter Chips Row
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ['All', 'Pending', 'Completed', 'Medicines'].map((filter) {
              final isSelected = _filter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () => setState(() => _filter = filter),
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.forestGreen : Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected ? AppTheme.forestGreen : AppTheme.surfaceBorder,
                      ),
                    ),
                    child: Text(
                      filter,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 14),

        // Reminders List
        if (filteredList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Column(
              children: [
                const Text('🌿', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text(
                  'No reminders in this view',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap "+ Add Reminder" above to create a gentle routine.',
                  style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.textSecondary),
                ),
              ],
            ),
          )
        else
          ...filteredList.map((item) {
            final index = _items.indexOf(item);
            final isDone = item.isCompleted;

            return Dismissible(
              key: Key(item.id),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.only(right: 20),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: AppTheme.alertCoral,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              ),
              onDismissed: (_) => _deleteReminder(index),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.0),
                  border: Border.all(
                    color: isDone ? AppTheme.surfaceBorder : AppTheme.sageBorder,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  child: Row(
                    children: [
                      // Category Emoji Avatar
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isDone ? AppTheme.background : AppTheme.sageLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(item.emoji, style: const TextStyle(fontSize: 20)),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Title, Time & Notes
                      Expanded(
                        child: InkWell(
                          onTap: () => _toggleComplete(index),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w800,
                                  color: isDone ? AppTheme.textLight : AppTheme.textPrimary,
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDone ? AppTheme.background : AppTheme.pastelYellow,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.formattedTime,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDone ? AppTheme.textLight : AppTheme.warmTerracotta,
                                      ),
                                    ),
                                  ),
                                  if (item.notes != null) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.notes!,
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          color: AppTheme.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Edit Button
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textSecondary),
                        tooltip: 'Edit Reminder',
                        onPressed: () => _showReminderModal(item),
                      ),
                      const SizedBox(width: 4),

                      // Large Accessible Checkbox Toggle
                      InkWell(
                        onTap: () => _toggleComplete(index),
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDone ? AppTheme.forestGreen : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDone ? AppTheme.forestGreen : AppTheme.surfaceBorder,
                              width: 2.0,
                            ),
                          ),
                          child: isDone
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

import 'package:flutter/material.dart';

enum ReminderCategory { medicine, hydration, meal, activity, walk, other }

class ReminderItem {
  final String id;
  String title;
  TimeOfDay time;
  ReminderCategory category;
  String emoji;
  bool isCompleted;
  bool isRepeatingDaily;
  String? notes;

  ReminderItem({
    required this.id,
    required this.title,
    required this.time,
    this.category = ReminderCategory.medicine,
    this.emoji = '💊',
    this.isCompleted = false,
    this.isRepeatingDaily = true,
    this.notes,
  });

  String get formattedTime {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'hour': time.hour,
        'minute': time.minute,
        'category': category.name,
        'emoji': emoji,
        'isCompleted': isCompleted,
        'isRepeatingDaily': isRepeatingDaily,
        'notes': notes,
      };

  factory ReminderItem.fromMap(Map<dynamic, dynamic> map) {
    return ReminderItem(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: map['title'] ?? 'Reminder',
      time: TimeOfDay(hour: map['hour'] ?? 8, minute: map['minute'] ?? 0),
      category: ReminderCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ReminderCategory.medicine,
      ),
      emoji: map['emoji'] ?? '💊',
      isCompleted: map['isCompleted'] ?? false,
      isRepeatingDaily: map['isRepeatingDaily'] ?? true,
      notes: map['notes'],
    );
  }

  static List<ReminderItem> get defaultReminders => [
        ReminderItem(
          id: 'rem-1',
          title: 'Morning medicine',
          time: const TimeOfDay(hour: 8, minute: 0),
          category: ReminderCategory.medicine,
          emoji: '💊',
          notes: 'Take with warm water after breakfast',
          isCompleted: true,
        ),
        ReminderItem(
          id: 'rem-2',
          title: 'Morning hydration & water',
          time: const TimeOfDay(hour: 10, minute: 30),
          category: ReminderCategory.hydration,
          emoji: '💧',
          notes: 'A glass of fresh water',
          isCompleted: false,
        ),
        ReminderItem(
          id: 'rem-3',
          title: 'Lunch & vitamins',
          time: const TimeOfDay(hour: 13, minute: 0),
          category: ReminderCategory.meal,
          emoji: '🍽',
          notes: 'Wholesome nutritious lunch',
          isCompleted: false,
        ),
        ReminderItem(
          id: 'rem-4',
          title: 'Memory Match game activity',
          time: const TimeOfDay(hour: 16, minute: 0),
          category: ReminderCategory.activity,
          emoji: '🧠',
          notes: 'Daily 5-minute cognitive exercise',
          isCompleted: false,
        ),
        ReminderItem(
          id: 'rem-5',
          title: 'Evening garden walk',
          time: const TimeOfDay(hour: 17, minute: 30),
          category: ReminderCategory.walk,
          emoji: '🚶',
          notes: 'Gentle 15-minute stroll in fresh air',
          isCompleted: false,
        ),
        ReminderItem(
          id: 'rem-6',
          title: 'Night medicine',
          time: const TimeOfDay(hour: 21, minute: 0),
          category: ReminderCategory.medicine,
          emoji: '💊',
          notes: 'Before going to bed',
          isCompleted: false,
        ),
      ];
}

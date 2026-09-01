import 'package:flutter_test/flutter_test.dart';
import 'package:neuronova/data/models/task.dart';
import 'package:neuronova/data/models/care_reminder.dart';
import 'package:neuronova/data/models/game_session.dart';
import 'package:neuronova/data/models/content_item.dart';

void main() {
  group('Domain Models Serialization Tests', () {
    test('Task model map serialization and copyWith', () {
      final now = DateTime.now();
      final task = Task(
        id: 't1',
        name: 'Morning Walk',
        scheduledAt: now,
        createdBy: TaskCreator.patient,
        isPrivate: false,
        status: TaskStatus.upcoming,
        notifId: 101,
        createdAt: now,
      );

      final map = task.toMap();
      expect(map['id'], 't1');
      expect(map['name'], 'Morning Walk');
      expect(map['is_private'], 0);
      expect(map['status'], 'upcoming');

      final fromMap = Task.fromMap(map);
      expect(fromMap.id, task.id);
      expect(fromMap.name, task.name);
      expect(fromMap.createdBy, TaskCreator.patient);

      final completed = task.copyWith(status: TaskStatus.done);
      expect(completed.status, TaskStatus.done);
    });

    test('CareReminder model serialization and category parsing', () {
      final now = DateTime.now();
      final reminder = CareReminder(
        id: 'cr1',
        type: CareReminderType.hydration,
        name: 'Drink Water',
        scheduleMode: ReminderScheduleMode.interval,
        configData: {'interval_hours': 2.0},
        isActive: true,
        createdAt: now,
      );

      final map = reminder.toMap();
      expect(map['type'], 'hydration');
      expect(map['schedule_mode'], 'interval');

      final fromMap = CareReminder.fromMap(map);
      expect(fromMap.type, CareReminderType.hydration);
      expect(fromMap.scheduleMode, ReminderScheduleMode.interval);
    });

    test('GameSession model serialization and metrics calculation', () {
      final now = DateTime.now();
      final session = GameSession(
        id: 'gs1',
        gameType: 'read_memorize_speak',
        playedAt: now,
        category: ContentCategory.stories,
        language: 'en',
        length: ContentLength.short,
        difficultyTier: 1,
        contentId: 'story_1',
        textTitle: 'A Quiet River',
        sourceText: 'The river flows gently through the green valley.',
        spokenText: 'The river flows gently through the green valley.',
        scorePercent: 100,
        wordMatchCount: 8,
        totalWords: 8,
      );

      final map = session.toMap();
      expect(map['score_percent'], 100);
      expect(map['category'], 'stories');

      final fromMap = GameSession.fromMap(map);
      expect(fromMap.textTitle, 'A Quiet River');
      expect(fromMap.scorePercent, 100);
    });
  });
}

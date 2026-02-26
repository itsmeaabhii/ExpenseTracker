import 'package:flutter/foundation.dart';

import '../../../features/reminders/domain/reminder.dart';
import '../app_database.dart';

@immutable
class ReminderRepository {
  const ReminderRepository(this._db);

  final AppDatabase _db;

  Future<List<ReminderModel>> getAll() {
    return _db.getReminders();
  }

  Future<List<ReminderModel>> getUpcoming() {
    return _db.getUpcomingReminders();
  }

  Future<void> add(ReminderModel reminder) async {
    await _db.insertReminder(reminder);
  }

  Future<void> update(ReminderModel reminder) async {
    await _db.updateReminder(reminder);
  }

  Future<void> remove(int id) async {
    await _db.deleteReminder(id);
  }

  Future<void> markAsPaid(int id) async {
    final reminders = await _db.getReminders();
    final reminder = reminders.firstWhere((r) => r.id == id);
    final updated = reminder.copyWith(isPaid: true);
    await _db.updateReminder(updated);
  }
}

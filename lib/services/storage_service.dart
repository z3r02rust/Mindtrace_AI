import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/person.dart';
import '../models/session.dart';

class StorageService {
  static const _kPeople = 'mt_people';
  static const _kSessions = 'mt_sessions';
  static const _kProfileName = 'mt_profile_name';
  static const _kProfileAge = 'mt_profile_age';
  static const _kProfileHealth = 'mt_profile_health';
  static const _kProfileNotes = 'mt_profile_notes';
  static const _kProfileUpdatedAt = 'mt_profile_updated_at';
  static const _kDeletedPersonIds = 'mt_deleted_person_ids';

  static Future<List<Person>> loadPeople() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPeople);
    if (raw == null || raw.isEmpty) return _seedPeople();
    try {
      return Person.decodeList(raw);
    } catch (error) {
      debugPrint('Lokal odamlar ma’lumotini o‘qib bo‘lmadi: $error');
      return _seedPeople();
    }
  }

  static Future<void> savePeople(List<Person> people) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPeople, Person.encodeList(people));
  }

  static Future<Set<String>> loadDeletedPersonIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_kDeletedPersonIds) ?? const <String>[])
        .toSet();
  }

  static Future<void> saveDeletedPersonIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kDeletedPersonIds, ids.toList()..sort());
  }

  static Future<List<TrainingSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSessions);
    if (raw == null || raw.isEmpty) return [];
    try {
      return TrainingSession.decodeList(raw);
    } catch (error) {
      debugPrint('Lokal sessiyalarni o‘qib bo‘lmadi: $error');
      return [];
    }
  }

  static Future<void> saveSessions(List<TrainingSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSessions, TrainingSession.encodeList(sessions));
  }

  static Future<void> addSession(TrainingSession session) async {
    final sessions = await loadSessions();
    sessions.add(session);
    await saveSessions(sessions);
  }

  static Future<Map<String, String>> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_kProfileName) ?? 'Foydalanuvchi',
      'age': prefs.getString(_kProfileAge) ?? '—',
      'health': prefs.getString(_kProfileHealth) ?? 'Sog\'lom',
      'notes': prefs.getString(_kProfileNotes) ?? 'Tibbiy eslatma yo\'q',
      'updatedAt':
          prefs.getString(_kProfileUpdatedAt) ??
          DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
    };
  }

  static Future<void> saveProfile({
    required String name,
    required String age,
    required String health,
    required String notes,
    String? updatedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfileName, name);
    await prefs.setString(_kProfileAge, age);
    await prefs.setString(_kProfileHealth, health);
    await prefs.setString(_kProfileNotes, notes);
    await prefs.setString(
      _kProfileUpdatedAt,
      updatedAt ?? DateTime.now().toIso8601String(),
    );
  }

  static int computeStreak(List<TrainingSession> sessions) {
    final days = _uniqueDayNumbers(sessions);
    if (days.isEmpty) return 0;

    final now = DateTime.now();
    final today = _dayNumber(now);
    final validDays = days.where((day) => day <= today).toList();
    if (validDays.isEmpty || today - validDays.first > 1) return 0;

    var streak = 1;
    for (var index = 1; index < validDays.length; index++) {
      if (validDays[index - 1] - validDays[index] != 1) break;
      streak++;
    }
    return streak;
  }

  static int computeBestStreak(List<TrainingSession> sessions) {
    final days = _uniqueDayNumbers(sessions);
    if (days.isEmpty) return 0;

    var best = 1;
    var current = 1;
    for (var index = 1; index < days.length; index++) {
      if (days[index - 1] - days[index] == 1) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }
    return best;
  }

  static List<int> _uniqueDayNumbers(List<TrainingSession> sessions) {
    final result =
        sessions.map((session) => _dayNumber(session.date)).toSet().toList()
          ..sort((a, b) => b.compareTo(a));
    return result;
  }

  static int _dayNumber(DateTime date) {
    return DateTime.utc(
          date.year,
          date.month,
          date.day,
        ).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }

  static List<Person> _seedPeople() => [
    Person(
      id: 'p1',
      name: 'Aziza',
      relation: 'Ona',
      notes: 'Toshkent, Chilonzor tumani',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
    Person(
      id: 'p2',
      name: 'Sardor',
      relation: 'Ota',
      notes: "Tug'ilgan kuni: 14-mart",
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
    Person(
      id: 'p3',
      name: 'Malika',
      relation: "Do'st",
      notes: 'Universitet do\'sti',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
    Person(
      id: 'p4',
      name: 'Jasur',
      relation: 'Qo\'shni',
      notes: '3-qavat, 12-xonadon',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
  ];
}

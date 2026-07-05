import 'package:shared_preferences/shared_preferences.dart';
import '../models/person.dart';
import '../models/session.dart';


class StorageService {
  static const _kPeople = 'mt_people';
  static const _kSessions = 'mt_sessions';
  static const _kProfileName = 'mt_profile_name';
  static const _kProfileAge = 'mt_profile_age';
  static const _kProfileHealth = 'mt_profile_health';
  static const _kProfileNotes = 'mt_profile_notes';

  static Future<List<Person>> loadPeople() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPeople);
    if (raw == null || raw.isEmpty) return _seedPeople();
    return Person.decodeList(raw);
  }

  static Future<void> savePeople(List<Person> people) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPeople, Person.encodeList(people));
  }

  static Future<List<TrainingSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSessions);
    if (raw == null || raw.isEmpty) return [];
    return TrainingSession.decodeList(raw);
  }

  static Future<void> addSession(TrainingSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await loadSessions();
    sessions.add(session);
    await prefs.setString(_kSessions, TrainingSession.encodeList(sessions));
  }

  static Future<Map<String, String>> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_kProfileName) ?? 'Foydalanuvchi',
      'age': prefs.getString(_kProfileAge) ?? '—',
      'health': prefs.getString(_kProfileHealth) ?? 'Sog\'lom',
      'notes': prefs.getString(_kProfileNotes) ?? 'Tibbiy eslatma yo\'q',
    };
  }

  static Future<void> saveProfile({
    required String name,
    required String age,
    required String health,
    required String notes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfileName, name);
    await prefs.setString(_kProfileAge, age);
    await prefs.setString(_kProfileHealth, health);
    await prefs.setString(_kProfileNotes, notes);
  }


  static int computeStreak(List<TrainingSession> sessions) {
    if (sessions.isEmpty) return 0;
    final days = sessions
        .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);

    for (final day in days) {
      final diff = cursor.difference(day).inDays;
      if (diff == 0 || diff == streak) {
        streak++;
        cursor = day;
      } else {
        break;
      }
    }
    return streak;
  }

  static List<Person> _seedPeople() => [
        Person(id: 'p1', name: 'Aziza', relation: 'Ona', notes: 'Toshkent, Chilonzor tumani'),
        Person(id: 'p2', name: 'Sardor', relation: 'Ota', notes: "Tug'ilgan kuni: 14-mart"),
        Person(id: 'p3', name: 'Malika', relation: "Do'st", notes: 'Universitet do\'sti'),
        Person(id: 'p4', name: 'Jasur', relation: 'Qo\'shni', notes: '3-qavat, 12-xonadon'),
      ];
}

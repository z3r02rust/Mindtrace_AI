import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/person.dart';
import '../models/session.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/spaced_repetition_service.dart';
import '../services/storage_service.dart';


class AppState extends ChangeNotifier {
  List<Person> people = [];
  List<TrainingSession> sessions = [];
  Map<String, String> profile = {};
  bool isLoading = true;

  DatabaseService? _db;
  String? _uid;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    people = await StorageService.loadPeople();
    sessions = await StorageService.loadSessions();
    profile = await StorageService.loadProfile();
    isLoading = false;
    notifyListeners();


    await _syncWithFirebase();
  }

  Future<void> _syncWithFirebase() async {
    try {
      _uid = await AuthService.ensureSignedIn();
      _db = DatabaseService(_uid!);

      final remotePeople = await _db!.loadPeople();
      final remoteSessions = await _db!.loadSessions();
      final remoteProfile = await _db!.loadProfile();

      if (remotePeople.isEmpty && people.isNotEmpty) {

        await _db!.savePeopleBatch(people);
      } else if (remotePeople.isNotEmpty) {

        people = remotePeople;
        await StorageService.savePeople(people);
      }

      if (remoteSessions.length > sessions.length) {
        sessions = remoteSessions;
      }

      if (remoteProfile != null && remoteProfile.isNotEmpty) {
        profile = remoteProfile;
        await StorageService.saveProfile(
          name: profile['name'] ?? '',
          age: profile['age'] ?? '',
          health: profile['health'] ?? '',
          notes: profile['notes'] ?? '',
        );
      }

      notifyListeners();
    } catch (e) {

      debugPrint('Firebase sinxronizatsiya xatosi (offline rejimda davom etilmoqda): $e');
    }
  }



  int get streak => StorageService.computeStreak(sessions);

  int get totalXp => sessions.fold(0, (sum, s) => sum + s.xpEarned);

  int get level => (totalXp / 100).floor() + 1;

  double get levelProgress => (totalXp % 100) / 100;

  double domainAccuracy(CognitiveDomain d) {
    final attempts = sessions.expand((s) => s.attempts).where((a) => a.domain == d).toList();
    if (attempts.isEmpty) return 0;
    return attempts.where((a) => a.correct).length / attempts.length;
  }


  int get cognitiveScore {
    final domains = CognitiveDomain.values;
    final scores = domains.map(domainAccuracy).where((v) => v > 0).toList();
    if (scores.isEmpty) return 0;
    return (scores.reduce((a, b) => a + b) / scores.length * 100).round();
  }

  CognitiveDomain? get weakestDomain {
    final withData = CognitiveDomain.values.where((d) => domainAccuracy(d) > 0);
    if (withData.isEmpty) return null;
    return withData.reduce((a, b) => domainAccuracy(a) <= domainAccuracy(b) ? a : b);
  }


  List<int> get last7DaysSessionCounts {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
      return sessions.where((s) {
        final d = DateTime(s.date.year, s.date.month, s.date.day);
        return d == day;
      }).length;
    });
  }


  Future<void> submitTrainingSession(List<ExerciseAttempt> attempts, List<Person> updatedPeople) async {
    people = updatedPeople;
    final session = TrainingSession(date: DateTime.now(), attempts: attempts);
    sessions = [...sessions, session];
    await StorageService.savePeople(people);
    await StorageService.addSession(session);
    notifyListeners();


    unawaited(_db?.savePeopleBatch(people));
    unawaited(_db?.addSession(session));
  }

  Future<void> addPerson(Person p) async {
    people = [...people, p];
    await StorageService.savePeople(people);
    notifyListeners();
    unawaited(_db?.savePerson(p));
  }

  Future<void> updatePerson(Person p) async {
    people = people.map((e) => e.id == p.id ? p : e).toList();
    await StorageService.savePeople(people);
    notifyListeners();
    unawaited(_db?.savePerson(p));
  }

  Future<void> deletePerson(String id) async {
    people = people.where((e) => e.id != id).toList();
    await StorageService.savePeople(people);
    notifyListeners();
    unawaited(_db?.deletePerson(id));
  }

  Future<void> updateProfile(Map<String, String> newProfile) async {
    profile = newProfile;
    await StorageService.saveProfile(
      name: newProfile['name'] ?? '',
      age: newProfile['age'] ?? '',
      health: newProfile['health'] ?? '',
      notes: newProfile['notes'] ?? '',
    );
    notifyListeners();
    unawaited(_db?.saveProfile(newProfile));
  }

  List<Person> get duePeopleToday => SpacedRepetitionService.dueToday(people);
}

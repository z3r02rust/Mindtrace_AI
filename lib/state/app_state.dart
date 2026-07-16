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
  Set<String> _pendingDeletedPersonIds = <String>{};

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    people = await StorageService.loadPeople();
    _pendingDeletedPersonIds = await StorageService.loadDeletedPersonIds();
    sessions = await StorageService.loadSessions();
    profile = await StorageService.loadProfile();
    isLoading = false;
    notifyListeners();

    await _syncWithFirebase();
  }

  Future<void> _syncWithFirebase() async {
    try {
      final uid = await AuthService.ensureSignedIn();
      final db = DatabaseService(uid);
      _db = db;

      final remotePeople = await db.loadPeople();
      final remoteSessions = await db.loadSessions();
      final remoteProfile = await db.loadProfile();

      for (final id in _pendingDeletedPersonIds) {
        await db.deletePerson(id);
      }
      final activeRemotePeople = remotePeople
          .where((person) => !_pendingDeletedPersonIds.contains(person.id))
          .toList();

      people = _mergePeople(people, activeRemotePeople);
      sessions = _mergeSessions(sessions, remoteSessions);
      profile = _mergeProfile(profile, remoteProfile);

      await Future.wait<void>([
        StorageService.savePeople(people),
        StorageService.saveSessions(sessions),
        _saveProfileLocally(profile),
      ]);

      _pendingDeletedPersonIds.clear();
      await StorageService.saveDeletedPersonIds(_pendingDeletedPersonIds);

      await Future.wait<void>([
        db.savePeopleBatch(people),
        db.saveSessionsBatch(sessions),
        db.saveProfile(profile),
      ]);

      notifyListeners();
    } catch (error, stack) {
      debugPrint(
        'Firebase sinxronizatsiya xatosi (offline rejim davom etadi): $error',
      );
      debugPrintStack(stackTrace: stack);
    }
  }

  static List<Person> _mergePeople(List<Person> local, List<Person> remote) {
    final merged = <String, Person>{
      for (final person in remote) person.id: person,
    };
    for (final localPerson in local) {
      final remotePerson = merged[localPerson.id];
      if (remotePerson == null ||
          localPerson.updatedAt.isAfter(remotePerson.updatedAt)) {
        merged[localPerson.id] = localPerson;
      }
    }
    final result = merged.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  static List<TrainingSession> _mergeSessions(
    List<TrainingSession> local,
    List<TrainingSession> remote,
  ) {
    final merged = <String, TrainingSession>{
      for (final session in remote) session.id: session,
      for (final session in local) session.id: session,
    };
    final result = merged.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  static Map<String, String> _mergeProfile(
    Map<String, String> local,
    Map<String, String>? remote,
  ) {
    if (remote == null || remote.isEmpty) {
      return Map<String, String>.from(local);
    }
    if (local.isEmpty) return Map<String, String>.from(remote);

    final localUpdatedAt = _profileUpdatedAt(local);
    final remoteUpdatedAt = _profileUpdatedAt(remote);
    return Map<String, String>.from(
      localUpdatedAt.isAfter(remoteUpdatedAt) ? local : remote,
    );
  }

  static DateTime _profileUpdatedAt(Map<String, String> value) {
    return DateTime.tryParse(value['updatedAt'] ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static Future<void> _saveProfileLocally(Map<String, String> value) {
    return StorageService.saveProfile(
      name: value['name'] ?? '',
      age: value['age'] ?? '',
      health: value['health'] ?? '',
      notes: value['notes'] ?? '',
      updatedAt: value['updatedAt'],
    );
  }

  int get streak => StorageService.computeStreak(sessions);

  int get bestStreak => StorageService.computeBestStreak(sessions);

  int get totalXp => sessions.fold(0, (sum, session) => sum + session.xpEarned);

  int get level => (totalXp / 100).floor() + 1;

  double get levelProgress => (totalXp % 100) / 100;

  int domainAttemptCount(CognitiveDomain domain) {
    return sessions
        .expand((session) => session.attempts)
        .where((attempt) => attempt.domain == domain)
        .length;
  }

  double domainAccuracy(CognitiveDomain domain) {
    final attempts = sessions
        .expand((session) => session.attempts)
        .where((attempt) => attempt.domain == domain)
        .toList();
    if (attempts.isEmpty) return 0;
    return attempts.where((attempt) => attempt.correct).length /
        attempts.length;
  }

  int get cognitiveScore {
    final domainsWithData = trainedCognitiveDomains
        .where((domain) => domainAttemptCount(domain) > 0)
        .toList();
    if (domainsWithData.isEmpty) return 0;
    final total = domainsWithData
        .map(domainAccuracy)
        .reduce((first, second) => first + second);
    return (total / domainsWithData.length * 100).round();
  }

  CognitiveDomain? get weakestDomain {
    final domainsWithData = trainedCognitiveDomains
        .where((domain) => domainAttemptCount(domain) > 0)
        .toList();
    if (domainsWithData.isEmpty) return null;
    return domainsWithData.reduce(
      (first, second) =>
          domainAccuracy(first) <= domainAccuracy(second) ? first : second,
    );
  }

  String get aiContextSignature {
    final domainSignature = trainedCognitiveDomains
        .map(
          (domain) =>
              '${domain.index}:${domainAttemptCount(domain)}:${domainAccuracy(domain).toStringAsFixed(3)}',
        )
        .join('|');
    final lastSessionId = sessions.isEmpty ? '-' : sessions.last.id;
    return '${sessions.length}:$lastSessionId:$streak:$domainSignature';
  }

  List<int> get last7DaysSessionCounts {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - index));
      return sessions.where((session) {
        final sessionDay = DateTime(
          session.date.year,
          session.date.month,
          session.date.day,
        );
        return sessionDay == day;
      }).length;
    });
  }

  Future<void> submitTrainingSession(
    List<ExerciseAttempt> attempts,
    List<Person> updatedPeople,
  ) async {
    people = updatedPeople;
    final session = TrainingSession(date: DateTime.now(), attempts: attempts);
    sessions = [...sessions, session];
    await Future.wait<void>([
      StorageService.savePeople(people),
      StorageService.addSession(session),
    ]);
    notifyListeners();

    final db = _db;
    if (db != null) {
      _runRemote(db.savePeopleBatch(people));
      _runRemote(db.addSession(session));
    }
  }

  Future<void> addPerson(Person person) async {
    final normalized = person.copyWith(
      relation: person.relation.trim().isEmpty
          ? 'Yaqin inson'
          : person.relation.trim(),
      updatedAt: DateTime.now(),
    );
    people = [...people, normalized];
    await StorageService.savePeople(people);
    notifyListeners();
    final db = _db;
    if (db != null) _runRemote(db.savePerson(normalized));
  }

  Future<void> updatePerson(Person person) async {
    final normalized = person.copyWith(
      relation: person.relation.trim().isEmpty
          ? 'Yaqin inson'
          : person.relation.trim(),
      updatedAt: DateTime.now(),
    );
    people = people
        .map((existing) => existing.id == normalized.id ? normalized : existing)
        .toList();
    await StorageService.savePeople(people);
    notifyListeners();
    final db = _db;
    if (db != null) _runRemote(db.savePerson(normalized));
  }

  Future<void> deletePerson(String id) async {
    people = people.where((person) => person.id != id).toList();
    _pendingDeletedPersonIds.add(id);
    await Future.wait<void>([
      StorageService.savePeople(people),
      StorageService.saveDeletedPersonIds(_pendingDeletedPersonIds),
    ]);
    notifyListeners();
    final db = _db;
    if (db != null) _runRemote(_deletePersonRemotely(db, id));
  }

  Future<void> _deletePersonRemotely(DatabaseService db, String id) async {
    await db.deletePerson(id);
    _pendingDeletedPersonIds.remove(id);
    await StorageService.saveDeletedPersonIds(_pendingDeletedPersonIds);
  }

  Future<void> updateProfile(Map<String, String> newProfile) async {
    profile = {...newProfile, 'updatedAt': DateTime.now().toIso8601String()};
    await _saveProfileLocally(profile);
    notifyListeners();
    final db = _db;
    if (db != null) _runRemote(db.saveProfile(profile));
  }

  void _runRemote(Future<void> operation) {
    unawaited(
      operation.catchError((Object error, StackTrace stack) {
        debugPrint('Firebase fon yozuvi bajarilmadi: $error');
        debugPrintStack(stackTrace: stack);
      }),
    );
  }

  List<Person> get duePeopleToday => SpacedRepetitionService.dueToday(people);
}

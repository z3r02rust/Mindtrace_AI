import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/person.dart';
import '../models/session.dart';

class DatabaseService {
  final String uid;
  DatabaseService(this.uid);

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> get _peopleRef =>
      _userDoc.collection('people');
  CollectionReference<Map<String, dynamic>> get _sessionsRef =>
      _userDoc.collection('sessions');

  // ---------- Odamlar (Person) ----------

  Future<void> savePerson(Person person) async {
    await _peopleRef.doc(person.id).set(person.toJson());
  }

  Future<void> deletePerson(String personId) async {
    await _peopleRef.doc(personId).delete();
  }

  Future<List<Person>> loadPeople() async {
    final snap = await _peopleRef.get();
    return snap.docs.map((d) => Person.fromJson(d.data())).toList();
  }

  // ---------- Mashg'ulot sessiyalari ----------

  Future<void> addSession(TrainingSession session) async {
    await _sessionsRef.doc(session.id).set(session.toJson());
  }

  Future<List<TrainingSession>> loadSessions() async {
    final snap = await _sessionsRef.get();
    return snap.docs.map((d) => TrainingSession.fromJson(d.data())).toList();
  }

  // ---------- Profil ----------

  Future<void> saveProfile(Map<String, String> profile) async {
    await _userDoc.set(profile, SetOptions(merge: true));
  }

  Future<Map<String, String>?> loadProfile() async {
    final doc = await _userDoc.get();
    if (!doc.exists || doc.data() == null) return null;
    return doc.data()!.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<void> savePeopleBatch(List<Person> people) async {
    if (people.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final p in people) {
      batch.set(_peopleRef.doc(p.id), p.toJson());
    }
    await batch.commit();
  }

  Future<void> saveSessionsBatch(List<TrainingSession> sessions) async {
    if (sessions.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final session in sessions) {
      batch.set(_sessionsRef.doc(session.id), session.toJson());
    }
    await batch.commit();
  }
}

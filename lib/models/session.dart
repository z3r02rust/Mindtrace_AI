import 'dart:convert';

/// Kognitiv sohalar — har bir mashq shulardan biriga tegishli bo'ladi.
/// Bu tasodifiy emas, balki AI Analysis ekranidagi haqiqiy statistikani
/// hisoblash uchun asos bo'ladi.
enum CognitiveDomain {
  workingMemory,
  episodicMemory,
  attention,
  processingSpeed,
}

// Reaksiya tezligi uchun alohida mashq hali yo‘q. Legacy qiymatni saqlash
// formatini buzmaslik uchun enumda qoldiramiz, lekin statistikaga kiritmaymiz.
const trainedCognitiveDomains = <CognitiveDomain>[
  CognitiveDomain.workingMemory,
  CognitiveDomain.episodicMemory,
  CognitiveDomain.attention,
];

extension CognitiveDomainLabel on CognitiveDomain {
  String get label {
    switch (this) {
      case CognitiveDomain.workingMemory:
        return 'Ishchi xotira';
      case CognitiveDomain.episodicMemory:
        return 'Ism/Yuz xotirasi';
      case CognitiveDomain.attention:
        return 'Diqqat';
      case CognitiveDomain.processingSpeed:
        return 'Reaksiya tezligi';
    }
  }
}

class ExerciseAttempt {
  final CognitiveDomain domain;
  final bool correct;
  final int reactionMs;
  final DateTime timestamp;

  ExerciseAttempt({
    required this.domain,
    required this.correct,
    required this.reactionMs,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'domain': domain.index,
    'correct': correct,
    'reactionMs': reactionMs,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ExerciseAttempt.fromJson(Map<String, dynamic> j) {
    final domainIndex = (j['domain'] as num?)?.toInt() ?? 0;
    final safeDomainIndex = domainIndex
        .clamp(0, CognitiveDomain.values.length - 1)
        .toInt();
    return ExerciseAttempt(
      domain: CognitiveDomain.values[safeDomainIndex],
      correct: j['correct'] == true,
      reactionMs: (j['reactionMs'] as num?)?.toInt() ?? 0,
      timestamp:
          DateTime.tryParse(j['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class TrainingSession {
  final String id;
  final DateTime date;
  final List<ExerciseAttempt> attempts;

  TrainingSession({String? id, required this.date, required this.attempts})
    : id = id ?? date.microsecondsSinceEpoch.toString();

  int get xpEarned =>
      attempts.where((a) => a.correct).length * 10 + attempts.length * 2;
  double get accuracy => attempts.isEmpty
      ? 0
      : attempts.where((a) => a.correct).length / attempts.length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'attempts': attempts.map((a) => a.toJson()).toList(),
  };

  factory TrainingSession.fromJson(Map<String, dynamic> j) {
    final date =
        DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now();
    final rawAttempts = j['attempts'];
    return TrainingSession(
      id: j['id']?.toString(),
      date: date,
      attempts: rawAttempts is List
          ? rawAttempts
                .whereType<Map>()
                .map(
                  (attempt) => ExerciseAttempt.fromJson(
                    Map<String, dynamic>.from(attempt),
                  ),
                )
                .toList()
          : <ExerciseAttempt>[],
    );
  }

  static String encodeList(List<TrainingSession> list) =>
      jsonEncode(list.map((s) => s.toJson()).toList());

  static List<TrainingSession> decodeList(String jsonStr) {
    final data = jsonDecode(jsonStr) as List;
    return data
        .whereType<Map>()
        .map(
          (item) => TrainingSession.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
}

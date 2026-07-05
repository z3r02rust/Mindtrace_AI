import 'dart:convert';

/// Kognitiv sohalar — har bir mashq shulardan biriga tegishli bo'ladi.
/// Bu tasodifiy emas, balki AI Analysis ekranidagi haqiqiy statistikani
/// hisoblash uchun asos bo'ladi.
enum CognitiveDomain { workingMemory, episodicMemory, attention, processingSpeed }

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

  factory ExerciseAttempt.fromJson(Map<String, dynamic> j) => ExerciseAttempt(
        domain: CognitiveDomain.values[j['domain']],
        correct: j['correct'],
        reactionMs: j['reactionMs'],
        timestamp: DateTime.parse(j['timestamp']),
      );
}

class TrainingSession {
  final DateTime date;
  final List<ExerciseAttempt> attempts;

  TrainingSession({required this.date, required this.attempts});

  int get xpEarned => attempts.where((a) => a.correct).length * 10 + attempts.length * 2;
  double get accuracy => attempts.isEmpty
      ? 0
      : attempts.where((a) => a.correct).length / attempts.length;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'attempts': attempts.map((a) => a.toJson()).toList(),
      };

  factory TrainingSession.fromJson(Map<String, dynamic> j) => TrainingSession(
        date: DateTime.parse(j['date']),
        attempts: (j['attempts'] as List)
            .map((e) => ExerciseAttempt.fromJson(e))
            .toList(),
      );

  static String encodeList(List<TrainingSession> list) =>
      jsonEncode(list.map((s) => s.toJson()).toList());

  static List<TrainingSession> decodeList(String jsonStr) {
    final data = jsonDecode(jsonStr) as List;
    return data.map((e) => TrainingSession.fromJson(e)).toList();
  }
}

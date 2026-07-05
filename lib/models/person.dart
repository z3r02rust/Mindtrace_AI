import 'dart:convert';

/// Yaqin inson modeli. Xotira mashqlari uchun ishlatiladi.
/// SM-2 (SuperMemo-2) spaced-repetition algoritmi maydonlarini o'z ichiga oladi,
/// shuning uchun har bir kishi haqiqiy ilmiy asoslangan jadval bo'yicha
/// takrorlanadi (unutish egri chizig'iga qarshi).
class Person {
  final String id;
  String name;
  String relation; // masalan: Ota, Ona, Do'st, Qo'shni
  String notes; // qo'shimcha eslash uchun kontekst (manzil, tug'ilgan kun va h.k.)

  // Spaced repetition holati (SM-2 soddalashtirilgan versiyasi)
  double easeFactor;
  int intervalDays;
  int repetitions;
  DateTime nextReview;
  DateTime? lastReviewed;

  Person({
    required this.id,
    required this.name,
    required this.relation,
    this.notes = '',
    this.easeFactor = 2.5,
    this.intervalDays = 0,
    this.repetitions = 0,
    DateTime? nextReview,
    this.lastReviewed,
  }) : nextReview = nextReview ?? DateTime.now();

  bool get isDue => nextReview.isBefore(DateTime.now()) || repetitions == 0;

  /// 0.0–1.0 oralig'ida taxminiy "xotira kuchi".
  /// Ko'proq muvaffaqiyatli takrorlash va yuqori ease-factor -> kuchliroq xotira.
  double get memoryStrength {
    final repFactor = (repetitions / 6).clamp(0.0, 1.0);
    final easeFactorNorm = ((easeFactor - 1.3) / (2.8 - 1.3)).clamp(0.0, 1.0);
    return (repFactor * 0.6 + easeFactorNorm * 0.4).clamp(0.0, 1.0);
  }

  Person copyWith({
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    DateTime? nextReview,
    DateTime? lastReviewed,
  }) {
    return Person(
      id: id,
      name: name,
      relation: relation,
      notes: notes,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      nextReview: nextReview ?? this.nextReview,
      lastReviewed: lastReviewed ?? this.lastReviewed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'relation': relation,
        'notes': notes,
        'easeFactor': easeFactor,
        'intervalDays': intervalDays,
        'repetitions': repetitions,
        'nextReview': nextReview.toIso8601String(),
        'lastReviewed': lastReviewed?.toIso8601String(),
      };

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'],
        name: json['name'],
        relation: json['relation'],
        notes: json['notes'] ?? '',
        easeFactor: (json['easeFactor'] as num).toDouble(),
        intervalDays: json['intervalDays'],
        repetitions: json['repetitions'],
        nextReview: DateTime.parse(json['nextReview']),
        lastReviewed: json['lastReviewed'] != null
            ? DateTime.parse(json['lastReviewed'])
            : null,
      );

  static String encodeList(List<Person> list) =>
      jsonEncode(list.map((p) => p.toJson()).toList());

  static List<Person> decodeList(String jsonStr) {
    final data = jsonDecode(jsonStr) as List;
    return data.map((e) => Person.fromJson(e)).toList();
  }
}

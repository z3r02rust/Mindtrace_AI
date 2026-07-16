import 'dart:convert';

/// Yaqin inson modeli. Xotira mashqlari uchun ishlatiladi.
/// SM-2 (SuperMemo-2) spaced-repetition algoritmi maydonlarini o'z ichiga oladi,
/// shuning uchun har bir kishi haqiqiy ilmiy asoslangan jadval bo'yicha
/// takrorlanadi (unutish egri chizig'iga qarshi).
class Person {
  final String id;
  String name;
  String relation; // masalan: Ota, Ona, Do'st, Qo'shni
  String
  notes; // qo'shimcha eslash uchun kontekst (manzil, tug'ilgan kun va h.k.)

  // Spaced repetition holati (SM-2 soddalashtirilgan versiyasi)
  double easeFactor;
  int intervalDays;
  int repetitions;
  DateTime nextReview;
  DateTime? lastReviewed;
  DateTime updatedAt;

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
    DateTime? updatedAt,
  }) : nextReview = nextReview ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isDue => nextReview.isBefore(DateTime.now()) || repetitions == 0;

  /// 0.0–1.0 oralig'ida taxminiy "xotira kuchi".
  /// Ko'proq muvaffaqiyatli takrorlash va yuqori ease-factor -> kuchliroq xotira.
  double get memoryStrength {
    final repFactor = (repetitions / 6).clamp(0.0, 1.0);
    final easeFactorNorm = ((easeFactor - 1.3) / (2.8 - 1.3)).clamp(0.0, 1.0);
    return (repFactor * 0.6 + easeFactorNorm * 0.4).clamp(0.0, 1.0);
  }

  Person copyWith({
    String? name,
    String? relation,
    String? notes,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    DateTime? nextReview,
    DateTime? lastReviewed,
    DateTime? updatedAt,
  }) {
    return Person(
      id: id,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      notes: notes ?? this.notes,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      nextReview: nextReview ?? this.nextReview,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      updatedAt: updatedAt ?? this.updatedAt,
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
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Person.fromJson(Map<String, dynamic> json) => Person(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    relation: json['relation']?.toString() ?? '',
    notes: json['notes']?.toString() ?? '',
    easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
    intervalDays: (json['intervalDays'] as num?)?.toInt() ?? 0,
    repetitions: (json['repetitions'] as num?)?.toInt() ?? 0,
    nextReview: _parseDate(json['nextReview']) ?? DateTime.now(),
    lastReviewed: json['lastReviewed'] != null
        ? _parseDate(json['lastReviewed'])
        : null,
    updatedAt:
        _parseDate(json['updatedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
  );

  static String encodeList(List<Person> list) =>
      jsonEncode(list.map((p) => p.toJson()).toList());

  static List<Person> decodeList(String jsonStr) {
    final data = jsonDecode(jsonStr) as List;
    return data
        .whereType<Map>()
        .map((item) => Person.fromJson(Map<String, dynamic>.from(item)))
        .where((person) => person.id.isNotEmpty && person.name.isNotEmpty)
        .toList();
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

import '../models/person.dart';


class SpacedRepetitionService {
  static Person review(Person person, {required bool correct}) {
    // quality: 0-5 shkala, biz oddiy to'g'ri/noto'g'ri dan hosil qilamiz
    final int quality = correct ? 4 : 2;

    int repetitions = person.repetitions;
    int interval = person.intervalDays;
    double ease = person.easeFactor;

    if (quality < 3) {
      repetitions = 0;
      interval = 1;
    } else {
      repetitions += 1;
      if (repetitions == 1) {
        interval = 1;
      } else if (repetitions == 2) {
        interval = 3;
      } else {
        interval = (interval * ease).round();
      }
    }

    ease = ease + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (ease < 1.3) ease = 1.3;

    return person.copyWith(
      easeFactor: ease,
      intervalDays: interval,
      repetitions: repetitions,
      nextReview: DateTime.now().add(Duration(days: interval)),
      lastReviewed: DateTime.now(),
    );
  }

  /// Bugun mashq qilinishi kerak bo'lgan (yoki hali umuman mashq qilinmagan)
  /// odamlar ro'yxati.
  static List<Person> dueToday(List<Person> people) {
    final due = people.where((p) => p.isDue).toList();
    return due.isNotEmpty ? due : people; // hech kim due bo'lmasa - hammasidan foydalan
  }
}

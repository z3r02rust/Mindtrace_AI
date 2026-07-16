import '../models/session.dart';
import '../state/app_state.dart';
import 'gemini_service.dart';

class CoachInsightResult {
  final String text;
  final bool generatedByAi;
  final String? error;

  const CoachInsightResult({
    required this.text,
    required this.generatedByAi,
    this.error,
  });
}

class AiCoachService {
  static String localInsight(AppState state) {
    if (state.sessions.isEmpty) {
      return "Hali birorta mashg'ulot bajarilmagan. Birinchi sessiyadan so'ng "
          "tizim sizning zaif va kuchli tomonlaringizni aniqlay boshlaydi.";
    }

    final weakest = state.weakestDomain;
    final score = state.cognitiveScore;
    final streak = state.streak;
    final buffer = StringBuffer();

    if (score >= 80) {
      buffer.write(
        "Ajoyib natija — umumiy kognitiv ko'rsatkichingiz $score/100. ",
      );
    } else if (score >= 50) {
      buffer.write(
        "Yaxshi sur'at — umumiy kognitiv ko'rsatkichingiz $score/100. ",
      );
    } else {
      buffer.write(
        "Umumiy kognitiv ko'rsatkichingiz $score/100 — barqaror mashq bilan yaxshilanadi. ",
      );
    }

    if (weakest != null) {
      final acc = (state.domainAccuracy(weakest) * 100).round();
      buffer.write(
        '"${weakest.label}" sohasi hozircha eng zaif ($acc% aniqlik). '
        'Keyingi mashg\'ulotlarda tizim shu sohaga ko\'proq urg\'u beradi. ',
      );
    }

    if (streak >= 3) {
      buffer.write(
        "$streak kunlik streak — davomiylik xotira mustahkamlanishi uchun eng muhim omil.",
      );
    } else {
      buffer.write(
        "Muntazamlik muhim: kuniga 10-15 daqiqa, haftada kamida 4 marta mashq tavsiya etiladi.",
      );
    }

    return buffer.toString();
  }

  static Future<CoachInsightResult> deepInsight(AppState state) async {
    final local = localInsight(state);
    if (state.sessions.isEmpty) {
      return CoachInsightResult(text: local, generatedByAi: false);
    }

    try {
      final domainMap = {
        for (final domain in trainedCognitiveDomains)
          domain.label: state.domainAccuracy(domain),
      };

      final result = await GeminiService.coachInsight(
        cognitiveScore: state.cognitiveScore,
        streak: state.streak,
        domainAccuracy: domainMap,
        totalSessions: state.sessions.length,
      );

      if (result.isSuccess) {
        return CoachInsightResult(text: result.text!, generatedByAi: true);
      }
      return CoachInsightResult(
        text: local,
        generatedByAi: false,
        error: result.error,
      );
    } catch (_) {
      return CoachInsightResult(
        text: local,
        generatedByAi: false,
        error: 'AI tavsiyasini yuklab bo‘lmadi.',
      );
    }
  }
}

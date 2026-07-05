import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // firebase_ai o'rniga kirib keldi
import '../models/person.dart';
import '../models/session.dart';


class GeminiService {

  static const String _apiKey = "AIzaSyDI7yMdVJ9mUyTicwD5-m1TBoCIyDxOgbo";


  static final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: _apiKey,
    generationConfig: GenerationConfig(
      maxOutputTokens: 1500,
      temperature: 0.7,
    ),
  );

  static Future<String?> _ask(String prompt) async {
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      return (text == null || text.isEmpty) ? null : text;
    } catch (e, stack) {
      debugPrint('❌ Gemini API xatosi: $e');
      debugPrint('Stack: $stack');
      return null;
    }
  }


  static Future<String?> coachInsight({
    required int cognitiveScore,
    required int streak,
    required Map<String, double> domainAccuracy,
    required int totalSessions,
  }) async {
    final domainsText = domainAccuracy.entries
        .map((e) => '${e.key}: ${(e.value * 100).round()}%')
        .join(', ');
    final prompt =
        "Sen MindTrace AI ilovasidagi shaxsiy kognitiv trener (AI Coach)san. "
        "Foydalanuvchi statistikasi: umumiy kognitiv ball $cognitiveScore/100, "
        "$streak kunlik streak, $totalSessions ta sessiya, sohalar bo'yicha "
        "anixlik: $domainsText. Shu ma'lumotga asoslanib, o'zbek tilida, "
        "2-3 gapdan iborat, iliq va motivatsion, lekin ANIQ va "
        "shaxsiylashtirilgan tavsiya yoz. Tibbiy tashxis qo'yma, faqat "
        "mashq tavsiyasi ber.";
    return _ask(prompt);
  }


  static Future<String?> sessionSummary(List<ExerciseAttempt> attempts) async {
    final correct = attempts.where((a) => a.correct).length;
    final byDomain = <String, int>{};
    for (final a in attempts) {
      byDomain[a.domain.label] = (byDomain[a.domain.label] ?? 0) + (a.correct ? 1 : 0);
    }
    final prompt =
        "Foydalanuvchi hozirgina mashg'ulotni yakunladi: ${attempts.length} "
        "urinishdan $correct tasi to'g'ri. Sohalar bo'yicha to'g'ri javoblar: "
        "${byDomain.entries.map((e) => '${e.key}: ${e.value}').join(', ')}. "
        "O'zbek tilida, 1-2 gapli qisqa, quvvatlantiruvchi xulosa yoz — "
        "xuddi shaxsiy murabbiy his-tuyg'usini his qilsin.";
    return _ask(prompt);
  }


  static Future<String?> memoryTip(Person person) async {
    final prompt =
        "Foydalanuvchi \"${person.name}\" (${person.relation}) ismli "
        "insonni eslashda qiynalmoqda (xotira kuchi past). Qo'shimcha "
        "ma'lumot: \"${person.notes}\". O'zbek tilida, 1 ta amaliy, ijodiy "
        "mnemonika (assotsiatsiya) taklifini 1-2 gapda yoz — bu odamni "
        "eslab qolishga yordam beradigan bo'lsin.";
    return _ask(prompt);
  }


  static Future<String?> chatReply({
    required String userMessage,
    required String contextSummary,
    required List<Map<String, String>> history,
  }) async {
    final historyText = history
        .map((m) => '${m['role'] == 'user' ? 'Foydalanuvchi' : 'Murabbiy'}: ${m['text']}')
        .join('\n');
    final prompt =
        "Sen MindTrace AI ilovasidagi shaxsiy kognitiv murabbiysan (AI Coach). "
        "Foydalanuvchi konteksti: $contextSummary\n\n"
        "Suhbat tarixi:\n$historyText\n\n"
        "Foydalanuvchi: $userMessage\n\n"
        "O'zbek tilida, qisqa (3-4 gapgacha), do'stona va aniq javob ber. "
        "Tibbiy tashxis qo'yma — faqat kognitiv mashqlar va motivatsiya "
        "bo'yicha yordam ber.";
    return _ask(prompt);
  }
}
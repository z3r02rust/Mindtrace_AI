import 'dart:async';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/person.dart';
import '../models/session.dart';

class AiResult {
  final String? text;
  final String? error;

  const AiResult.success(this.text) : error = null;
  const AiResult.failure(this.error) : text = null;

  bool get isSuccess => text != null && text!.isNotEmpty;
}

class GeminiService {
  // Ixtiyoriy direct kalit build vaqtida berilishi mumkin. Odatiy yo‘l
  // Firebase AI Logic bo‘lib, Gemini kalitini APK ichiga joylamaydi.
  static const String _developerApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
  );

  static const String _configuredModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );
  static const String _fallbackModel = 'gemini-3.5-flash';
  static const Duration _requestTimeout = Duration(seconds: 30);

  static Future<AiResult> _ask(String prompt) async {
    final models = <String>[
      _configuredModel,
      if (_configuredModel != _fallbackModel) _fallbackModel,
    ];

    for (var index = 0; index < models.length; index++) {
      try {
        final text = _developerApiKey.isNotEmpty
            ? await _requestDirectModel(models[index], prompt)
            : await _requestFirebaseModel(models[index], prompt);
        return AiResult.success(text);
      } on _GeminiHttpException catch (error, stack) {
        debugPrint('Gemini API xatosi (${models[index]}): $error');
        debugPrintStack(stackTrace: stack);

        final canTryFallback =
            error.statusCode == 404 && index < models.length - 1;
        if (canTryFallback) continue;
        return AiResult.failure(_friendlyHttpError(error));
      } on FirebaseAIException catch (error, stack) {
        debugPrint('Firebase AI xatosi (${models[index]}): $error');
        debugPrintStack(stackTrace: stack);

        final canTryFallback =
            _isMissingModelError(error.message) && index < models.length - 1;
        if (canTryFallback) continue;
        return AiResult.failure(_friendlyFirebaseError(error));
      } on TimeoutException catch (error, stack) {
        debugPrint('Gemini timeout: $error');
        debugPrintStack(stackTrace: stack);
        return const AiResult.failure(
          'AI serveri vaqtida javob bermadi. Internetni tekshirib qayta urinib ko‘ring.',
        );
      } catch (error, stack) {
        debugPrint('Gemini kutilmagan xatosi: $error');
        debugPrintStack(stackTrace: stack);
        return const AiResult.failure(
          'AI xizmatiga ulanib bo‘lmadi. Internetni tekshirib qayta urinib ko‘ring.',
        );
      }
    }

    return const AiResult.failure('Mos Gemini modeli topilmadi.');
  }

  static Future<String> _requestFirebaseModel(
    String modelName,
    String prompt,
  ) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: modelName,
      generationConfig: GenerationConfig(
        maxOutputTokens: 1500,
        temperature: 0.7,
      ),
    );
    final response = await model
        .generateContent([Content.text(prompt)])
        .timeout(_requestTimeout);
    final text = response.text?.trim() ?? '';
    if (text.isEmpty) {
      throw FirebaseAIException('AI matnli javob qaytarmadi.');
    }
    return text;
  }

  static Future<String> _requestDirectModel(String model, String prompt) async {
    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$model:generateContent',
    );

    http.Response? response;
    for (var attempt = 0; attempt < 2; attempt++) {
      response = await http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'x-goog-api-key': _developerApiKey,
            },
            body: jsonEncode({
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
              'generationConfig': {'maxOutputTokens': 1500, 'temperature': 0.7},
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode < 500 || attempt == 1) break;
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }

    final body = _decodeObject(response!.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorObject = body['error'];
      final message = errorObject is Map
          ? errorObject['message']?.toString()
          : null;
      throw _GeminiHttpException(
        response.statusCode,
        message ?? 'Noma’lum server xatosi',
      );
    }

    final candidates = body['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      final feedback = body['promptFeedback'];
      final reason = feedback is Map
          ? feedback['blockReason']?.toString()
          : null;
      throw _GeminiHttpException(
        422,
        reason == null ? 'AI bo‘sh javob qaytardi' : 'Javob bloklandi: $reason',
      );
    }

    final first = candidates.first;
    final content = first is Map ? first['content'] : null;
    final parts = content is Map ? content['parts'] : null;
    final text = parts is List
        ? parts
              .whereType<Map>()
              .map((part) => part['text']?.toString() ?? '')
              .where((part) => part.trim().isNotEmpty)
              .join('\n')
              .trim()
        : '';

    if (text.isEmpty) {
      throw const _GeminiHttpException(422, 'AI matnli javob qaytarmadi');
    }
    return text;
  }

  static Map<String, dynamic> _decodeObject(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static String _friendlyHttpError(_GeminiHttpException error) {
    switch (error.statusCode) {
      case 400:
        return 'AI so‘rovni qabul qilmadi. Model yoki so‘rov sozlamasini tekshiring.';
      case 401:
      case 403:
        return 'Gemini API kaliti yaroqsiz, cheklangan yoki API yoqilmagan.';
      case 404:
        return 'Sozlangan Gemini modeli mavjud emas.';
      case 429:
        return 'Gemini API limiti tugagan. Birozdan keyin qayta urinib ko‘ring.';
      case 422:
        return 'AI javob yaratmadi: ${error.message}.';
      default:
        if (error.statusCode >= 500) {
          return 'Gemini serverida vaqtinchalik muammo bor. Keyinroq qayta urinib ko‘ring.';
        }
        return 'Gemini API xatosi (${error.statusCode}).';
    }
  }

  static bool _isMissingModelError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('404') ||
        normalized.contains('not found') ||
        normalized.contains('model is not supported');
  }

  static String _friendlyFirebaseError(FirebaseAIException error) {
    if (error is InvalidApiKey) {
      return 'Firebase API kaliti AI Logic uchun ruxsatlanmagan.';
    }
    if (error is ServiceApiNotEnabled) {
      return 'Firebase AI Logic hali yoqilmagan. Firebase Console → AI Logic → Get started orqali yoqing.';
    }
    if (error is QuotaExceeded) {
      return 'Gemini API limiti tugagan. Birozdan keyin qayta urinib ko‘ring.';
    }
    if (error is UnsupportedUserLocation) {
      return 'Gemini xizmati ushbu hududda ishlamaydi.';
    }
    if (_isMissingModelError(error.message)) {
      return 'Sozlangan Gemini modeli mavjud emas.';
    }
    return 'Firebase AI Logic xatosi: ${error.message}';
  }

  static Future<AiResult> coachInsight({
    required int cognitiveScore,
    required int streak,
    required Map<String, double> domainAccuracy,
    required int totalSessions,
  }) {
    final domainsText = domainAccuracy.entries
        .map((entry) => '${entry.key}: ${(entry.value * 100).round()}%')
        .join(', ');
    final prompt =
        'Sen MindTrace AI ilovasidagi shaxsiy kognitiv trener (AI Coach)san. '
        'Foydalanuvchi statistikasi: umumiy kognitiv ball $cognitiveScore/100, '
        '$streak kunlik streak, $totalSessions ta sessiya, sohalar bo‘yicha '
        'aniqlik: $domainsText. Shu ma’lumotga asoslanib, o‘zbek tilida, '
        '2-3 gapdan iborat, iliq va motivatsion, lekin aniq va '
        'shaxsiylashtirilgan tavsiya yoz. Tibbiy tashxis qo‘yma, faqat '
        'mashq tavsiyasi ber.';
    return _ask(prompt);
  }

  static Future<AiResult> sessionSummary(List<ExerciseAttempt> attempts) {
    final correct = attempts.where((attempt) => attempt.correct).length;
    final byDomain = <String, int>{};
    for (final attempt in attempts) {
      byDomain[attempt.domain.label] =
          (byDomain[attempt.domain.label] ?? 0) + (attempt.correct ? 1 : 0);
    }
    final prompt =
        'Foydalanuvchi hozirgina mashg‘ulotni yakunladi: ${attempts.length} '
        'urinishdan $correct tasi to‘g‘ri. Sohalar bo‘yicha to‘g‘ri javoblar: '
        '${byDomain.entries.map((entry) => '${entry.key}: ${entry.value}').join(', ')}. '
        'O‘zbek tilida, 1-2 gapli qisqa, quvvatlantiruvchi xulosa yoz.';
    return _ask(prompt);
  }

  static Future<AiResult> memoryTip(Person person) {
    final prompt =
        'Foydalanuvchi “${person.name}” (${person.relation}) ismli insonni '
        'eslashda qiynalmoqda. Qo‘shimcha ma’lumot: “${person.notes}”. '
        'O‘zbek tilida, 1 ta amaliy, ijodiy mnemonika taklifini 1-2 gapda yoz.';
    return _ask(prompt);
  }

  static Future<AiResult> chatReply({
    required String userMessage,
    required String contextSummary,
    required List<Map<String, String>> history,
  }) {
    final recentHistory = history.length <= 12
        ? history
        : history.sublist(history.length - 12);
    final historyText = recentHistory
        .map(
          (message) =>
              '${message['role'] == 'user' ? 'Foydalanuvchi' : 'Murabbiy'}: ${message['text']}',
        )
        .join('\n');
    final prompt =
        'Sen MindTrace AI ilovasidagi shaxsiy kognitiv murabbiysan. '
        'Foydalanuvchi konteksti: $contextSummary\n\n'
        'Suhbat tarixi:\n$historyText\n\n'
        'Foydalanuvchi: $userMessage\n\n'
        'O‘zbek tilida, qisqa (3-4 gapgacha), do‘stona va aniq javob ber. '
        'Tibbiy tashxis qo‘yma — faqat kognitiv mashqlar va motivatsiya '
        'bo‘yicha yordam ber.';
    return _ask(prompt);
  }
}

class _GeminiHttpException implements Exception {
  final int statusCode;
  final String message;

  const _GeminiHttpException(this.statusCode, this.message);

  @override
  String toString() => 'HTTP $statusCode: $message';
}

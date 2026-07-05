# MindTrace AI — Flutter versiyasi

Ilmiy asoslangan kognitiv trening ilovasi. Medical/yorqin dizayn, Provider bilan
markazlashgan state management, va real ma'lumotlarga asoslangan AI Coach.

## Ishga tushirish

```bash
flutter pub get
flutter run
```

(Flutter SDK o'rnatilgan bo'lishi kerak: https://docs.flutter.dev/get-started/install)

## Arxitektura

```
lib/
├── main.dart                    → kirish nuqtasi, Provider bog'lash, bottom nav
├── theme/app_theme.dart         → Medical Bright dizayn tizimi
├── state/app_state.dart         → markaziy holat (ChangeNotifier)
├── services/
│   ├── storage_service.dart     → SharedPreferences bilan ishlash
│   ├── spaced_repetition_service.dart → SM-2 algoritmi
│   └── ai_coach_service.dart    → qoidaga asoslangan + ixtiyoriy LLM tahlili
├── models/
│   ├── person.dart              → yaqin insonlar (spaced repetition holati bilan)
│   └── session.dart             → mashq natijalari, kognitiv sohalar
├── widgets/common_widgets.dart  → SectionCard, StatChip, ProgressBarRow
└── screens/                     → Home, Training, Analysis, Level, People, Profile
```

## Ilmiy asoslangan mashqlar

1. **Ism/yuz eslash** — SM-2 spaced-repetition jadvali bo'yicha (Anki/Duolingo'da
   ishlatiladigan algoritm). To'g'ri javob → oraliq kengayadi; xato → tez orada qayta so'raladi.
2. **1-Back mashqi** — dual n-back'ning soddalashtirilgan varianti, ishchi xotira uchun
   eng ko'p ilmiy tadqiq qilingan mashq turi.
3. **Raqamlar oralig'i (Digit Span)** — diqqat va qisqa muddatli xotira uchun klassik
   klinik test formati.

Barcha statistika (kognitiv ball, sohalar bo'yicha aniqlik, streak, XP) **haqiqiy
saqlangan natijalardan** hisoblanadi — tasodifiy yoki qattiq kodlangan raqamlar emas.

## AI qanday keng ko'lamda ishlatilgan

Ilova endi AI'ni bitta joyda emas, **4 xil funksional nuqtada** ishlatadi — barchasi
**Firebase AI Logic + Gemini** orqali, **bepul (no-cost) darajada**, backend server
qurmasdan:

1. **AI Coach tahlili** (Home, Analysis) — `GeminiService.coachInsight()`. Foydalanuvchining
   haqiqiy kognitiv ball, streak va sohalar bo'yicha aniqligiga qarab tabiiy tildagi,
   shaxsiylashtirilgan tavsiya generatsiya qiladi.
2. **Mashg'ulot xulosasi** (Training ekrani, sessiya oxirida) — `GeminiService.sessionSummary()`.
   Har bir mashg'ulot natijasiga qarab noyob, quvvatlantiruvchi xulosa yozadi.
3. **Mnemonika maslahati** (People ekrani) — `GeminiService.memoryTip()`. Xotira kuchi
   past bo'lgan har bir kishi uchun AI ijodiy assotsiatsiya (mnemonika) taklif qiladi.
4. **AI Chat** (alohida tab) — `GeminiService.chatReply()`. Foydalanuvchi erkin savol
   berishi mumkin, AI esa uning haqiqiy statistikasi konteksti bilan javob beradi.

Har bir joyda **fallback bor**: agar Gemini javob bermasa (internet yo'q, kvota tugagan
va h.k.), ilova jimgina mahalliy (rule-based) matnga tushadi — foydalanuvchi hech qachon
xato ko'rmaydi.

### Nega Gemini + Firebase AI Logic (Claude API o'rniga)

- **Karta/to'lov shart emas** — Gemini Developer API'ning bepul darajasi bor
- **Backend server yozish shart emas** — `firebase_ai` paketi to'g'ridan-to'g'ri
  Flutter'dan xavfsiz so'rov yuboradi (kalit Firebase proksi orqali yashiriladi)
- Ishlab chiqarishga chiqarishdan oldin **Firebase App Check** yoqish tavsiya etiladi —
  bu so'rovlar faqat sizning haqiqiy ilovangizdan kelayotganini tasdiqlaydi (bot/skript
  emas)

## AI Coach haqida (eski izoh, hozir ishlatilmaydi)

Avvalgi versiyada `AiCoachService.apiBaseUrl` orqali o'z backendingizga ulanish
mumkin edi. Bu mexanizm endi ishlatilmaydi — uning o'rniga to'g'ridan-to'g'ri
Gemini (Firebase AI Logic) ishlatiladi, chunki bu bepul va soddaroq.

## Keyingi qadamlar (tavsiya)

- Haqiqiy backend qo'shish (Firebase/Supabase) — hozircha barcha ma'lumot faqat
  qurilmada (`SharedPreferences`) saqlanadi.
- `flutter_local_notifications` bilan kunlik eslatma push-bildirishnomalari.
- Ko'proq mashq turlari: Stroop testi, task-switching.

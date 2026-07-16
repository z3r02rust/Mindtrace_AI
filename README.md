# MindTrace AI — Flutter versiyasi

Ilmiy asoslangan kognitiv trening ilovasi. Medical/yorqin dizayn, Provider bilan
markazlashgan state management, va real ma'lumotlarga asoslangan AI Coach.



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





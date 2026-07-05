import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../services/ai_coach_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.isLoading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        const Text('AI Tahlil', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Ilmiy asoslangan kognitiv baholash', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 20),


        SectionCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: state.cognitiveScore / 100,
                        strokeWidth: 12,
                        backgroundColor: AppColors.background,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${state.cognitiveScore}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        const Text('/ 100', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text('Kognitiv ko\'rsatkich', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('${state.sessions.length} ta sessiya asosida hisoblangan', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text('Sohalar bo\'yicha aniqlik', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            children: CognitiveDomain.values.map((d) {
              final acc = state.domainAccuracy(d);
              final count = state.sessions.expand((s) => s.attempts).where((a) => a.domain == d).length;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProgressBarRow(label: d.label, value: acc, color: memoryStrengthColor(acc)),
                    Text('$count urinish qayd etilgan', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        SectionCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Coach tavsiyasi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 6),
                    FutureBuilder<String>(
                      future: AiCoachService.deepInsight(state),
                      initialData: AiCoachService.localInsight(state),
                      builder: (context, snapshot) => Text(
                        snapshot.data ?? AiCoachService.localInsight(state),
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

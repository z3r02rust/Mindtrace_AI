import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class LevelScreen extends StatelessWidget {
  const LevelScreen({super.key});

  static const _weekdayLabels = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final counts = state.last7DaysSessionCounts;
    final now = DateTime.now();
    final dayLabels = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return _weekdayLabels[date.weekday - 1];
    });
    final maxCount =
        (counts.isEmpty ? 1 : counts.reduce((a, b) => a > b ? a : b)).clamp(
          1,
          999,
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        const Text(
          'Daraja',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),

        SectionCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${state.level}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${state.level}-daraja',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${state.totalXp} XP jami',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: state.levelProgress,
                  minHeight: 10,
                  backgroundColor: AppColors.background,
                  valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Keyingi darajagacha ${100 - (state.totalXp % 100)} XP',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'So\'nggi 7 kunlik faollik',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final h = counts[i] == 0
                    ? 6.0
                    : 24.0 + (counts[i] / maxCount) * 70.0;
                final isToday = i == 6;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${counts[i]}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isToday
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: h,
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppColors.primary
                              : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dayLabels[i],
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

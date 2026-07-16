import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../services/ai_coach_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'training_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final state = context.watch<AppState>();

    if (state.isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: state.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        children: [
          Text('Xayrli kun, ${state.profile['name'] ?? ''} 👋'.trim(), style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          const Text('MindTrace AI', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          Row(
            children: [
              StatChip(label: 'Kunlik streak', value: '${state.streak} kun', color: AppColors.warning, icon: Icons.local_fire_department_rounded),
              const SizedBox(width: 12),
              StatChip(label: 'Kognitiv ball', value: '${state.cognitiveScore}/100', color: AppColors.primary, icon: Icons.psychology_alt_rounded),
            ],
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 18),
          Container(
            height: 150,




            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF0891B2),
              boxShadow:[ BoxShadow(
                  offset: const Offset(0, 5),
                  color: Colors.black,


                  spreadRadius: -2,
                  blurRadius: 5
              )],
            ),

            child: TextButton(
              style: ElevatedButton.styleFrom(shape: CircleBorder(eccentricity: 0,)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrainingScreen())),
              child: const Text('Go',style: TextStyle(color: Colors.white,fontSize: 40,fontWeight: FontWeight.bold),),
            ),
          ),
          /*SectionCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                  child: const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 34),
                ),
                const SizedBox(height: 16),
                const Text('Bugungi mashqni boshlash', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text(
                  'Ismlarni eslash, ishchi xotira va diqqat mashqlari — ilmiy asoslangan spaced-repetition jadvali bo\'yicha',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),

              ],
            ),
          )*/
          const SizedBox(height: 20),
          _AiInsightCard(state: state),
          const SizedBox(height: 20),
          const Text('Kognitiv sohalar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              children: CognitiveDomain.values
                  .map((d) => ProgressBarRow(
                label: d.label,
                value: state.domainAccuracy(d),
                color: memoryStrengthColor(state.domainAccuracy(d)),
              ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}


class _AiInsightCard extends StatefulWidget {
  final AppState state;
  const _AiInsightCard({required this.state});

  @override
  State<_AiInsightCard> createState() => _AiInsightCardState();
}

class _AiInsightCardState extends State<_AiInsightCard> {
  late String _text;
  bool _fetchingDeep = false;

  @override
  void initState() {
    super.initState();
    _text = AiCoachService.localInsight(widget.state);
    _fetchDeep();
  }

  Future<void> _fetchDeep() async {
    setState(() => _fetchingDeep = true);
    final deep = await AiCoachService.deepInsight(widget.state);
    if (mounted) setState(() { _text = deep as String; _fetchingDeep = false; });
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('AI Coach', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    if (_fetchingDeep) ...[
                      const SizedBox(width: 8),
                      const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                    ]
                  ],
                ),
                const SizedBox(height: 6),
                Text(_text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


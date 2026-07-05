import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../services/gemini_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.isLoading) return const Center(child: CircularProgressIndicator());

    final sorted = [...state.people]..sort((a, b) => a.memoryStrength.compareTo(b.memoryStrength));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPersonForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Qo\'shish'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          const Text('Yaqin insonlar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Xotira mashqlarida ishlatiladigan shaxslar', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          if (sorted.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('Hali hech kim qo\'shilmagan', style: TextStyle(color: AppColors.textSecondary))),
            ),
          ...sorted.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SectionCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(p.name.isNotEmpty ? p.name[0] : '?', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 18)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            Text(p.relation, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 8),
                            ProgressBarRow(label: 'Xotira kuchi', value: p.memoryStrength, color: memoryStrengthColor(p.memoryStrength)),
                            if (p.memoryStrength < 0.5) ...[
                              const SizedBox(height: 6),
                              TextButton.icon(
                                onPressed: () => _showAiTip(context, p),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32), alignment: Alignment.centerLeft),
                                icon: const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.secondary),
                                label: const Text('AI mnemonika maslahati', style: TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                        onSelected: (v) {
                          if (v == 'edit') _showPersonForm(context, person: p);
                          if (v == 'delete') context.read<AppState>().deletePerson(p.id);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Tahrirlash')),
                          PopupMenuItem(value: 'delete', child: Text('O\'chirish')),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  void _showAiTip(BuildContext context, Person person) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.auto_awesome_rounded, color: AppColors.secondary, size: 20),
            SizedBox(width: 8),
            Text('AI mnemonika maslahati', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: FutureBuilder<String?>(
          future: GeminiService.memoryTip(person),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()));
            }
            final tip = snapshot.data ??
                "${person.name}ni eslash uchun ularni \"${person.relation}\" roli va "
                    "\"${person.notes}\" bilan bog'liq yorqin bir tasvir sifatida ko'z oldingizga keltiring.";
            return Text(tip, style: const TextStyle(fontSize: 14, height: 1.4));
          },
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Yopish'))],
      ),
    );
  }

  void _showPersonForm(BuildContext context, {Person? person}) {
    final nameCtrl = TextEditingController(text: person?.name);
    final relationCtrl = TextEditingController(text: person?.relation);
    final notesCtrl = TextEditingController(text: person?.notes);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(person == null ? 'Yangi kishi qo\'shish' : 'Tahrirlash', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Ismi')),
            const SizedBox(height: 12),
            TextField(controller: relationCtrl, decoration: const InputDecoration(labelText: 'Qarindoshlik/aloqa (Ona, Do\'st...)')),
            const SizedBox(height: 12),
            TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Qo\'shimcha izoh (manzil, sana...)'), maxLines: 2),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final appState = context.read<AppState>();
                if (person == null) {
                  appState.addPerson(Person(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameCtrl.text.trim(),
                    relation: relationCtrl.text.trim(),
                    notes: notesCtrl.text.trim(),
                  ));
                } else {
                  appState.updatePerson(Person(
                    id: person.id,
                    name: nameCtrl.text.trim(),
                    relation: relationCtrl.text.trim(),
                    notes: notesCtrl.text.trim(),
                    easeFactor: person.easeFactor,
                    intervalDays: person.intervalDays,
                    repetitions: person.repetitions,
                    nextReview: person.nextReview,
                    lastReviewed: person.lastReviewed,
                  ));
                }
                Navigator.pop(ctx);
              },
              child: const Text('Saqlash'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  late TextEditingController _name, _age, _notes;
  String _health = 'Sog\'lom';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.isLoading) return const Center(child: CircularProgressIndicator());

    if (!_editing) {
      _name = TextEditingController(text: state.profile['name']);
      _age = TextEditingController(text: state.profile['age']);
      _notes = TextEditingController(text: state.profile['notes']);
      _health = state.profile['health'] ?? 'Sog\'lom';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Profil', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            IconButton(
              icon: Icon(_editing ? Icons.close_rounded : Icons.edit_rounded, color: AppColors.primary),
              onPressed: () => setState(() => _editing = !_editing),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const CircleAvatar(radius: 40, backgroundColor: AppColors.primaryLight, child: Icon(Icons.person_rounded, size: 40, color: AppColors.primary)),
              const SizedBox(height: 16),
              if (_editing) ...[
                TextField(controller: _name, decoration: const InputDecoration(labelText: 'Ism')),
                const SizedBox(height: 12),
                TextField(controller: _age, decoration: const InputDecoration(labelText: 'Yosh'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _health,
                  decoration: const InputDecoration(labelText: 'Sog\'liq holati'),
                  items: ['Sog\'lom', 'Nazorat ostida', 'Shifokor tavsiyasida']
                      .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                      .toList(),
                  onChanged: (v) => setState(() => _health = v ?? _health),
                ),
                const SizedBox(height: 12),
                TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Tibbiy izohlar'), maxLines: 3),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await context.read<AppState>().updateProfile({
                        'name': _name.text.trim(),
                        'age': _age.text.trim(),
                        'health': _health,
                        'notes': _notes.text.trim(),
                      });
                      setState(() => _editing = false);
                    },
                    child: const Text('Saqlash'),
                  ),
                ),
              ] else ...[
                Text(state.profile['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Text('${state.profile['age'] ?? '—'} yosh', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                _InfoRow(icon: Icons.favorite_rounded, label: 'Sog\'liq holati', value: state.profile['health'] ?? '—'),
                const Divider(height: 24, color: AppColors.border),
                _InfoRow(icon: Icons.notes_rounded, label: 'Tibbiy izoh', value: state.profile['notes'] ?? 'Yo\'q'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Trening statistikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(
          children: [
            StatChip(label: 'Jami sessiya', value: '${state.sessions.length}', color: AppColors.primary, icon: Icons.psychology_alt_rounded),
            const SizedBox(width: 12),
            StatChip(label: 'Eng yaxshi streak', value: '${state.streak} kun', color: AppColors.warning, icon: Icons.local_fire_department_rounded),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

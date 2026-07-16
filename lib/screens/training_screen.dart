import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../models/session.dart';
import '../services/gemini_service.dart';
import '../services/spaced_repetition_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

enum _Phase { loading, nameRecall, nBack, digitSpan, summary }

class _TrainingScreenState extends State<TrainingScreen> {
  _Phase _phase = _Phase.loading;
  final List<ExerciseAttempt> _attempts = [];

  List<Person> _allPeople = [];
  List<Person> _duePeople = [];
  int _nameIndex = 0;
  List<String>? _nameOptions;
  Person? _selectedTarget;
  final Stopwatch _nameStopwatch = Stopwatch();
  bool _answeringName = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final people = List<Person>.from(context.read<AppState>().people);
    final due = SpacedRepetitionService.dueToday(people).take(3).toList();
    setState(() {
      _allPeople = people;
      _duePeople = due;
      _phase = due.isEmpty ? _Phase.nBack : _Phase.nameRecall;
      if (due.isNotEmpty) _prepareNameQuestion();
    });
  }

  void _prepareNameQuestion() {
    _selectedTarget = _duePeople[_nameIndex];
    final distractors =
        _allPeople
            .where(
              (person) =>
                  person.id != _selectedTarget!.id &&
                  person.name != _selectedTarget!.name,
            )
            .map((person) => person.name)
            .toSet()
            .toList()
          ..shuffle();
    final options = <String>[
      _selectedTarget!.name,
      ...distractors.take(min(2, distractors.length)),
    ]..shuffle();
    _nameOptions = options;
    _nameStopwatch
      ..reset()
      ..start();
  }

  Future<void> _answerName(String chosen) async {
    if (_answeringName) return;
    setState(() => _answeringName = true);
    _nameStopwatch.stop();
    final correct = chosen == _selectedTarget!.name;
    _attempts.add(
      ExerciseAttempt(
        domain: CognitiveDomain.episodicMemory,
        correct: correct,
        reactionMs: _nameStopwatch.elapsedMilliseconds,
      ),
    );

    final updated = SpacedRepetitionService.review(
      _selectedTarget!,
      correct: correct,
    );
    final idx = _allPeople.indexWhere((p) => p.id == updated.id);
    if (idx != -1) _allPeople[idx] = updated;

    await _showFeedback(correct);

    if (!mounted) return;
    setState(() {
      _nameIndex++;
      _answeringName = false;
      if (_nameIndex < _duePeople.length) {
        _prepareNameQuestion();
      } else {
        _phase = _Phase.nBack;
      }
    });
  }

  Future<void> _showFeedback(bool correct) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(correct ? "To'g'ri! ✅" : "Noto'g'ri ❌"),
        backgroundColor: correct ? AppColors.secondary : AppColors.danger,
        duration: const Duration(milliseconds: 700),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _onNBackDone(List<ExerciseAttempt> attempts) {
    _attempts.addAll(attempts);
    setState(() => _phase = _Phase.digitSpan);
  }

  Future<void> _onDigitSpanDone(bool correct, int reactionMs) async {
    _attempts.add(
      ExerciseAttempt(
        domain: CognitiveDomain.attention,
        correct: correct,
        reactionMs: reactionMs,
      ),
    );
    await _finishSession();
  }

  String? _aiSummary;
  String? _aiSummaryError;
  bool _loadingAiSummary = false;

  Future<void> _finishSession() async {
    await context.read<AppState>().submitTrainingSession(_attempts, _allPeople);
    if (!mounted) return;
    setState(() => _phase = _Phase.summary);

    setState(() => _loadingAiSummary = true);
    final result = await GeminiService.sessionSummary(_attempts);
    if (mounted) {
      setState(() {
        _aiSummary = result.text;
        _aiSummaryError = result.error;
        _loadingAiSummary = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mashg\'ulot'),
        leading: _phase == _Phase.summary
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: SafeArea(
        child: Padding(padding: const EdgeInsets.all(20), child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _Phase.loading:
        return const Center(child: CircularProgressIndicator());
      case _Phase.nameRecall:
        return SingleChildScrollView(child: _buildNameRecall());
      case _Phase.nBack:
        return SingleChildScrollView(child: _NBackGame(onDone: _onNBackDone));
      case _Phase.digitSpan:
        return SingleChildScrollView(
          child: _DigitSpanGame(onDone: _onDigitSpanDone),
        );
      case _Phase.summary:
        return _buildSummary();
    }
  }

  Widget _buildNameRecall() {
    final total = _duePeople.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: (_nameIndex) / total,
          minHeight: 6,
          borderRadius: BorderRadius.circular(6),
        ),
        const SizedBox(height: 8),
        Text(
          'Bosqich 1/3 · Ism eslash  (${_nameIndex + 1}/$total)',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 28),
        SectionCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  _selectedTarget!.relation.trim().isEmpty
                      ? _selectedTarget!.name[0]
                      : _selectedTarget!.relation.trim()[0],
                  style: const TextStyle(
                    fontSize: 28,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _selectedTarget!.relation,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _selectedTarget!.notes,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bu kishining ismi nima edi?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ...(_nameOptions ?? []).map(
          (opt) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.border),
              ),
              onPressed: _answeringName ? null : () => _answerName(opt),
              child: Text(
                opt,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final correct = _attempts.where((a) => a.correct).length;
    final total = _attempts.length;
    final xp = correct * 10 + total * 2;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.secondary,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Mashg\'ulot yakunlandi!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '$correct/$total to\'g\'ri javob',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              '+$xp XP',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            SectionCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _loadingAiSummary
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _aiSummary ??
                                    "Yaxshi ish qildingiz! Muntazam mashq eng yaxshi natija beradi.",
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              if (_aiSummaryError != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Mahalliy xulosa ko‘rsatildi: $_aiSummaryError',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text('Bosh sahifaga qaytish'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NBackGame extends StatefulWidget {
  final void Function(List<ExerciseAttempt>) onDone;
  const _NBackGame({required this.onDone});

  @override
  State<_NBackGame> createState() => _NBackGameState();
}

class _NBackGameState extends State<_NBackGame> {
  static const int _trialCount = 8;
  final List<int> _sequence = [];
  int _trial = 0;
  int? _current;
  bool _showingStimulus = true;
  bool _answered = false;
  Stopwatch _sw = Stopwatch();
  final List<ExerciseAttempt> _attempts = [];
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _generateSequence();
    _runTrial();
  }

  void _generateSequence() {
    _sequence.add(_rand.nextInt(9));
    for (int i = 1; i < _trialCount; i++) {
      if (_rand.nextDouble() < 0.35) {
        _sequence.add(_sequence[i - 1]); // ataylab moslik yaratish
      } else {
        int v;
        do {
          v = _rand.nextInt(9);
        } while (v == _sequence[i - 1]);
        _sequence.add(v);
      }
    }
  }

  void _runTrial() async {
    if (_trial >= _trialCount) {
      widget.onDone(_attempts);
      return;
    }
    setState(() {
      _current = _sequence[_trial];
      _showingStimulus = true;
      _answered = false;
    });
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _showingStimulus = false);

    if (_trial > 0) {
      _sw = Stopwatch()..start();
    }

    if (_trial == 0) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      _trial++;
      _runTrial();
    }
  }

  void _respond(bool userSaysMatch) {
    if (_answered || _trial == 0) return;
    setState(() => _answered = true);
    _sw.stop();
    final actualMatch = _sequence[_trial] == _sequence[_trial - 1];
    final correct = actualMatch == userSaysMatch;
    _attempts.add(
      ExerciseAttempt(
        domain: CognitiveDomain.workingMemory,
        correct: correct,
        reactionMs: _sw.elapsedMilliseconds,
      ),
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _trial++;
      _runTrial();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: _trial / _trialCount,
          minHeight: 6,
          borderRadius: BorderRadius.circular(6),
        ),
        const SizedBox(height: 8),
        const Text(
          'Bosqich 2/3 · Ishchi xotira (1-Back)',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        const Text(
          'Har bir katakcha oldingisi bilan bir xil joyda yonganini eslab qoling.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 9,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, i) {
              final active = _showingStimulus && _current == i;
              return Container(
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 0),
        if (_trial > 0 && !_showingStimulus) ...[
          const Text(
            'Bu joylashuv oldingisi bilan bir xilmi?',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 0),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _answered ? null : () => _respond(false),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Boshqa'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _answered ? null : () => _respond(true),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Bir xil'),
                  ),
                ),
              ),
            ],
          ),
        ] else
          const SizedBox(height: 60),
      ],
    );
  }
}

class _DigitSpanGame extends StatefulWidget {
  final void Function(bool correct, int reactionMs) onDone;
  const _DigitSpanGame({required this.onDone});

  @override
  State<_DigitSpanGame> createState() => _DigitSpanGameState();
}

class _DigitSpanGameState extends State<_DigitSpanGame> {
  late final List<int> _digits;
  bool _showing = true;
  final List<int> _input = [];
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    final rand = Random();
    _digits = List.generate(5, (_) => rand.nextInt(10));
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showing = false);
        _stopwatch.start();
      }
    });
  }

  void _tap(int d) {
    if (_input.length >= _digits.length) return;
    setState(() => _input.add(d));
    if (_input.length == _digits.length) {
      _stopwatch.stop();
      final correct = List.generate(
        _digits.length,
        (i) => _input[i] == _digits[i],
      ).every((e) => e);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) widget.onDone(correct, _stopwatch.elapsedMilliseconds);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LinearProgressIndicator(
          value: 2 / 3,
          minHeight: 6,
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Bosqich 3/3 · Raqamlar oralig\'i (Diqqat)',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 32),
        if (_showing) ...[
          const Text(
            'Bu ketma-ketlikni eslab qoling:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Text(
            _digits.join('  '),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 4,
            ),
          ),
        ] else ...[
          const Text(
            'Endi shu ketma-ketlikni kiriting:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            children: List.generate(
              _digits.length,
              (i) => Container(
                width: 40,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.background,
                ),
                child: Text(
                  i < _input.length ? '${_input[i]}' : '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 10,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, i) => OutlinedButton(
              onPressed: () => _tap(i),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Text(
                '$i',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

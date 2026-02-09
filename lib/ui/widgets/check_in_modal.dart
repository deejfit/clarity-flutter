import 'package:flutter/material.dart';

/// Optional follow-up data (analytics only).
typedef OnSaveExtra = void Function(int? difficulty, String? note);

class CheckInModal extends StatefulWidget {
  const CheckInModal({
    super.key,
    required this.onYes,
    required this.onNotToday,
    this.onSaveExtra,
  });

  final VoidCallback onYes;
  final VoidCallback onNotToday;
  final OnSaveExtra? onSaveExtra;

  @override
  State<CheckInModal> createState() => _CheckInModalState();
}

class _CheckInModalState extends State<CheckInModal> {
  static const int _minDifficulty = 1;
  static const int _maxDifficulty = 5;
  static const int _maxNoteLength = 20;

  bool _answered = false;
  bool _sober = false;
  double _difficultyValue = 3.0; // 1-5
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String? _singleWordNote(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    final word = t.split(RegExp(r'\s+')).first;
    if (word.isEmpty) return null;
    return word.length > _maxNoteLength ? word.substring(0, _maxNoteLength) : word;
  }

  void _applyExtra() {
    if (widget.onSaveExtra == null) return;
    final d = _difficultyValue.round().clamp(_minDifficulty, _maxDifficulty);
    widget.onSaveExtra!(d, _singleWordNote(_noteController.text));
  }

  void _onAnswer(bool sober) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _sober = sober;
    });
    if (sober) {
      widget.onYes();
    } else {
      widget.onNotToday();
    }
  }

  void _onDifficultyChange(double value) {
    setState(() => _difficultyValue = value);
    final d = value.round().clamp(_minDifficulty, _maxDifficulty);
    widget.onSaveExtra?.call(d, _singleWordNote(_noteController.text));
  }

  void _onNoteChange(String value) {
    widget.onSaveExtra?.call(
      _difficultyValue.round().clamp(_minDifficulty, _maxDifficulty),
      _singleWordNote(value),
    );
  }

  void _done() {
    _applyExtra();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_answered) ...[
              Text(
                'Did you stay sober today?',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _onAnswer(false),
                      child: const Text('Not today'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _onAnswer(true),
                      child: const Text('Yes'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Did you stay sober today?',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _sober ? 'Yes' : 'Not today',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (widget.onSaveExtra != null) ...[
                Text(
                  'How hard was today?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    Text('Easy', style: Theme.of(context).textTheme.bodySmall),
                    Expanded(
                      child: Slider(
                        value: _difficultyValue,
                        min: _minDifficulty.toDouble(),
                        max: _maxDifficulty.toDouble(),
                        divisions: _maxDifficulty - _minDifficulty,
                        onChanged: _onDifficultyChange,
                      ),
                    ),
                    Text('Hard', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'One word for today',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _noteController,
                  maxLength: _maxNoteLength,
                  decoration: const InputDecoration(
                    hintText: 'Optional',
                    counterText: '',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _onNoteChange,
                ),
                const SizedBox(height: 16),
              ],
              FilledButton(
                onPressed: _done,
                child: const Text('Done'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

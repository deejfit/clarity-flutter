import 'package:flutter/material.dart';

class CheckInModal extends StatelessWidget {
  const CheckInModal({
    super.key,
    required this.onYes,
    required this.onNotToday,
  });

  final VoidCallback onYes;
  final VoidCallback onNotToday;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                    onPressed: () {
                      onNotToday();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Not today'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      onYes();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Yes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

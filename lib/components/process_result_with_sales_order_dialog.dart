import 'package:flutter/material.dart';

class ProcessResultWidget extends StatelessWidget {
  const ProcessResultWidget({
    super.key,
    required this.qtyPassed,
    required this.qtyRejected,
    required this.problems,
    required this.remarks,
  });

  final String qtyPassed;
  final String qtyRejected;
  final List<Map<String, dynamic>> problems;
  final String remarks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 380,
        maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      ),
      child: SizedBox(
        width: 380,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Process Result',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Qty Passed: $qtyPassed unit(s)'),
                      Text('Qty Rejected: $qtyRejected unit(s)'),
                      const Divider(height: 22),
                      Text('Problem:', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 3),
                      ...problems.map((problem) {
                        final code = problem['code']?.toString() ?? '';
                        final name = problem['name']?.toString() ?? '';
                        return Text(
                          '${code.isEmpty ? '' : '$code - '}${name.isEmpty ? 'Problem' : name}',
                        );
                      }),
                      const Divider(height: 22),
                      Text('Remarks:', style: theme.textTheme.titleMedium),
                      Text(remarks.trim().isEmpty ? 'No remarks.' : remarks),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        child: const Text('Confirm'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

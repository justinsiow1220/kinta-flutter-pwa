import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/kinta_process_draft.dart';

/// Confirmation popup for the non-scan process, which ends with a description
/// rather than passed/rejected quantities.
class ProcessResultWithoutSalesOrderConfirmationDialog extends StatelessWidget {
  const ProcessResultWithoutSalesOrderConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final draft = KintaProcessDraft.instance;
    final timestamp = DateFormat('yyyy-MM-dd | hh:mma').format(DateTime.now());
    final description = draft.activityDescription?.trim();

    return SizedBox(
      width: 340,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Process Result',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                timestamp,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              draft.sectorLabel ?? 'Sector not selected',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              draft.activityLabel ?? 'Activity not selected',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              description == null || description.isEmpty
                  ? 'No description entered.'
                  : description,
              softWrap: true,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
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
                    height: 44,
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
    );
  }
}

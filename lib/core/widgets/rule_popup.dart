/// Rule-violation popup (v4.3) — the formal rule messages of the chain
/// rules (R-01..R-04) and the program rules (P-01..P-05) open as a dialog
/// with a single «متوجه شدم» button instead of the fast-disappearing top
/// toast, so the user has enough time to read them
/// («پیغام‌های قوائد به‌صورت پاپ‌آپ با دکمه متوجه شدم نمایش داده شوند»).
library;

import 'package:flutter/material.dart';

import '../state/app_providers.dart';
import '../theme/app_theme.dart';

/// Shows one dialog with [title] and the listed [messages]; the single
/// action closes it («متوجه شدم»). Long lists scroll inside the dialog.
Future<void> showRuleViolationPopup(
  BuildContext context, {
  required String title,
  required List<String> messages,
}) {
  final l = L(context);
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.rule_outlined, color: AppTheme.orangeDeep, size: 22),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15))),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: messages.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Text(
                messages.isEmpty ? '' : l.rulePopupIntro,
                style: TextStyle(
                    fontSize: 11.5, height: 1.9, color: Theme.of(context).hintColor),
              );
            }
            final index = i - 1;
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppTheme.orangeDeep.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.orangeDeep.withValues(alpha: 0.35)),
                ),
                child: Text(
                  messages[index],
                  style: const TextStyle(fontSize: 12, height: 1.9),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l.ruleOk),
        ),
      ],
    ),
  );
}

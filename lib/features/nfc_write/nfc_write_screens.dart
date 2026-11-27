import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/nfc/nfc_service.dart';
import '../../core/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/utils/jalali.dart';
import '../../core/widgets/nfc_hex_button.dart';
import '../../state/providers.dart';
import '../../state/write_flow_provider.dart';
import '../../core/widgets/app_toasts.dart';

/// Write confirmation — reviews the payload in user-friendly terms (no
/// register/block details) before starting the protocol, and exposes the
/// design-review simulation scenarios (RC paths).
class WriteConfirmScreen extends ConsumerStatefulWidget {
  const WriteConfirmScreen({required this.mode, super.key});

  final WriteMode mode;

  @override
  ConsumerState<WriteConfirmScreen> createState() => _WriteConfirmScreenState();
}

class _WriteConfirmScreenState extends ConsumerState<WriteConfirmScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(writeFlowProvider).begin(widget.mode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L(context);
    final fa = isFa(context);
    final programs = ref.watch(programsProvider);
    final status = ref.watch(deviceStatusProvider).status;
    final newVersion = (status?.runVersion ?? 0) + 1;

    // Q-05: only ENABLED programs are transferred — disabled programs stay
    // on the phone and are not written to the relay memory.
    final enabledPrograms = programs.enabledPrograms;
    final enabledEvents = programs.enabledEventUsage;
    final enabledTimers = programs.enabledTimerUsage;
    final disabledCount = programs.disabledCount;

    // Persian (Jalali) date + clock shown on the time-sync row — the same
    // moment the device clock will be set to.
    final now = DateTime.now();
    final j = gregorianToJalali(now);
    final monthName = switch (j.month) {
      1 => l.m0, 2 => l.m1, 3 => l.m2, 4 => l.m3, 5 => l.m4, 6 => l.m5,
      7 => l.m6, 8 => l.m7, 9 => l.m8, 10 => l.m9, 11 => l.m10, _ => l.m11,
    };
    final dateChip =
        '${faNumInt(fa, j.day)} $monthName ${faNumInt(fa, j.year)} — ${num2(fa, now.hour)}:${num2(fa, now.minute)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == WriteMode.settingsOnly ? l.wcTitleSet : l.wcTitleProg),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.wcSub, style: TextStyle(fontSize: 11.5, height: 1.9, color: Theme.of(context).hintColor)),
          const SizedBox(height: 12),
          _row(context, Icons.schedule, l.wcTime, l.wcTimeD, dateChip),
          _row(context, Icons.wb_twilight_outlined, l.wcAstro, l.wcAstroD, l.wcAstroSide),
          if (widget.mode == WriteMode.programAndSettings)
            _row(
              context,
              Icons.calendar_today_outlined,
              l.wcPrograms,
              l.wcProgramsD(
                  faNumInt(fa, enabledPrograms.length),
                  faNumInt(fa, enabledEvents),
                  faNumInt(fa, enabledTimers)),
              l.countPrograms(faNumInt(fa, enabledPrograms.length)),
            )
          else
            _row(context, Icons.memory, l.wcTitleSet, l.wcSetD2, l.wcSetSide),
          if (widget.mode == WriteMode.programAndSettings && disabledCount > 0)
            _row(
              context,
              Icons.power_off_outlined,
              l.wcOffNote(faNumInt(fa, disabledCount)),
              l.programWriteD,
              faNumInt(fa, disabledCount),
            ),
          _row(context, Icons.sync_outlined, l.wcVersion, l.wcVersionD(faNumInt(fa, newVersion)),
              faNumInt(fa, newVersion)),
          _row(context, Icons.list_alt, l.wcCapacity,
              l.wcCapacityD(faNumInt(fa, programs.enabledEventUsage),
                  faNumInt(fa, programs.enabledTimerUsage)),
              null),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _openProgress(context, ref, l),
            icon: const Icon(Icons.bolt),
            label: Text(l.wcStart),
          ),
          TextButton(
            onPressed: () => context.pop(),
            child: Text(l.wcBack),
          ),
        ],
      ),
    );
  }

  Future<void> _openProgress(
      BuildContext context, WidgetRef ref, AppLocalizationsX l) async {
    if (widget.mode == WriteMode.programAndSettings) {
      final programs = ref.read(programsProvider);
      if (programs.programs.isEmpty) {
        showAppMessage(context, l.noProgramsToast);
        return;
      }
      // Q-05: an all-disabled list has nothing to transfer.
      if (programs.enabledPrograms.isEmpty) {
        showAppMessage(context, l.allDisabledToast);
        return;
      }
    }
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      pageBuilder: (context, _, __) => const WriteProgressDialog(),
    );
    ref.read(writeFlowProvider).resetForConfirm();
  }

  Widget _row(BuildContext context, IconData icon, String title, String desc, String? side) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.orangeDeep),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  Text(desc,
                      style: TextStyle(
                          fontSize: 10.5, height: 1.7, color: Theme.of(context).hintColor)),
                ],
              ),
            ),
            if (side != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(side,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen progress overlay running the 8-step protocol simulation —
/// hexagonal NFC badge with pulse, live percentage, user-friendly step
/// names, and the failure paths (retry / power-off guidance / back to app).
class WriteProgressDialog extends ConsumerStatefulWidget {
  const WriteProgressDialog({super.key});

  @override
  ConsumerState<WriteProgressDialog> createState() => _WriteProgressDialogState();
}

class _WriteProgressDialogState extends ConsumerState<WriteProgressDialog> {
  bool _rcAutoShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(writeFlowProvider).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L(context);
    final fa = isFa(context);
    final flow = ref.watch(writeFlowProvider);
    final attempt = flow.attempt == 0 ? 1 : flow.attempt;
    // The dialog reads the write mode from the flow controller (the dialog
    // itself is mode-less).
    final widgetMode = flow.mode ?? WriteMode.settingsOnly;

    final stepNames = [
      l.step1, l.step2, l.step3, l.step4, l.step5, l.step6, l.step7, l.step8,
    ];

    final doneCount = flow.stepStatus.where((s) => s == StepStatus.done).length;
    final percent = (doneCount / 8 * 100).round();
    final unpoweredContinue = flow.skipClock; // «ادامه ارسال» accepted

    // Step 4 description changes when clock/date are skipped.
    final stepDescs = [
      l.step1d, l.step2d, l.step3d,
      unpoweredContinue ? l.step4dNoClock : l.step4d,
      l.step5d, l.step6d, l.step7d, l.step8d,
    ];

    // RC-10: two consecutive failed attempts → power-off guidance opens once.
    if (flow.failure != null && attempt >= 2 && !_rcAutoShown) {
      _rcAutoShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showPowerOff(context, l);
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: const Color(0xF20A0D10),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const SizedBox(height: 14),
                if (flow.running || flow.polling) ...[
                  const NfcHexBadge(size: 56, pulse: true),
                  const SizedBox(height: 6),
                  Text('٪${faNumInt(fa, percent)}',
                      style: const TextStyle(
                          color: AppTheme.orange, fontSize: 15, fontWeight: FontWeight.w700)),
                ] else
                  Icon(
                    flow.completed ? Icons.check_circle_outline : Icons.error_outline,
                    color: flow.completed ? const Color(0xFF35C584) : const Color(0xFFE4695C),
                    size: 76,
                  ),
                const SizedBox(height: 12),
                Text(
                  flow.powerOffDetected
                      ? (widgetMode == WriteMode.settingsOnly ? l.wpPwSetT : l.wpPwProgT)
                      : flow.completed
                          ? l.wpDoneTitle
                          : flow.failure != null
                              ? l.wpFailTitle
                              : l.wpTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  flow.powerOffDetected
                      ? (widgetMode == WriteMode.settingsOnly ? l.wpPwSetM : l.wpPwProgM)
                      : flow.completed
                          ? (unpoweredContinue
                              ? l.wpDoneSubNoClock(faNumInt(fa, flow.newVersion ?? 0))
                              : l.wpDoneSub(faNumInt(fa, flow.newVersion ?? 0)))
                          : flow.polling
                              ? l.wpPolling
                              : flow.failure != null
                                  ? _failureText(l, flow, stepNames)
                                  : l.keepSteady,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11.5, height: 1.8),
                  textAlign: TextAlign.center,
                ),
                if (unpoweredContinue && !flow.completed) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC0392B).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFC0392B).withValues(alpha: 0.5)),
                    ),
                    child: Text(l.wpPwSkipped,
                        style: const TextStyle(color: Color(0xFFE4695C), fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  l.attemptOf(faNumInt(fa, attempt)),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10.5),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView(
                    children: [
                      for (var i = 0; i < 8; i++)
                        _stepTile(
                          context,
                          index: i,
                          name: stepNames[i],
                          desc: stepDescs[i],
                          status: flow.stepStatus[i],
                        ),
                    ],
                  ),
                ),
                if (flow.powerOffDetected) ...[
                  // v2.7 relay-unpowered decision — formal wording.
                  if (widgetMode == WriteMode.settingsOnly) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          ref.read(writeFlowProvider).ackSettingsBlocked();
                          Navigator.of(context).pop();
                          showAppMessage(this.context, l.wpPwSetToast);
                        },
                        child: Text(l.wpPwAck),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: FilledButton.icon(
                            onPressed: () => ref.read(writeFlowProvider).continueWithoutClock(),
                            icon: const Icon(Icons.bolt, size: 18),
                            label: Text(l.wpPwContinue),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                            ),
                            onPressed: () {
                              ref.read(writeFlowProvider).cancel();
                              Navigator.of(context).pop();
                              showAppMessage(this.context, l.wpPwCancelled);
                            },
                            child: Text(l.wpPwCancel),
                          ),
                        ),
                      ],
                    ),
                  ],
                ] else if (flow.completed) ...[
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l.wpClose),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.push('/device');
                          },
                          child: Text(l.wpDoneGo),
                        ),
                      ),
                    ],
                  ),
                ] else if (flow.failure != null) ...[
                  Text(l.wpRetryHint,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 10.5)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: FilledButton.icon(
                          onPressed: () => ref.read(writeFlowProvider).start(),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: Text(l.wpRetryFromStep1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          ),
                          onPressed: () => _showPowerOff(context, l),
                          icon: const Icon(Icons.power_off_outlined, size: 17),
                          label: Text(l.wpPowerOff, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () {
                      // Approved escape path: back to the app environment.
                      showAppMessage(this.context, l.wpBackToast);
                      Navigator.of(context).pop();
                    },
                    child: Text(l.wpBackApp, style: TextStyle(color: Colors.grey.shade400)),
                  ),
                ] else ...[
                  TextButton(
                    onPressed: () {
                      ref.read(writeFlowProvider).cancel();
                      // Real transport: stop an in-flight protocol session too.
                      ref.read(nfcServiceProvider).cancelActiveOperation();
                      Navigator.of(context).pop();
                    },
                    child: Text(l.wpCancel, style: TextStyle(color: Colors.grey.shade400)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// v4.3 — bespoke failure texts for the known engine codes: the empty
  /// payload on the real tag (v4.2.0 report) and the new device checks get
  /// their own, actionable wording instead of a generic step message.
  String _failureText(
      AppLocalizationsX l, WriteFlowController flow, List<String> stepNames) {
    final code = flow.failureCode ?? '';
    if (code.startsWith('payload_not_written') ||
        code.startsWith('write_verify_failed') ||
        code.startsWith('crc_mismatch')) {
      return l.wpFailPayload;
    }
    if (code.startsWith('no_programs')) return l.wpFailNoPrograms;
    if (code.startsWith('link_invalid') ||
        code.startsWith('model_unsupported') ||
        code.startsWith('model_mismatch')) {
      return l.wpFailModel;
    }
    if (code.startsWith('uid_signature')) return l.wpFailUid;
    if (code == 'not_iso15693' || code == 'not_type5_tag') {
      return l.idFailNotIso;
    }
    if (code.startsWith('memory_too_small')) return l.idFailMemory;
    return flow.failedStep != null && flow.failedStep! >= 1
        ? l.wpFailStep(stepNames[flow.failedStep! - 1])
        : l.wpFailBusy;
  }

  Widget _stepTile(BuildContext context,
      {required int index,
      required String name,
      required String desc,
      required StepStatus status}) {
    final (color, icon) = switch (status) {
      StepStatus.pending => (Colors.grey.shade600, null),
      StepStatus.active => (AppTheme.orange, null),
      StepStatus.done => (const Color(0xFF35C584), Icons.check),
      StepStatus.failed => (const Color(0xFFE4695C), Icons.close),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: status == StepStatus.active
              ? AppTheme.orange.withValues(alpha: 0.55)
              : status == StepStatus.failed
                  ? const Color(0xFFC0392B).withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: status == StepStatus.active
                  ? AppTheme.orange
                  : status == StepStatus.done
                      ? const Color(0xFF35C584).withValues(alpha: 0.25)
                      : status == StepStatus.failed
                          ? const Color(0xFFC0392B)
                          : Colors.white.withValues(alpha: 0.08),
            ),
            child: icon == null
                ? Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: status == StepStatus.active ? Colors.white : Colors.grey.shade400,
                    ),
                  )
                : Icon(icon, size: 14, color: status == StepStatus.done ? const Color(0xFF35C584) : Colors.white),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Color(0xFFE7EBEF), fontSize: 11.5, fontWeight: FontWeight.w700)),
                Text(desc,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 9.8, height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPowerOff(BuildContext context, AppLocalizationsX l) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.power_off_outlined, color: Color(0xFFC0392B)),
            const SizedBox(width: 10),
            Expanded(child: Text(l.rcTitle)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.rcSub, style: TextStyle(fontSize: 11.5, color: Theme.of(dialogContext).hintColor)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFC0392B).withValues(alpha: 0.08),
                border: Border.all(color: const Color(0xFFC0392B).withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l.rcMsg,
                style: const TextStyle(fontSize: 12, height: 2.0),
              ),
            ),
            const SizedBox(height: 12),
            _step(dialogContext, 1, l.rcS1, l.rcS1d),
            _step(dialogContext, 2, l.rcS2, l.rcS2d),
            _step(dialogContext, 3, l.rcS3, l.rcS3d),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Approved escape path: close the guidance and return to the app.
              Navigator.of(dialogContext).pop(); // close RC dialog
              showAppMessage(this.context, l.wpBackToast);
              Navigator.of(this.context).pop(); // close progress overlay
            },
            child: Text(l.rcBack),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(writeFlowProvider).start();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l.rcRetry),
          ),
        ],
      ),
    );
  }

  Widget _step(BuildContext context, int n, String title, String desc) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppTheme.slate900, shape: BoxShape.circle),
              child: Text('$n', style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(desc,
                      style: TextStyle(fontSize: 10.5, height: 1.7, color: Theme.of(context).hintColor)),
                ],
              ),
            ),
          ],
        ),
      );
}

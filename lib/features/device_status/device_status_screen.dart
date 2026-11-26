import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/crypto/crc32_stm32.dart';
import '../../core/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../state/providers.dart';

/// Device status dashboard — consistent logger read per §4.10.
class DeviceStatusScreen extends ConsumerStatefulWidget {
  const DeviceStatusScreen({super.key});

  @override
  ConsumerState<DeviceStatusScreen> createState() => _DeviceStatusScreenState();
}

class _DeviceStatusScreenState extends ConsumerState<DeviceStatusScreen> {
  bool _techOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deviceStatusProvider).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L(context);
    final fa = isFa(context);
    final controller = ref.watch(deviceStatusProvider);
    final s = controller.status;

    return Scaffold(
      appBar: AppBar(title: Text(l.stTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.stSub, style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor)),
          const SizedBox(height: 12),
          if (controller.reading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.orange),
                  ],
                ),
              ),
            )
          else if (controller.lastError != null && s == null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFFC0392B).withValues(alpha: 0.10),
                border: Border.all(color: const Color(0xFFC0392B).withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.nfc, color: Color(0xFFC0392B), size: 20),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(l.stNoTagTitle,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                color: Color(0xFFC0392B))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(l.stNoTagText,
                      style: TextStyle(
                          fontSize: 11, height: 1.9, color: Theme.of(context).hintColor)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ] else if (s == null) ...[
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(l.stPressRefresh,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11.5, height: 1.9, color: Theme.of(context).hintColor)),
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            // Version card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.sync_outlined, size: 17, color: AppTheme.orangeDeep),
                      const SizedBox(width: 7),
                      Text(l.stVersionCard, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 8),
                    _kv(l.stOnDevice, 'v${faNumInt(fa, s.runVersion)}'),
                    _kv(l.stLastWritten, 'v${faNumInt(fa, s.writtenVersion)}'),
                    const SizedBox(height: 10),
                    _syncChip(l, s.pendingAccept, s.runVersion == s.writtenVersion),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Ongoing event card
            Card(
              child: ListTile(
                leading: Icon(
                  s.hasOngoing ? Icons.bolt : Icons.schedule_outlined,
                  color: AppTheme.orange,
                ),
                title: Text(l.stOngoing, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  s.hasOngoing
                      ? (s.ongoingRelayOn ? l.stRelayOn : l.stRelayOff)
                      : l.stOngoingNone,
                  style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Counters
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.list_alt, size: 17, color: AppTheme.orangeDeep),
                      const SizedBox(width: 7),
                      Text(l.stCounters, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _statTile(fa, s.operatingHour, l.stHour),
                        const SizedBox(width: 8),
                        _statTile(fa, s.outputOnHour, l.stHourOn),
                        const SizedBox(width: 8),
                        _statTile(fa, s.relayOps, l.stCn, unit: null),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Internal error (OI-01: only non-zero is meaningful)
            if (s.internalError != 0)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFC0392B).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFC0392B).withValues(alpha: 0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFC0392B), size: 22),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.stErrCode,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: Color(0xFFC0392B))),
                          const SizedBox(height: 4),
                          Text(l.stErrHint,
                              style: TextStyle(
                                  fontSize: 11, height: 1.8, color: Theme.of(context).hintColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline, color: Color(0xFF1B7F4D)),
                  title: Text(l.stErrCard, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(l.stErrNone,
                      style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor)),
                ),
              ),
            const SizedBox(height: 12),
            // Technical details
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  InkWell(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    onTap: () => setState(() => _techOpen = !_techOpen),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.memory, size: 17, color: Colors.grey),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(l.stTech,
                                style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).hintColor)),
                          ),
                          Icon(_techOpen ? Icons.expand_less : Icons.expand_more, size: 18),
                        ],
                      ),
                    ),
                  ),
                  if (_techOpen)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                      child: Column(
                        children: [
                          _kv('Process_Record_LOG', '0x00', mono: true),
                          _kv('Process_LOG_Address', 'blk 0', mono: true),
                          _kv('LOG_CRC32', crc32Hex(s.logCrc), mono: true),
                          _kv('CRC self-test TV-01..03', crcSelfTest() ? 'PASS' : 'FAIL', mono: true),
                          _kv(
                            l.stLastRead,
                            '${num2(fa, s.lastRead.hour)}:${num2(fa, s.lastRead.minute)}',
                            mono: true,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(l.stReadSeq,
                style: TextStyle(fontSize: 10.5, height: 1.9, color: Theme.of(context).hintColor)),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: () => ref.read(deviceStatusProvider).refresh(),
            icon: const Icon(Icons.refresh),
            label: Text(l.stRefresh),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {bool mono = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(child: Text(k, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor))),
            Text(
              v,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ],
        ),
      );

  Widget _statTile(bool fa, int value, String label, {String? unit = 'h'}) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(
                unit == null ? faNumInt(fa, value) : '${faNumInt(fa, value)} $unit',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: 5),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, color: Theme.of(context).hintColor, height: 1.5)),
            ],
          ),
        ),
      );

  Widget _syncChip(AppLocalizationsX l, bool pending, bool synced) {
    final (label, color, icon) = pending
        ? (l.stPending, const Color(0xFFB4570A), Icons.sync_outlined)
        : synced
            ? (l.stSynced, const Color(0xFF1B7F4D), Icons.check_circle_outline)
            : (l.stOutdated, const Color(0xFFC0392B), Icons.sync_problem_outlined);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }
}

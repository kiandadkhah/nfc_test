import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/domain.dart';
import '../../core/models/program.dart';
import '../../core/nfc/nfc_service.dart';
import '../../core/nfc/tag_link.dart';
import '../../core/platform/system_gate.dart';
import '../../core/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_toasts.dart';
import '../../core/widgets/kianex_shapes.dart';
import '../../core/widgets/nfc_hex_button.dart';
import '../../state/programs_provider.dart';
import '../../state/providers.dart';

/// Home — approved v2.2 layout: black header with brand / device selector /
/// menu, two fixed gauge cards (program memory + timers), the program list
/// with master switches, the «add program» card, the empty state with the
/// two entry actions, and the black footer bar with the hexagonal NFC button.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _gateRan = false;

  @override
  void initState() {
    super.initState();
    // v4.1 startup gate — permissions & hardware prompts run once per app
    // session, right after the first frame so the localization context is
    // ready.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_gateRan || !mounted) return;
      _gateRan = true;
      await runStartupGate(context);
      if (mounted) setState(() {}); // refresh the readiness strip
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L(context);
    final fa = isFa(context);
    final programs = ref.watch(programsProvider);

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: AppTheme.slate900,
            child: SafeArea(bottom: false, child: _header(l)),
          ),
          // v4.1 — NFC / location readiness strip (hidden when all good).
          const SystemStatusStrip(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _chartsRow(context, l, fa, programs),
          ),
          Expanded(
            child: programs.programs.isEmpty
                ? _emptyBody(context, l, fa)
                : _listBody(context, l, fa, programs),
          ),
        ],
      ),
      bottomNavigationBar: _nfcFooter(l),
    );
  }

  // ------------------------------------------------------------------
  // Header (brand · device selector · menu)
  // ------------------------------------------------------------------
  Widget _header(AppLocalizationsX l) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Official KIANEX brand mark (LOGO_SVG.svg) as an asset.
                    SvgPicture.asset(
                      'assets/images/logo.svg',
                      width: 36,
                      height: 36,
                      semanticsLabel: 'KIANEX logo',
                    ),
                    const SizedBox(width: 9),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('KIANEX',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3.5)),
                        // Brand slogan — replaces the old "SMART SOLUTIONS".
                        Text(l.brandSlogan,
                            style: const TextStyle(
                                color: Color(0xFF9AA4AE),
                                fontSize: 9.5,
                                height: 1.5)),
                      ],
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (v) => _onMenu(context, v),
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Text(l.menuEdit)),
                    PopupMenuItem(value: 'status', child: Text(l.menuStatus)),
                    PopupMenuItem(value: 'gps', child: Text(l.menuGps)),
                    PopupMenuItem(value: 'settings', child: Text(l.menuSettings)),
                    const PopupMenuDivider(),
                    PopupMenuItem(value: 'help', child: Text(l.menuHelp)),
                    PopupMenuItem(value: 'about', child: Text(l.menuAbout)),
                  ],
                ),
              ],
            ),
          ),
          // Center device selector (opens the product/device sheet)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showDeviceSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('PTS50N1',
                      style: TextStyle(
                          color: AppTheme.orange,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                  SizedBox(width: 5),
                  Icon(Icons.keyboard_arrow_down, color: AppTheme.orange, size: 19),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onMenu(BuildContext context, String v) {
    switch (v) {
      case 'edit':
        context.push('/programs');
      case 'status':
        context.push('/device');
      case 'gps':
        context.push('/gps');
      case 'settings':
        context.push('/settings');
      case 'help':
        context.push('/help');
      case 'about':
        context.push('/about');
    }
  }

  // ------------------------------------------------------------------
  // Fixed chart cards under the header (memory + timers)
  // ------------------------------------------------------------------
  Widget _chartsRow(
      BuildContext context, AppLocalizationsX l, bool fa, ProgramsController programs) {
    return Row(
      children: [
        _gaugeCard(
          context,
          icon: Icons.memory_outlined,
          title: l.chartMemTitle,
          // Only ENABLED programs consume the device payload — disabling a
          // program frees its event slots (reported bug fix).
          used: programs.enabledEventUsage,
          max: DomainLimits.maxEvents,
          fa: fa,
        ),
        const SizedBox(width: 8),
        _gaugeCard(
          context,
          icon: Icons.monitor_heart_outlined,
          title: l.chartTimerTitle,
          used: programs.enabledTimerUsage,
          max: DomainLimits.maxTimers,
          fa: fa,
        ),
      ],
    );
  }

  Widget _gaugeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int used,
    required int max,
    required bool fa,
  }) {
    final pct = max == 0 ? 0.0 : used / max * 100;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppTheme.orange.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: AppTheme.orange, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text.rich(
                    TextSpan(
                      text: faNumInt(fa, used),
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                      children: [
                        TextSpan(
                          text: ' / ${faNumInt(fa, max)}',
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GaugeDonut(percent: pct),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Program list + add card
  // ------------------------------------------------------------------
  Widget _listBody(BuildContext context, AppLocalizationsX l, bool fa, ProgramsController programs) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 132),
      children: [
        Row(
          children: [
            Text(l.timerPrograms,
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
            const Spacer(),
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text(programs.programs.isEmpty
                  ? l.countEmpty
                  // v3.0: derived counts — active and disabled programs.
                  : (programs.disabledCount > 0
                      ? l.countActiveFmt(faNumInt(fa, programs.activeCount),
                          faNumInt(fa, programs.disabledCount))
                      : l.countPrograms(faNumInt(fa, programs.programs.length)))),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < programs.programs.length; i++)
          _programCard(context, l, fa, programs.programs[i], i),
        const SizedBox(height: 4),
        _addCard(context, l),
      ],
    );
  }

  Widget _programCard(
      BuildContext context, AppLocalizationsX l, bool fa, Program p, int index) {
    final (on, off, timers) = _eventCounts(p);
    final enabled = p.enabled;
    final night = _isNight(p);
    const dim = Color(0xFFB9C0C7);
    final mainColor = enabled ? AppTheme.orange : dim;
    final titleColor = enabled ? null : dim;
    final metaColor = enabled ? Theme.of(context).hintColor : dim;

    return GestureDetector(
      onTap: () {
        ref.read(programsProvider).editProgramAt(index);
        context.push('/programs/new/chain');
      },
      onLongPress: () => _confirmDelete(context, l, p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 4.5, color: mainColor), // status bar (start edge)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 0, 12),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: enabled
                        ? AppTheme.orange.withValues(alpha: 0.12)
                        : const Color(0xFFE4E7EA),
                  ),
                  child: Icon(
                    night ? Icons.nightlight_round : Icons.wb_sunny,
                    color: mainColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700, color: titleColor),
                            ),
                          ),
                          Transform.scale(
                            scale: 0.82,
                            child: Switch(
                              value: enabled,
                              activeThumbColor: AppTheme.orange,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onChanged: (_) => _toggleProgram(index),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l.metaFmt(faNumInt(fa, on), faNumInt(fa, off), faNumInt(fa, timers))} · ${l.relay1}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: metaColor),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          _cycleBadge(l, p.cycle, enabled),
                          const Spacer(),
                          Text(
                            l.viewEvents,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: enabled ? AppTheme.orangeDeep : dim),
                          ),
                          Icon(Icons.chevron_left,
                              size: 14, color: enabled ? AppTheme.orangeDeep : dim),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cycleBadge(AppLocalizationsX l, CycleType c, bool enabled) {
    final (bg, fg) = !enabled
        ? (const Color(0xFFB9C0C7), Colors.white)
        : switch (c) {
            CycleType.daily => (const Color(0xFFF0E2F0), const Color(0xFFA75AA7)),
            CycleType.weekly => (const Color(0xFF888888), Colors.white),
            CycleType.monthly => (const Color(0xFF333333), Colors.white),
            CycleType.annual => (AppTheme.orange, Colors.white),
          };
    final label = switch (c) {
      CycleType.daily => l.daily,
      CycleType.weekly => l.weekly,
      CycleType.monthly => l.monthly,
      CycleType.annual => l.annual,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _addCard(BuildContext context, AppLocalizationsX l) {
    return GestureDetector(
      onTap: () => _startNewProgram(context),
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 8),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: CustomPaint(
          painter: const DashedRRectBorder(),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.orange.withValues(alpha: 0.12),
                  ),
                  child: const Icon(Icons.add, color: AppTheme.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.addCardTitle,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(l.addCardDesc,
                          style: TextStyle(
                              fontSize: 10.5, color: Theme.of(context).hintColor)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left, color: Theme.of(context).hintColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Empty state — exactly two entry actions + sample link
  // ------------------------------------------------------------------
  Widget _emptyBody(BuildContext context, AppLocalizationsX l, bool fa) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 132),
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              const HexGhostIcon(size: 86),
              const SizedBox(height: 14),
              Text(l.emptyTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                l.emptyText,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12, height: 1.9, color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push('/device'),
                  icon: const Icon(Icons.nfc, size: 18),
                  label: Text(l.emptyBtnRead),
                ),
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _startNewProgram(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l.emptyBtnAdd),
                ),
              ),
              const SizedBox(height: 10),
              // The demo/sample-data loader was removed with the QA
              // simulator — the production app works only with the real
              // relay (user directive: «قسمت شبیه‌سازی حذف شود»).
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // Black footer bar with the protruding hexagonal NFC button
  // ------------------------------------------------------------------
  Widget _nfcFooter(AppLocalizationsX l) {
    // Field report: the NFC entry must be more prominent — a taller black
    // footer bar with a larger protruding hexagonal button.
    return SizedBox(
      height: 112,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(height: 76, color: const Color(0xFF0A0D10)),
          ),
          Positioned(
            top: 4,
            child: NfcHexButton(size: 80, onTap: () => _openNfcSheet(context)),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // NFC sheet — read status / set time & location / write programs
  // ------------------------------------------------------------------
  void _openNfcSheet(BuildContext context) {
    final l = L(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.nfcSheetTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text(l.nfcSheetSub,
                style: TextStyle(
                    fontSize: 11.5, height: 1.8, color: Theme.of(context).hintColor)),
            const SizedBox(height: 14),
            _optCard(
              sheetContext,
              icon: Icons.visibility_outlined,
              title: l.readStatusT,
              desc: l.readStatusD,
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push('/device');
              },
            ),
            const SizedBox(height: 9),
            _optCard(
              sheetContext,
              icon: Icons.schedule_outlined,
              title: l.settingsOnlyT,
              desc: l.settingsOnlyD,
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push('/write?mode=settings');
              },
            ),
            const SizedBox(height: 9),
            _optCard(
              sheetContext,
              icon: Icons.calendar_month_outlined,
              title: l.programWriteT,
              desc: l.programWriteD,
              onTap: () {
                Navigator.of(sheetContext).pop();
                final programs = ref.read(programsProvider);
                if (programs.programs.isEmpty) {
                  showAppMessage(context, L(context).noProgramsToast, isError: true);
                  return;
                }
                // Q-05: a disabled program is never sent to the relay.
                if (programs.enabledPrograms.isEmpty) {
                  showAppMessage(context, L(context).allDisabledToast, isError: true);
                  return;
                }
                context.push('/write?mode=program');
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(l.cancel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optCard(
    BuildContext sheetContext, {
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: AppTheme.orange.withValues(alpha: 0.12),
                ),
                child: Icon(icon, color: AppTheme.orange, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10.5, height: 1.6, color: Theme.of(context).hintColor)),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, size: 17, color: Theme.of(context).hintColor),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Device sheet — the single PTS50N1 product card + NFC identify
  // ------------------------------------------------------------------
  void _showDeviceSheet(BuildContext context) {
    final l = L(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.dsheetTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text(l.dsheetSub,
                style: TextStyle(
                    fontSize: 11.5, height: 1.8, color: Theme.of(context).hintColor)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppTheme.orange.withValues(alpha: 0.08),
                border: Border.all(color: AppTheme.orange.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                    ),
                    child: const Icon(Icons.electrical_services, color: AppTheme.orange, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PTS50N1',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(
                          '${L(context).deviceTitle} — ${L(context).deviceSub}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10, height: 1.6, color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  ),
                  Chip(label: Text(L(sheetContext).dsheetCurrent, style: const TextStyle(fontSize: 10.5))),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.orange, width: 1.4),
                  foregroundColor: AppTheme.orangeDeep,
                ),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _showIdentifyOverlay();
                },
                icon: const Icon(Icons.nfc, size: 18),
                label: Text(l.dsIdentifyBtn),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(l.dsIdentifyD,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10.5, color: Theme.of(context).hintColor)),
            ),
            const SizedBox(height: 12),
            Text(l.dsheetNote,
                style: TextStyle(
                    fontSize: 10.5, height: 1.8, color: Theme.of(context).hintColor)),
          ],
        ),
      ),
    );
  }

  void _showIdentifyOverlay() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      pageBuilder: (dialogContext, _, __) => const _IdentifyOverlay(),
    );
  }

  // ------------------------------------------------------------------
  // Mutations
  // ------------------------------------------------------------------
  void _toggleProgram(int index) {
    final l = L(context);
    final programs = ref.read(programsProvider);
    programs.toggleEnabled(index);
    final nowEnabled = programs.programs[index].enabled;
    showAppMessage(context, nowEnabled ? l.progOnToast : l.progOffToast);
  }

  Future<void> _startNewProgram(BuildContext context) async {
    final l = L(context);
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.nameDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.nameDialogQ,
                style: TextStyle(fontSize: 12, color: Theme.of(dialogContext).hintColor)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: DomainLimits.programNameMaxLength,
              decoration: InputDecoration(labelText: l.nameLabel, hintText: l.nameHint),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => FilledButton(
              onPressed: value.text.trim().isEmpty ? null : () => Navigator.of(dialogContext).pop(true),
              child: Text(l.confirm),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(programsProvider)
        ..startDraft()
        ..setDraftName(controller.text.trim());
      if (context.mounted) context.push('/programs/new');
    }
  }

  Future<void> _confirmDelete(BuildContext context, AppLocalizationsX l, Program p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(l.delTitle)),
          ],
        ),
        content: Text(l.delText(p.name),
            style: const TextStyle(fontSize: 12.5, height: 1.9)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            // Approved design: the destructive action keeps the theme orange.
            style: FilledButton.styleFrom(backgroundColor: AppTheme.orange),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      final idx = ref.read(programsProvider).programs.indexOf(p);
      ref.read(programsProvider).deleteAt(idx);
      if (context.mounted) {
        showAppMessage(context, l.programDeleted(p.name));
      }
    }
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------
  (int, int, int) _eventCounts(Program p) {
    var on = 0, off = 0, timers = 0;
    for (final e in p.events) {
      switch (e.cmd) {
        case RelayCommand.on:
          on++;
        case RelayCommand.off:
          off++;
        case RelayCommand.timer:
          timers++;
      }
    }
    return (on, off, timers);
  }

  bool _isNight(Program p) {
    for (final e in p.events) {
      if (e.type == EventType.fixed) return e.hh < 7 || e.hh >= 18;
    }
    return false;
  }
}

/// Full-screen NFC identification overlay — runs the real tag read
/// (onboarding area + system info) through the production NFC service and
/// reports the identified device model back to the user. This replaces the
/// earlier timer-driven simulation with the real «بررسی و شناسایی رله».
class _IdentifyOverlay extends ConsumerStatefulWidget {
  const _IdentifyOverlay();

  @override
  ConsumerState<_IdentifyOverlay> createState() => _IdentifyOverlayState();
}

class _IdentifyOverlayState extends ConsumerState<_IdentifyOverlay> {
  TagIdentity? _identity;
  String? _failureKey;
  String? _failureDetail;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    if (!mounted) return;
    setState(() {
      _retrying = true;
      _failureKey = null;
      _failureDetail = null;
    });
    final logger = ref.read(appLoggerProvider);
    logger.action('identify requested from device sheet');
    try {
      final identity = await ref.read(nfcServiceProvider).identify();
      if (!mounted) return;
      setState(() {
        _identity = identity;
        _retrying = false;
      });
    } on TagLinkException catch (e) {
      if (!mounted) return;
      logger.warn('identify failed: ${e.message}');
      setState(() {
        _failureKey = e.message;
        _failureDetail = e.message.startsWith('link_invalid:') ||
                e.message.startsWith('memory_too_small:')
            ? e.message.split(':').sublist(1).join(':')
            : null;
        _retrying = false;
      });
    } catch (e) {
      if (!mounted) return;
      logger.error('identify failed: $e');
      setState(() {
        _failureKey = 'no_tag';
        _retrying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L(context);
    final fa = isFa(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: const Color(0xF20A0D10),
        width: double.infinity,
        child: SafeArea(
          child: _identity != null
              ? _result(context, l, fa, _identity!)
              : _failureKey != null
                  ? _failure(context, l)
                  : _scanning(context, l),
        ),
      ),
    );
  }

  Widget _scanning(BuildContext context, AppLocalizationsX l) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const NfcHexBadge(size: 64, pulse: true),
          const SizedBox(height: 18),
          Text(l.dsScanTitle,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              l.dsScanSub,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 11.5, height: 1.8),
            ),
          ),
          const SizedBox(height: 24),
          if (_retrying)
            const CircularProgressIndicator(color: AppTheme.orange, strokeWidth: 2.4)
          else
            TextButton(
              onPressed: () {
                ref.read(nfcServiceProvider).cancelActiveOperation();
                Navigator.of(context).pop();
              },
              child: Text(l.wpCancel,
                  style: TextStyle(color: Colors.grey.shade400)),
            ),
        ],
      ),
    );
  }

  Widget _result(BuildContext context, AppLocalizationsX l, bool fa, TagIdentity id) {
    // v4.3 — four warn cases, in decision order: memory, unknown link,
    // recognized-but-unsupported model (e.g. PTS50R15), UID signature.
    final (title, text, warnColor) = switch (id) {
      _ when !id.enoughMemory => (
          l.idMemoryWarnTitle,
          l.idMemoryWarnText,
          const Color(0xFFE4695C),
        ),
      _ when id.recognizedModel == null => (
          l.idLinkInvalidTitle,
          l.idLinkInvalidText(
              id.ndefUri.isEmpty ? '—' : id.ndefUri),
          const Color(0xFFE4695C),
        ),
      _ when !id.modelMatched => (
          l.idModelUnsupportedTitle,
          l.idModelUnsupportedText(
              id.recognizedModel ?? '-', NdefContract.supportedModel),
          const Color(0xFFE4695C),
        ),
      _ when !id.uidSignatureOk => (
          l.idUidWarnTitle,
          l.idUidWarnText,
          const Color(0xFFE4695C),
        ),
      _ => ('', '', const Color(0xFF35C584)),
    };
    final warn = title.isNotEmpty;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              warn ? Icons.report_problem_outlined : Icons.check_circle_outline,
              color: warnColor,
              size: 68,
            ),
            const SizedBox(height: 14),
            Text(
              warn ? title : l.dsFound,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              warn ? text : l.dsFoundD,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 11.5, height: 1.8),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kv(l.idTagModel, id.modelName.isEmpty ? '—' : id.modelName),
                  _kv(l.idLinkModel,
                      id.recognizedModel ?? '—'),
                  _kv(l.idTagMemory,
                      '${faNumInt(fa, id.totalBlocks)} × ${faNumInt(fa, id.blockSize)} B'),
                  _kv(l.idTagUid, id.uid),
                  _kv(l.idTagUri, id.ndefUri.isEmpty ? '—' : id.ndefUri),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l.ok),
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
                    onPressed: _run,
                    child: Text(l.idRetry),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _failure(BuildContext context, AppLocalizationsX l) {
    final key = _failureKey ?? 'no_tag';
    // v4.3 — prefix matching: several codes carry a detail suffix
    // (link_invalid:<uri>, model_unsupported:<model>, memory_too_small:<g>).
    final message = switch (key) {
      _ when key.startsWith('link_invalid') =>
        l.idLinkInvalidText(_failureDetail ?? '—'),
      _ when key.startsWith('model_unsupported') => l.idModelUnsupportedText(
          _failureDetail ?? '-', NdefContract.supportedModel),
      _ when key.startsWith('uid_signature') => l.idUidWarnText,
      _ when key.startsWith('memory_too_small') => l.idFailMemory,
      'not_iso15693' => l.idFailNotIso,
      'not_type5_tag' => l.idFailNotIso,
      'nfc_disabled' => l.idFailNfcOff,
      _ => l.idFailNoTag,
    };
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFE4695C), size: 68),
            const SizedBox(height: 14),
            Text(l.idFailTitle,
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 11.5, height: 1.8),
            ),
            if (_failureDetail != null && _failureDetail!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _failureDetail!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppTheme.orange, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: FilledButton.icon(
                    onPressed: _run,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(l.idRetry),
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
                      ref.read(nfcServiceProvider).cancelActiveOperation();
                      Navigator.of(context).pop();
                    },
                    child: Text(l.cancel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 92,
              child: Text(k,
                  style: TextStyle(
                      fontSize: 10.5, color: Colors.grey.shade500)),
            ),
            Expanded(
              child: Text(v,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ],
        ),
      );
}

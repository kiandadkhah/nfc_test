import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/state/app_providers.dart';
import '../../core/theme/app_theme.dart';

/// Help — seven short topics aligned with the spec §4.6.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L(context);
    final topics = <(IconData, String, String)>[
      (Icons.start, l.heT1, l.heD1),
      (Icons.schedule_outlined, l.heT2, l.heD2),
      (Icons.timer_outlined, l.heT3, l.heD3),
      (Icons.sensors, l.heT4, l.heD4),
      (Icons.rule_outlined, l.heT5, l.heD5),
      (Icons.wifi_off_outlined, l.heT6, l.heD6),
      (Icons.data_usage_outlined, l.heT7, l.heD7),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.heTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.heSub, style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor)),
          const SizedBox(height: 8),
          for (final (icon, title, desc) in topics)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        color: AppTheme.orange.withValues(alpha: 0.12),
                      ),
                      child: Icon(icon, size: 20, color: AppTheme.orangeDeep),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(desc,
                              style: TextStyle(
                                  fontSize: 11.5, height: 1.9, color: Theme.of(context).hintColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// About — version, target model and references.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.abTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                // Official KIANEX brand mark (LOGO_SVG.svg).
                SvgPicture.asset(
                  'assets/images/logo.svg',
                  width: 84,
                  height: 84,
                  semanticsLabel: 'KIANEX logo',
                ),
                const SizedBox(height: 12),
                const Text('KIANEX',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 8)),
                Text(l.brandSlogan, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                children: [
                  _kv(context, l.abVer, '4.0.0'),
                  _kv(context, l.abMode, l.abModeV),
                  _kv(context, l.abTarget, 'PTS50N1 — ${l.deviceEngName}'),
                  _kv(context, l.abImpl, l.abImplV),
                  _kv(context, l.abSot, l.abSotV),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(l.abNote,
              style: TextStyle(fontSize: 11, height: 1.95, color: Theme.of(context).hintColor)),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(k, style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor)),
            ),
            Expanded(
              child: Text(v,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}

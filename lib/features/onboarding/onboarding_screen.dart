import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../state/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _pages = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(settingsProvider).finishOnboarding();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final l = L(context);
    final kickers = [l.obKicker1, l.obKicker2, l.obKicker3];
    final titles = [l.obTitle1, l.obTitle2, l.obTitle3];
    final texts = [l.obText1, l.obText2, l.obText3];
    final icons = [
      Icons.home_filled,
      Icons.nfc,
      Icons.calendar_month,
    ];

    return Scaffold(
      backgroundColor: AppTheme.slate900,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.storage, color: AppTheme.orange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'KIANEX',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 6,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _finish,
                    child: Text(l.skip,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75))),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.orange.withValues(alpha: 0.10),
                        ),
                        child: Icon(icons[i], color: AppTheme.orange, size: 84),
                      ),
                      const SizedBox(height: 26),
                      Text(
                        kickers[i].toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.orange,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        titles[i],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        texts[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13.5,
                          height: 2.0,
                        ),
                      ),
                      if (i == 1) ...[
                        const SizedBox(height: 18),
                        _point(l.obPoint1, Icons.nfc),
                        _point(l.obPoint2, Icons.check_circle_outline),
                        _point(l.obPoint3, Icons.shield_outlined),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page ? AppTheme.orange : Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_page == _pages - 1) {
                      _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(_page == _pages - 1 ? l.getStarted : l.next),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _point(String text, IconData icon) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.orange, size: 17),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Color(0xFFC9D2DB), fontSize: 12, height: 1.7),
              ),
            ),
          ],
        ),
      );
}

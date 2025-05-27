import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/common.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  // ── record tuple ── (requires Dart ≥3)
  static const _pages = [
    ('assets/splash_1.png', 'Jadwal Rehabilitasi',
    'Dapatkan jadwal latihan dan temu rutin untuk rehabilitasi Anda'),
    ('assets/splash_2.png', 'Rehabilitasi Mandiri\nBerbasis Computer Vision',
    'Dapatkan paket rehabilitasi termonitoring dengan teknologi pose detection'),
    ('assets/splash_3.png', 'Resep Gerakan Rehabilitasi',
    'Dapatkan resep gerakan rehabilitasi yang disesuaikan dengan kebutuhan'),
    ('assets/splash_4.png', 'Konsultasi Online',
    'Lakukan konsultasi kendala rehabilitasi dengan terapis Anda'),
    ('assets/splash_5.png', 'Pola Makan',
    'Dapatkan rekomendasi makanan pendukung rehabilitasi'),
    ('assets/splash_6.png', 'Mari Kembalikan\nKemampuan Fisik Anda',
    'NeuReCare App'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ─────────── Tombol Skip (Sembunyikan di slide terakhir) ───────────
            if (_index < _pages.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Skip'),
                ),
              ),

            // ─────────── PageView ───────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (v) => setState(() => _index = v),
                itemBuilder: (_, i) {
                  final (img, title, desc) = _pages[i];
                  return Column(
                    children: [
                      const SizedBox(height: 24),
                      Image.asset(img, height: 220),
                      const SizedBox(height: 48),
                      Text(title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(desc,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.green)),
                      ),
                    ],
                  );
                },
              ),
            ),

            // ─────────── Indicator dot ───────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                    (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.all(3),
                  width: 20,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                    i == _index ? Colors.orange : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // ─────────── Tombol Next / Get Started ───────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: NeuButton(
                label:
                _index == _pages.length - 1 ? 'Get Started' : 'Selanjutnya',
                onTap: () {
                  if (_index == _pages.length - 1) {
                    context.go('/login');
                  } else {
                    _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/common.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    ('assets/splash_1.png', 'Jadwal Rehabilitasi',
    'Dapatkan jadwal latihan dan temu rutin untuk rehabilitasi Anda'),
    ('assets/splash_2.png', 'Rehabilitasi Mandiri\nBerbasis Computer Vision',
    'Paket rehabilitasi termonitoring dengan pose-detection'),
    ('assets/splash_3.png', 'Resep Gerakan Rehabilitasi',
    'Resep gerakan yang disesuaikan kebutuhan'),
    ('assets/splash_4.png', 'Konsultasi Online',
    'Konsultasi kendala rehabilitasi dengan terapis'),
    ('assets/splash_5.png', 'Pola Makan',
    'Rekomendasi makanan pendukung rehabilitasi'),
    ('assets/splash_6.png', 'Mari Kembalikan\nKemampuan Fisik Anda',
    'Restro App'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboard_done', true);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          if (_index < _pages.length - 1)
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Color(0xFF2F3026),
                  ),
                ),
              ),
            ),
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
                  color: i == _index
                      ? Colors.orange
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: NeuButton(
              label:
              _index == _pages.length - 1 ? 'Get Started' : 'Selanjutnya',
              onTap: () {
                if (_index == _pages.length - 1) {
                  _finish();
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

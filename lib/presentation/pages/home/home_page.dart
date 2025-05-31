import 'package:flutter/material.dart';
import 'calendar_page.dart';
import 'detect_page.dart';
import 'chat_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _idx = 0;

  final _pages = const [
    _Dashboard(),
    CalendarPage(),
    DetectPage(),
    ChatPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (v) => setState(() => _idx = v),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Kalender'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: 'Deteksi'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header logo + notif
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset('assets/logo_homepage.png', height: 32),
                const Icon(Icons.notifications_none),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Selamat datang,\nJames!',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                _statCard(Icons.accessibility_new, '8', 'Gerakan'),
                const SizedBox(width: 12),
                _statCard(Icons.timer, '20', 'Menit'),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Lanjutkan Program'),
              ),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(Icons.restaurant),
              tileColor: Colors.orange.shade50,
              title: const Text('Pola Makan'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  /// Kartu statistik (dipakai dua kali)
  Widget _statCard(IconData icon, String value, String label) => Expanded(
    child: Container(
      height: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Colors.orange),
          const SizedBox(height: 8),
          Text(value,
              style:
              const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label),
        ],
      ),
    ),
  );
}

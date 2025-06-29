import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:restro/presentation/pages/detect/program_history_page.dart';
import 'package:restro/presentation/pages/home/report_history_page.dart';
import '../calendar/calendar_page.dart';
import '../profile/profile_page.dart';
import 'diet_plan_page.dart';

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras; // Add cameras parameter

  const HomePage({super.key, required this.cameras}); // Constructor

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _idx = 0;

  // Lazily initialize _pages to use widget.cameras
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _Dashboard(cameras: widget.cameras), // Pass cameras to Dashboard
      const CalendarPage(),
      ProgramHistoryPage(cameras: widget.cameras), // Use ExerciseSelectionPage here
      const DietPlanPage(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (v) => setState(() => _idx = v),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white, // Background navigation bar changed to white
        selectedItemColor: Colors.green.shade700, // Selected icon color (darker green for contrast)
        unselectedItemColor: Colors.grey.shade600, // Unselected icon color (darker grey for visibility on white)
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Kalender'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_gymnastics), label: 'Latihan'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Pola Makan'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  final List<CameraDescription> cameras; // Receive cameras parameter

  const _Dashboard({super.key, required this.cameras}); // Constructor

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            const Text(
              'Halo, Pasien!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black), // Text color explicitly black
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _statCard(Icons.run_circle, '8', 'Gerakan'),
                const SizedBox(width: 16),
                _statCard(Icons.timer, '20', 'Menit'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom( // Using ElevatedButton.styleFrom directly
                  backgroundColor: Colors.green.shade700, // Main button background color
                  foregroundColor: Colors.white, // Main button text color
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProgramHistoryPage(cameras: cameras),
                    ),
                  );
                },
                child: const Text('Lanjutkan Program'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom( // Using ElevatedButton.styleFrom directly
                  backgroundColor: Colors.green.shade100, // Light green background
                  foregroundColor: Colors.green.shade900, // Dark green text for contrast
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReportHistoryPage()),
                  );
                },
                child: const Text('Riwayat Laporan'),
              ),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: Icon(Icons.restaurant, color: Colors.green.shade700),
              tileColor: Colors.green.shade50,
              title: const Text('Pola Makan'),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const DietPlanPage())),
            ),
            // Tambahkan bagian lainnya dari homepage Anda di sini
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
        color: Colors.green.shade50, // Background color for stat cards (very light green)
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Colors.green.shade700), // Icon color (darker green)
          const SizedBox(height: 8),
          Text(value,
              style:
              const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)), // Text color explicitly black
          Text(label, style: const TextStyle(color: Colors.black)), // Text color explicitly black
        ],
      ),
    ),
  );
}
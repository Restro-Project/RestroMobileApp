import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../data/api_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  /* ────────── state ────────── */
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();
  bool _loading = true;

  /// map   yyyy-mm-dd (tanpa time) → list program
  final Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadRange(_focused);
  }

  /* ────────── load API ────────── */
  Future<void> _loadRange(DateTime center) async {
    setState(() => _loading = true);

    final start = DateTime(center.year, center.month, 1);
    final end   = DateTime(center.year, center.month + 1, 0);
    final fmt   = DateFormat('yyyy-MM-dd');

    final list = await ApiService.getCalendarPrograms(
      start: fmt.format(start),
      end  : fmt.format(end),
    );

    _events.clear();
    for (final p in list) {
      final d = DateTime.parse(p['tanggal_program']);
      final key = DateTime(d.year, d.month, d.day);
      _events.putIfAbsent(key, () => []).add(p);
    }

    if (mounted) setState(() => _loading = false);
  }

  /* ────────── helper ────────── */
  List<Map<String, dynamic>> _getEvents(DateTime day) =>
      _events[DateTime(day.year, day.month, day.day)] ?? [];

  /* ────────── UI ────────── */
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kalender Program')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
      children: [
        TableCalendar(
          locale: 'id_ID',
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focused,
          selectedDayPredicate: (d) =>
          d.year == _selected.year &&
              d.month == _selected.month &&
              d.day == _selected.day,
          eventLoader: _getEvents,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: false,
          ),
          calendarStyle: CalendarStyle(
            markerDecoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.green.shade200,
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          onDaySelected: (sel, foc) =>
              setState(() => _selected = sel),
          onPageChanged: (f) {
            _focused = f;
            _loadRange(f);
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: _DayEventList(
            events: _getEvents(_selected),
            onTap: _showDetail,
          ),
        ),
      ],
    ),
  );

  /* ────────── bottom-sheet detail ────────── */
  void _showDetail(Map<String, dynamic> program) async {
    // ambil detail terkini (status dsb.)
    Map<String, dynamic>? detail;
    try {
      detail = await ApiService.getTodayProgram();
    } catch (_) {
      // fallback pakai item dari list
      detail = program;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ProgramDetailSheet(detail: detail!),
    );
  }
}

/*════════════════════════════════════════════════════════════════════*/
/*                         LIST EVENT HARI INI                        */
/*════════════════════════════════════════════════════════════════════*/
class _DayEventList extends StatelessWidget {
  const _DayEventList({
    required this.events,
    required this.onTap,
  });
  final List<Map<String, dynamic>> events;
  final void Function(Map<String, dynamic>) onTap;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(child: Text('- Tidak ada jadwal -'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final e = events[i];
        return InkWell(
          onTap: () => onTap(e),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e['nama_program'] ?? '-',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(e['status'] ?? '',
                        style: const TextStyle(color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(DateFormat.Hm().format(
                        DateTime.parse(e['tanggal_program'])
                            .add(const Duration(hours: 13))), // dummy jam 13:00
                        style: const TextStyle(color: Colors.green)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/*════════════════════════════════════════════════════════════════════*/
/*                        BOTTOM-SHEET DETAIL                         */
/*════════════════════════════════════════════════════════════════════*/
class _ProgramDetailSheet extends StatelessWidget {
  const _ProgramDetailSheet({required this.detail});
  final Map<String, dynamic> detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding:
    EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.8,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding:
        const EdgeInsets.symmetric(horizontal: 24).copyWith(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Detail Jadwal',
                style:
                TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _row(Icons.menu_book_rounded, 'Jenis Program',
                detail['nama_program'] ?? '-'),
            const SizedBox(height: 16),
            _row(Icons.sticky_note_2_rounded, 'Catatan Terapis',
                detail['catatan_terapis'] ?? '-'),
            const SizedBox(height: 16),
            _row(Icons.person, 'Terapis',
                detail['terapis_nama'] ??
                    detail['terapis']?['nama_lengkap'] ??
                    '-'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: arahkan ke halaman “Mulai Program”
                },
                child: const Text('Lanjutkan Program'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );

  Widget _row(IconData icon, String title, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: Colors.orange, size: 20),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/api_service.dart';
import 'report_detail_page.dart';

class ReportHistoryPage extends StatefulWidget {
  const ReportHistoryPage({super.key});

  @override
  State<ReportHistoryPage> createState() => _ReportHistoryPageState();
}

class _ReportHistoryPageState extends State<ReportHistoryPage> {
  final _fmt          = DateFormat('d MMM yyyy', 'id');
  final _items        = <Map<String, dynamic>>[];
  int  _page          = 1;
  bool _loading       = true;
  bool _lastPageReached = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (_lastPageReached) return;

    setState(() => _loading = true);
    final list = await ApiService.getReportHistory(page: _page, perPage: 10);

    if (list.isEmpty) {
      _lastPageReached = true;
    } else {
      _items.addAll(list);
      _page++;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Riwayat Laporan')),
    body: RefreshIndicator(
      onRefresh: () async {
        _items.clear();
        _page               = 1;
        _lastPageReached    = false;
        await _fetch();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length + 1, // slot extra untuk loader/footer
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, idx) {
          /* ---------- footer / indikator ---------- */
          if (idx == _items.length) {
            if (_loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!_lastPageReached) {
              _fetch(); // trigger lazy load berikutnya
              return const Center(child: CircularProgressIndicator());
            }
            return const SizedBox.shrink();
          }

          /* ---------- satu kartu laporan ---------- */
          final m   = _items[idx];
          final d   = DateTime.parse(m['tanggal_laporan_disubmit']);
          final pNm = m['program_info']['nama_program'] ?? '-';

          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ReportDetailPage(laporanId: m['laporan_id']),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pNm,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Dikirim: ${_fmt.format(d)}'),
                  Text(
                      'Durasi: ${m['total_waktu_rehabilitasi_string'] ?? '-'}'),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

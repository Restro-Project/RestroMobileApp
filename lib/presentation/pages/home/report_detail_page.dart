import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/api_service.dart';

class ReportDetailPage extends StatefulWidget {
  final int laporanId;
  const ReportDetailPage({super.key, required this.laporanId});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  late Future<Map<String, dynamic>> _future;

  final _fmt = DateFormat('d MMM yyyy – HH:mm', 'id');

  @override
  void initState() {
    super.initState();
    _future = ApiService.getReportDetail(widget.laporanId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detail Laporan')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (c, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!s.hasData) {
          return const Center(child: Text('Gagal memuat data'));
        }

        final data      = s.data!;
        final program   = data['program_info'];
        final tanggal   = DateTime.parse(
            data['tanggal_laporan_disubmit'] ?? program['tanggal_program']);
        final detailArr = (data['detail_hasil_gerakan'] as List)
            .cast<Map<String, dynamic>>();
        final summary   = data['summary_total_hitungan'] ?? {};

        /* ---------------- UI utama ---------------- */
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('Program'),
            Text(program['nama_program'] ?? '-',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Terlapor: ${_fmt.format(tanggal)}'),
            const Divider(height: 32),

            _sectionTitle('Ringkasan'),
            Text('Durasi : ${data['total_waktu_rehabilitasi_string']}'),
            Text('Sempurna        : ${summary['sempurna'] ?? 0}'),
            Text('Tidak sempurna  : ${summary['tidak_sempurna'] ?? 0}'),
            Text('Tidak terdeteksi: ${summary['tidak_terdeteksi'] ?? 0}'),
            const Divider(height: 32),

            if ((data['catatan_pasien_laporan'] as String).isNotEmpty) ...[
              _sectionTitle('Catatan Pasien'),
              Text(data['catatan_pasien_laporan']),
              const Divider(height: 32),
            ],

            _sectionTitle('Detail per Gerakan'),
            ...detailArr.map(_movementTile).toList(),
          ],
        );
      },
    ),
  );

  /* ---------- helper UI ---------- */

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t,
        style:
        const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  );

  /// Kotak satu gerakan di dalam detail
  Widget _movementTile(Map<String, dynamic> m) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(m['nama_gerakan'] ?? '-',
          style:
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('Repetisi rencana : ${m['jumlah_repetisi_direncanakan']}'),
      Text('Sempurna         : ${m['jumlah_sempurna']}'),
      Text('Tidak sempurna   : ${m['jumlah_tidak_sempurna']}'),
      Text('Tidak terdeteksi : ${m['jumlah_tidak_terdeteksi']}'),
      Text('Waktu (detik)    : ${m['waktu_aktual_per_gerakan_detik']}'),
    ]),
  );
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/api_service.dart';
import '../../../main.dart';
import '../detect/detect_page.dart';

class ProgramDetailPage extends StatefulWidget {
  final int programId;
  const ProgramDetailPage({Key? key, required this.programId})
      : super(key: key);

  @override
  State<ProgramDetailPage> createState() => _ProgramDetailPageState();
}

class _ProgramDetailPageState extends State<ProgramDetailPage> {
  final _fmt = DateFormat('d MMMM y', 'id');
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /* ─────────── HTTP ─────────── */
  Future<void> _load() async {
    setState(() => _loading = true);
    _data = await ApiService.getProgramDetail(widget.programId);
    if (mounted) setState(() => _loading = false);
  }

  /* ─────────── tombol ─────────── */
  bool get _canStart =>
      _data!['status'] == 'belum_dimulai' || _data!['status'] == 'berjalan';

  String get _labelBtn =>
      _data!['status'] == 'belum_dimulai' ? 'Mulai Program' : 'Lanjutkan';

  Future<bool?> _confirm(String title, String msg) => showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(msg),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal')),
        ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Iya')),
      ],
    ),
  );

  Future<void> _handleStartOrContinue() async {
    /* jika status masih “belum_dimulai” → konfirmasi & ubah ke berjalan */
    if (_data!['status'] == 'belum_dimulai') {
      final ok = await _confirm(
          'Mulai program?', 'Status akan diubah menjadi "berjalan"');
      if (ok != true) return;

      await ApiService.updateProgramStatus(widget.programId, 'berjalan');
      await _load();                            // refresh => “berjalan”
    }

    /* susun plannedExercises */
    final list = (_data!['list_gerakan_direncanakan'] as List)
        .cast<Map<String, dynamic>>();
    final planned = list
        .map((g) => {
      'actionName': g['nama_gerakan'],
      'targetReps': g['jumlah_repetisi_direncanakan'],
      'gerakanId' : g['gerakan_id'],
    })
        .toList();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetectPage(
          cameras: cameras,                // global list
          plannedExercises: planned,
          maxDurationPerRep: 20,
          programId: widget.programId,
        ),
      ),
    );

    /* selesai latihan: muat ulang agar status → “selesai” */
    await _load();
  }

  /* ─────────── UI ─────────── */
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detail Program')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(_data!['nama_program'],
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(_fmt.format(DateTime.parse(_data!['tanggal_program']))),
        const SizedBox(height: 8),
        Text('Status : ${_data!['status']}'),
        const SizedBox(height: 16),

        /* catatan terapis */
        const Text('Catatan Terapis',
            style: TextStyle(fontWeight: FontWeight.w600)),
        Text(_data!['catatan_terapis'] ?? '-'),
        const SizedBox(height: 16),

        /* daftar gerakan */
        const Text('Gerakan',
            style: TextStyle(fontWeight: FontWeight.w600)),
        ...(_data!['list_gerakan_direncanakan'] as List)
            .map((g) => Text(
            '• ${g['nama_gerakan']} (${g['jumlah_repetisi_direncanakan']}×)')),

        const SizedBox(height: 32),

        if (_canStart)
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _handleStartOrContinue,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade800),
              child: Text(_labelBtn),
            ),
          ),
      ],
    ),
  );
}

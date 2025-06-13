import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/api_service.dart';
import 'debug_page.dart';
import 'program_detail_page.dart';

class ProgramHistoryPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const ProgramHistoryPage({super.key, required this.cameras});
  @override
  State<ProgramHistoryPage> createState() => _ProgramHistoryPageState();
}

class _ProgramHistoryPageState extends State<ProgramHistoryPage> {
  final _controller = ScrollController();
  final _fmt = DateFormat('d MMM yyyy', 'id');
  int _page = 1;
  bool _loading = true;
  bool _last = false;
  final _items = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.position.pixels >
          _controller.position.maxScrollExtent - 200 &&
          !_loading &&
          !_last) {
        _fetch();
      }
    });
    _fetch();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (_last) return;
    setState(() => _loading = true);
    final list =
    await ApiService.getProgramHistory(page: _page, perPage: 10);
    if (list.isEmpty) _last = true;
    _items.addAll(list);
    _page++;
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Program'),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              c,
              MaterialPageRoute(
                builder: (_) => DebugPage(cameras: widget.cameras), // ← FIX
              ),
            ),
            child: const Text('debug', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _items.clear();
          _page = 1;
          _last = false;
          await _fetch();
        },
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, idx) {
            if (idx == _items.length) {
              if (_loading) {
                return const Center(child: CircularProgressIndicator());
              }
              return const SizedBox.shrink();
            }
            final m = _items[idx];
            final d = DateTime.parse(m['tanggal_program']);
            return InkWell(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ProgramDetailPage(programId: m['id']))),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m['nama_program'],
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(_fmt.format(d)),
                      Text('Status : ${m['status']}'),
                    ]),
              ),
            );
          },
        ),
      ));
}

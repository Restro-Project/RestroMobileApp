import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/api_service.dart';

class DietPlanPage extends StatefulWidget {
  const DietPlanPage({super.key});
  @override _DietPlanPageState createState() => _DietPlanPageState();
}

class _DietPlanPageState extends State<DietPlanPage> {
  late DateTime _selected;
  Map<String, dynamic>? _plan;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selected = DateTime.now();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selected);
      _plan = await ApiService.getDietPlan(dateStr);
    } catch (_) {
      _plan = null;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Rencana Pola Makan')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _plan == null
        ? const Center(child: Text('Tidak ada data'))
        : ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _row('Pagi',  _plan!['menu_pagi']),
        _row('Siang', _plan!['menu_siang']),
        _row('Malam', _plan!['menu_malam']),
        _row('Camilan', _plan!['cemilan']),
      ],
    ),
    bottomNavigationBar: BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.date_range),
          label: const Text('Pilih Tanggal Lain'),
          onPressed: () async {
            final d = await showDatePicker(
              context: context,
              firstDate: DateTime(2024),
              lastDate: DateTime(2030),
              initialDate: _selected,
              locale: const Locale('id'),
            );
            if (d != null) {
              setState(() => _selected = d);
              _fetch();
            }
          },
        ),
      ),
    ),
  );

  Widget _row(String title, String? val) => ListTile(
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Text(val ?? '-'),
  );
}
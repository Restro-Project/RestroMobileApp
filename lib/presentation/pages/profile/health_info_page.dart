import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HealthInfoPage extends StatefulWidget {
  const HealthInfoPage({super.key});

  @override
  State<HealthInfoPage> createState() => _HealthInfoPageState();
}

class _HealthInfoPageState extends State<HealthInfoPage> {
  /* ── controller ──────────────────────────────────────────────── */
  final _formKey  = GlobalKey<FormState>();
  final _heightC  = TextEditingController();
  final _weightC  = TextEditingController();
  final _medicalC = TextEditingController();
  final _allergyC = TextEditingController();

  /* ── dropdown notifier ────────────────────────────────────────── */
  final _btype = ValueNotifier<String>('A');

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final uid = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance.collection('users').doc(uid).get().then((d) {
      final m            = d.data()!;
      _heightC.text      = (m['height']  ?? '').toString();
      _weightC.text      = (m['weight']  ?? '').toString();
      _medicalC.text     = m['medicalHistory'] ?? '';
      _allergyC.text     = m['allergyHistory'] ?? '';
      _btype.value       = ['A','B','AB','O'].contains(m['bloodType'])
          ? m['bloodType']
          : 'A';
      setState(() {});
    });
  }

  @override
  void dispose() {
    _heightC.dispose();
    _weightC.dispose();
    _medicalC.dispose();
    _allergyC.dispose();
    super.dispose();
  }

  /* ── UI ───────────────────────────────────────────────────────── */
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Informasi Kesehatan')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: ListView(children: [
          _field(_heightC, 'Tinggi Badan (cm)', kb: TextInputType.number),
          const SizedBox(height: 16),
          _field(_weightC, 'Berat Badan (kg)', kb: TextInputType.number),
          const SizedBox(height: 16),
          _dropdown('Golongan Darah', _btype, ['A', 'B', 'AB', 'O']),
          const SizedBox(height: 16),
          _field(_medicalC, 'Riwayat Medis'),
          const SizedBox(height: 16),
          _field(_allergyC, 'Riwayat Alergi'),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kembali'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const CircularProgressIndicator()
                      : const Text('Simpan'),
                ),
              ),
            ],
          ),
        ]),
      ),
    ),
  );

  /* ── helper widget & logic ───────────────────────────────────── */
  Widget _field(TextEditingController c, String l, {TextInputType? kb}) =>
      TextFormField(
        controller: c,
        keyboardType: kb,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(labelText: l),
        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
      );

  Widget _dropdown(String l, ValueNotifier<String> vn, List<String> items) =>
      ValueListenableBuilder<String>(
        valueListenable: vn,
        builder: (_, val, __) => DropdownButtonFormField<String>(
          value: items.contains(val) ? val : null,
          hint : const Text('Pilih'),
          decoration: InputDecoration(labelText: l),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => vn.value = v!,
        ),
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'height'        : int.tryParse(_heightC.text) ?? 0,
      'weight'        : int.tryParse(_weightC.text) ?? 0,
      'bloodType'     : _btype.value,
      'medicalHistory': _medicalC.text.trim(),
      'allergyHistory': _allergyC.text.trim(),
    });

    if (mounted) Navigator.pop(context);
  }
}

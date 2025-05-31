import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PatientInfoPage extends StatefulWidget {
  const PatientInfoPage({super.key});

  @override
  State<PatientInfoPage> createState() => _PatientInfoPageState();
}

class _PatientInfoPageState extends State<PatientInfoPage> {
  /* ── controller & state ──────────────────────────────────────── */
  final _formKey     = GlobalKey<FormState>();
  final _fullNameC   = TextEditingController();
  final _birthPlaceC = TextEditingController();
  final _addressC    = TextEditingController();
  final _companionC  = TextEditingController();
  final _gender      = ValueNotifier<String>('Laki-laki');

  DateTime? _birthDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance.collection('users').doc(uid).get().then((d) {
      final m            = d.data()!;
      _fullNameC.text    = m['fullName']   ?? '';
      _birthPlaceC.text  = m['birthPlace'] ?? '';
      _addressC.text     = m['address']    ?? '';
      _companionC.text   = m['companionName'] ?? '';
      _gender.value      = ['Laki-laki','Perempuan'].contains(m['gender'])
          ? m['gender']
          : 'Laki-laki';
      final ts           = m['birthDate'];
      if (ts != null) _birthDate = (ts as Timestamp).toDate();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _fullNameC.dispose();
    _birthPlaceC.dispose();
    _addressC.dispose();
    _companionC.dispose();
    super.dispose();
  }

  /* ── UI ───────────────────────────────────────────────────────── */
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Informasi Pasien')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: ListView(children: [
          _field(_fullNameC, 'Nama Lengkap'),
          const SizedBox(height: 16),
          _dropdown('Jenis Kelamin', _gender, ['Laki-laki', 'Perempuan']),
          const SizedBox(height: 16),
          _dateField(),
          const SizedBox(height: 16),
          _field(_birthPlaceC, 'Tempat Lahir'),
          const SizedBox(height: 16),
          _field(_addressC, 'Alamat', lines: 2),
          const SizedBox(height: 16),
          _field(_companionC, 'Nama Pendamping'),
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
  Widget _field(TextEditingController c, String l,
      {int lines = 1, TextInputType? kb}) =>
      TextFormField(
        controller: c,
        keyboardType: kb,
        maxLines: lines,
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

  Widget _dateField() => GestureDetector(
    onTap: () async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate:
        _birthDate ?? now.subtract(const Duration(days: 7000)),
        firstDate: DateTime(1900),
        lastDate: now,
      );
      if (picked != null) setState(() => _birthDate = picked);
    },
    child: InputDecorator(
      decoration: const InputDecoration(labelText: 'Tanggal Lahir'),
      child: Text(
        _birthDate == null
            ? 'Pilih tanggal'
            : DateFormat('d MMMM y', 'id').format(_birthDate!),
      ),
    ),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'fullName'     : _fullNameC.text.trim(),
      'gender'       : _gender.value,
      'birthDate'    : _birthDate,
      'birthPlace'   : _birthPlaceC.text.trim(),
      'address'      : _addressC.text.trim(),
      'companionName': _companionC.text.trim(),
    });

    if (mounted) Navigator.pop(context);
  }
}
